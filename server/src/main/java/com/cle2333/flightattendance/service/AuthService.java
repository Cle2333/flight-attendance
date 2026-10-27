package com.cle2333.flightattendance.service;

import com.cle2333.flightattendance.config.AppProperties;
import com.cle2333.flightattendance.dto.AuthData;
import com.cle2333.flightattendance.entity.Settings;
import com.cle2333.flightattendance.entity.User;
import com.cle2333.flightattendance.exception.ApiException;
import com.cle2333.flightattendance.repository.SettingsRepository;
import com.cle2333.flightattendance.repository.UserRepository;
import com.cle2333.flightattendance.security.JwtTokenProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    private static final Logger log = LoggerFactory.getLogger(AuthService.class);

    private final UserRepository users;
    private final SettingsRepository settings;
    private final PasswordEncoder encoder;
    private final JwtTokenProvider jwt;
    private final RefreshTokenService refreshTokens;
    private final AppProperties props;

    public AuthService(UserRepository users,
                       SettingsRepository settings,
                       PasswordEncoder encoder,
                       JwtTokenProvider jwt,
                       RefreshTokenService refreshTokens,
                       AppProperties props) {
        this.users = users;
        this.settings = settings;
        this.encoder = encoder;
        this.jwt = jwt;
        this.refreshTokens = refreshTokens;
        this.props = props;
    }

    @Transactional
    public AuthData register(String account, String password, String nickname) {
        if (users.existsByAccount(account)) {
            log.info("注册失败：账号已存在 account={}", account);
            throw new ApiException("账号已存在", HttpStatus.BAD_REQUEST);
        }
        String nick = (nickname == null || nickname.isBlank()) ? account : nickname;
        String hash = encoder.encode(password);
        String role = resolveRoleFor(account);
        User saved = users.save(new User(account, nick, null, hash, role));
        settings.save(new Settings(saved.getId()));

        log.info("注册成功 userId={} account={} role={}", saved.getId(), account, role);
        return buildAuthData(saved);
    }

    @Transactional(readOnly = true)
    public AuthData login(String account, String password) {
        User u = users.findByAccount(account)
                .orElseThrow(() -> {
                    log.info("登录失败：账号不存在 account={}", account);
                    return new ApiException("账号或密码错误", HttpStatus.UNAUTHORIZED);
                });
        if (!encoder.matches(password, u.getPasswordHash())) {
            log.info("登录失败：密码错误 account={}", account);
            throw new ApiException("账号或密码错误", HttpStatus.UNAUTHORIZED);
        }
        log.info("登录成功 userId={} account={} role={}", u.getId(), account, u.getRole());
        return buildAuthData(u);
    }

    /** 用 refresh token 换新的 access + refresh（轮换） */
    @Transactional
    public AuthData refresh(String oldRefreshToken) {
        var rotated = refreshTokens.rotate(oldRefreshToken);
        User u = users.findById(rotated.entity().getUserId())
                .orElseThrow(() -> new ApiException("用户不存在", HttpStatus.UNAUTHORIZED));
        log.info("token 刷新 userId={}", u.getId());
        return buildAuthData(u, rotated.rawToken());
    }

    /** 登出：撤销指定 refresh token */
    @Transactional
    public void logout(String refreshToken) {
        refreshTokens.revoke(refreshToken);
        log.info("登出 refreshToken.revoked={}", refreshToken != null);
    }

    private AuthData buildAuthData(User u) {
        return buildAuthData(u, null);
    }

    private AuthData buildAuthData(User u, String existingRefreshToken) {
        String access = jwt.generateAccessToken(u.getId(), u.getAccount(), u.getRole());
        String refresh = existingRefreshToken != null
                ? existingRefreshToken
                : refreshTokens.issue(u.getId()).rawToken();
        return new AuthData(
                u.getId(),
                u.getAccount(),
                u.getNickname(),
                u.getRole(),
                access,
                refresh,
                jwt.getAccessExpirationSeconds(),
                jwt.getRefreshExpirationSeconds()
        );
    }

    /** 注册时决定 role：账号匹配 app.admin.bootstrap-account → ADMIN，否则 USER */
    private String resolveRoleFor(String account) {
        String adminAcc = props.getAdmin().getBootstrapAccount();
        if (adminAcc != null && !adminAcc.isBlank() && adminAcc.equals(account)) {
            log.warn("🔑 引导 admin 账号注册 account={}", account);
            return User.ROLE_ADMIN;
        }
        return User.ROLE_USER;
    }
}
