-- 航班打卡初始 schema (MariaDB)

CREATE TABLE users (
    id            BIGINT       NOT NULL AUTO_INCREMENT,
    account       VARCHAR(20)  NOT NULL,
    nickname      VARCHAR(50)  NOT NULL,
    avatar        VARCHAR(50)  NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_users_account (account)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE records (
    id         BIGINT    NOT NULL AUTO_INCREMENT,
    user_id    BIGINT    NOT NULL,
    `time`     TIMESTAMP NOT NULL,
    note       TEXT      NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_records_user_time (user_id, `time`),
    CONSTRAINT fk_records_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE settings (
    user_id           BIGINT       NOT NULL,
    precision_setting VARCHAR(20)  NOT NULL DEFAULT 'second',
    effect            VARCHAR(20)  NOT NULL DEFAULT 'plane',
    theme             VARCHAR(20)  NOT NULL DEFAULT 'dark',
    effect_emoji      VARCHAR(20)  NOT NULL DEFAULT '✈️',
    quotes            TEXT         NULL,
    PRIMARY KEY (user_id),
    CONSTRAINT fk_settings_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
