package com.cle2333.flightattendance.service;

import com.cle2333.flightattendance.entity.RefreshToken;
import com.cle2333.flightattendance.exception.ApiException;
import com.cle2333.flightattendance.repository.RefreshTokenRepository;
import com.cle2333.flightattendance.security.JwtTokenProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.HexFormat;
import java.util.UUID;

@Service
public class RefreshTokenService {

    private static final Logger log = LoggerFactory.getLogger(RefreshTokenService.class);

    private final RefreshTokenRepository repo;
    private final JwtTokenProvider jwt;

    public RefreshTokenService(RefreshTokenRepository repo, JwtTokenProvider jwt) {
        this.repo = repo;
        this.jwt = jwt;
    }

    public record Issued(String rawToken, RefreshToken entity) {}

    /**
     * 签发新 refresh token。
     * 流程：先写 DB 占位拿到 tokenId，再用 JwtTokenProvider 签 JWT，
     *       JWT = rawToken，DB 存 hash(rawToken)。这样 rotation 撤销旧 token 时
     *       仍能直接用 hash 比对。
     */
    @Transactional
    public Issued issue(Long userId) {
        // 1. 先占位一行拿 id —— 用 UUID 避免并发场景下 unique 冲突
        Instant placeholderExpires = Instant.now().plusSeconds(60);
        RefreshToken placeholder = repo.save(
                new RefreshToken(userId, "pending-" + UUID.randomUUID(), placeholderExpires));

        // 2. 用 tokenId 签 JWT
        String signed = jwt.generateRefreshToken(userId, placeholder.getId());

        // 3. 把 hash(signed) 写回去，覆盖占位
        placeholder.setTokenHash(sha256Hex(signed));
        placeholder.setExpiresAt(Instant.now().plusSeconds(jwt.getRefreshExpirationSeconds()));
        RefreshToken saved = repo.save(placeholder);

        return new Issued(signed, saved);
    }

    /** 验证并返回 refresh token 实体 */
    @Transactional(readOnly = true)
    public RefreshToken verify(String rawToken) {
        if (rawToken == null || rawToken.isBlank()) {
            throw new ApiException("refresh token 缺失", HttpStatus.UNAUTHORIZED);
        }
        String hash = sha256Hex(rawToken);
        RefreshToken rt = repo.findByTokenHash(hash)
                .orElseThrow(() -> new ApiException("refresh token 无效", HttpStatus.UNAUTHORIZED));
        if (!rt.isUsable()) {
            throw new ApiException("refresh token 已过期或已撤销", HttpStatus.UNAUTHORIZED);
        }
        return rt;
    }

    /** 轮换：撤销旧 token，签发新 token */
    @Transactional
    public Issued rotate(String oldRawToken) {
        RefreshToken old = verify(oldRawToken);
        old.setRevokedAt(Instant.now());
        repo.save(old);
        log.info("refresh token 轮换 userId={} tokenId={}", old.getUserId(), old.getId());
        return issue(old.getUserId());
    }

    /** 登出：撤销指定 refresh token */
    @Transactional
    public void revoke(String rawToken) {
        if (rawToken == null || rawToken.isBlank()) return;
        String hash = sha256Hex(rawToken);
        repo.findByTokenHash(hash).ifPresent(rt -> {
            if (rt.getRevokedAt() == null) {
                rt.setRevokedAt(Instant.now());
                repo.save(rt);
                log.info("refresh token 撤销 userId={} tokenId={}", rt.getUserId(), rt.getId());
            }
        });
    }

    /** 强制下线：撤销用户所有 refresh token（改密码后用） */
    @Transactional
    public int revokeAll(Long userId) {
        return repo.revokeAllByUserId(userId, Instant.now());
    }

    private static String sha256Hex(String s) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] digest = md.digest(s.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }
}
