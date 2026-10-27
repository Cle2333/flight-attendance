-- V3: refresh token 表 —— 长期 refresh + 短期 access 的双 token 方案
CREATE TABLE refresh_tokens (
    id         BIGINT     NOT NULL AUTO_INCREMENT,
    user_id    BIGINT     NOT NULL,
    token_hash CHAR(64)   NOT NULL,            -- SHA-256 hex of the opaque refresh token
    expires_at TIMESTAMP  NOT NULL,
    created_at TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP  NULL,                 -- 非 NULL = 已撤销（登出 / 轮换）
    PRIMARY KEY (id),
    UNIQUE KEY uk_refresh_token_hash (token_hash),
    KEY idx_refresh_user (user_id),
    CONSTRAINT fk_refresh_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
