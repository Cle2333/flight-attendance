-- V2: 加 role 列到 users 表，给 admin 鉴权用
ALTER TABLE users
    ADD COLUMN role VARCHAR(20) NOT NULL DEFAULT 'USER';

CREATE INDEX idx_users_role ON users (role);
