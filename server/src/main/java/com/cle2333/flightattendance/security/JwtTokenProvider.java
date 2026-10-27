package com.cle2333.flightattendance.security;

import com.cle2333.flightattendance.config.AppProperties;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;

@Component
public class JwtTokenProvider {

    private static final Logger log = LoggerFactory.getLogger(JwtTokenProvider.class);

    private final SecretKey key;
    private final long accessExpirationMinutes;
    private final long refreshExpirationDays;

    public JwtTokenProvider(AppProperties props) {
        String secret = props.getJwt().getSecret();
        // 🔴 启动检查：默认值直接拒启动
        if (secret == null || secret.isBlank()) {
            throw new IllegalStateException(
                "❌ app.jwt.secret 未配置。请设置环境变量 JWT_SECRET=<openssl rand -hex 32>");
        }
        if (secret.contains("dev-secret") || secret.contains("please-change")) {
            throw new IllegalStateException(
                "❌ app.jwt.secret 仍是 application-config.yml 里的默认值。" +
                "生产环境必须设置 JWT_SECRET 环境变量（≥ 32 字节随机）。");
        }
        byte[] bytes = secret.getBytes(StandardCharsets.UTF_8);
        if (bytes.length < 32) {
            throw new IllegalStateException(
                "❌ app.jwt.secret 长度不足 32 字节（HS256 最低要求），实际: " + bytes.length);
        }
        this.key = Keys.hmacShaKeyFor(bytes);
        this.accessExpirationMinutes = props.getJwt().getAccessExpirationMinutes();
        this.refreshExpirationDays = props.getJwt().getRefreshExpirationDays();
        log.info("JwtTokenProvider 初始化完成: access TTL {} 分钟, refresh TTL {} 天",
                 accessExpirationMinutes, refreshExpirationDays);
    }

    /** 生成短期 access token（含 role claim） */
    public String generateAccessToken(Long userId, String account, String role) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(String.valueOf(userId))
                .claim("account", account)
                .claim("role", role)
                .claim("typ", "access")
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusSeconds(accessExpirationMinutes * 60)))
                .signWith(key)
                .compact();
    }

    /** 生成长期 refresh token（subject=tokenId，方便 DB 关联） */
    public String generateRefreshToken(Long userId, Long tokenId) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(String.valueOf(tokenId))
                .claim("uid", userId)
                .claim("typ", "refresh")
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusSeconds(refreshExpirationDays * 86400)))
                .signWith(key)
                .compact();
    }

    public Claims parse(String token) {
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public long getAccessExpirationSeconds() {
        return accessExpirationMinutes * 60;
    }

    public long getRefreshExpirationSeconds() {
        return refreshExpirationDays * 86400;
    }
}
