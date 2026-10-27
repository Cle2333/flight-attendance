package com.cle2333.flightattendance.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.List;

/**
 * 把 application-config.yml 里的 app.* 全部绑到这里。
 * 改值请改 yml 或环境变量，不要改这里。
 */
@ConfigurationProperties(prefix = "app")
public class AppProperties {

    private final Jwt jwt = new Jwt();
    private final Cors cors = new Cors();
    private final Admin admin = new Admin();

    public Jwt getJwt() { return jwt; }
    public Cors getCors() { return cors; }
    public Admin getAdmin() { return admin; }

    public static class Jwt {
        /** 启动时强校验：不能用 dev 默认值，长度必须 ≥ 32。 */
        private String secret;
        /** 短期 access token 有效期（分钟） */
        private long accessExpirationMinutes = 15;
        /** 长期 refresh token 有效期（天） */
        private long refreshExpirationDays = 7;

        public String getSecret() { return secret; }
        public void setSecret(String secret) { this.secret = secret; }
        public long getAccessExpirationMinutes() { return accessExpirationMinutes; }
        public void setAccessExpirationMinutes(long v) { this.accessExpirationMinutes = v; }
        public long getRefreshExpirationDays() { return refreshExpirationDays; }
        public void setRefreshExpirationDays(long v) { this.refreshExpirationDays = v; }
    }

    public static class Cors {
        /** 允许的 Origin 白名单。生产必改；多值用 yml 列表。环境变量 APP_CORS_ALLOWEDORIGINS=*** */
        private List<String> allowedOrigins = List.of(
                "http://localhost:3000",
                "http://localhost:8080"
        );

        public List<String> getAllowedOrigins() { return allowedOrigins; }
        public void setAllowedOrigins(List<String> v) { this.allowedOrigins = v; }
    }

    public static class Admin {
        /**
         * 启动时如果配置了此 account，则在注册/登录流程中自动提升为 ADMIN 角色。
         * 留空 = 没有任何自动 admin，全靠 SQL: UPDATE users SET role='ADMIN' WHERE account='xxx';
         */
        private String bootstrapAccount = "";

        public String getBootstrapAccount() { return bootstrapAccount; }
        public void setBootstrapAccount(String v) { this.bootstrapAccount = v; }
    }
}
