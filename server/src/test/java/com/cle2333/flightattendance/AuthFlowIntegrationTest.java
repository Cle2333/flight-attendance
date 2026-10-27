package com.cle2333.flightattendance;

import com.cle2333.flightattendance.dto.LoginRequest;
import com.cle2333.flightattendance.dto.LogoutRequest;
import com.cle2333.flightattendance.dto.RefreshRequest;
import com.cle2333.flightattendance.dto.RegisterRequest;
import com.cle2333.flightattendance.security.RateLimitFilter;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.RestTemplate;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class AuthFlowIntegrationTest {

    @LocalServerPort int port;
    @Autowired ObjectMapper json;
    @Autowired RateLimitFilter rateLimit;

    private final RestTemplate http = new RestTemplate();

    private String url(String path) { return "http://localhost:" + port + path; }

    @BeforeEach
    void resetRateLimit() {
        // 共享 Spring context 里 RateLimitFilter 是单例，每个测试前清零避免互相影响
        rateLimit.reset();
    }

    @Test
    void registerLoginRecordsFlow() throws Exception {
        // 1) register
        RegisterRequest reg = new RegisterRequest("alice", "secret123", "Alice");
        HttpHeaders h = new HttpHeaders();
        h.setContentType(MediaType.APPLICATION_JSON);
        ResponseEntity<String> regRes = http.postForEntity(
                url("/api/auth/register"),
                new HttpEntity<>(json.writeValueAsString(reg), h), String.class);
        assertEquals(200, regRes.getStatusCode().value());
        JsonNode regBody = json.readTree(regRes.getBody());
        assertTrue(regBody.get("success").asBoolean());
        String access = regBody.path("data").path("accessToken").asText();
        String refresh = regBody.path("data").path("refreshToken").asText();
        assertNotNull(access);
        assertNotNull(refresh);
        assertTrue(regBody.path("data").path("role").asText().equals("USER"));
        // 向后兼容：响应里也要有 "token" 字段（老客户端读这个）
        String legacyToken = regBody.path("data").path("token").asText();
        assertEquals(access, legacyToken);
        long userId = regBody.path("data").path("userId").asLong();

        // 2) login with same account
        LoginRequest login = new LoginRequest("alice", "secret123");
        ResponseEntity<String> loginRes = http.postForEntity(
                url("/api/auth/login"),
                new HttpEntity<>(json.writeValueAsString(login), h), String.class);
        assertEquals(200, loginRes.getStatusCode().value());
        assertTrue(json.readTree(loginRes.getBody()).get("success").asBoolean());

        // 3) GET /api/records (auth)
        HttpHeaders auth = new HttpHeaders();
        auth.setBearerAuth(access);
        ResponseEntity<String> listRes = http.exchange(
                url("/api/records"), HttpMethod.GET, new HttpEntity<>(auth), String.class);
        assertEquals(200, listRes.getStatusCode().value());
        assertTrue(json.readTree(listRes.getBody()).get("success").asBoolean());

        // 4) no token -> 401
        try {
            http.getForEntity(url("/api/records"), String.class);
            fail("expected 401");
        } catch (HttpStatusCodeException e) {
            assertEquals(401, e.getStatusCode().value());
        }

        // 5) /api/test works without auth
        ResponseEntity<String> ping = http.getForEntity(url("/api/test"), String.class);
        assertEquals(200, ping.getStatusCode().value());
        assertTrue(json.readTree(ping.getBody()).get("success").asBoolean());

        // 6) refresh 换新的 access + refresh
        ResponseEntity<String> refreshRes = http.postForEntity(
                url("/api/auth/refresh"),
                new HttpEntity<>(json.writeValueAsString(new RefreshRequest(refresh)), h), String.class);
        assertEquals(200, refreshRes.getStatusCode().value());
        JsonNode refreshBody = json.readTree(refreshRes.getBody()).path("data");
        String newAccess = refreshBody.path("accessToken").asText();
        String newRefresh = refreshBody.path("refreshToken").asText();
        assertNotNull(newAccess);
        assertNotNull(newRefresh);
        // rotation 后旧 refresh 应被撤销，再用它 refresh 应当失败
        try {
            http.postForEntity(
                    url("/api/auth/refresh"),
                    new HttpEntity<>(json.writeValueAsString(new RefreshRequest(refresh)), h), String.class);
            fail("old refresh should be revoked");
        } catch (HttpStatusCodeException e) {
            assertEquals(401, e.getStatusCode().value());
        }
    }

    @Test
    void adminRequiresAuth() {
        // 旧测试期望"无鉴权"，现在 /api/admin/** 强制要 ADMIN
        try {
            http.getForEntity(url("/api/admin/users"), String.class);
            fail("admin 应要求鉴权");
        } catch (HttpStatusCodeException e) {
            assertEquals(401, e.getStatusCode().value());
        }
    }

    @Test
    void leaderboardIsPublic() {
        // 排行榜是公开读（Flutter 排行榜页面依赖），即使没登录也能看
        ResponseEntity<String> res = http.getForEntity(url("/api/admin/leaderboard?type=all"), String.class);
        assertEquals(200, res.getStatusCode().value());
    }

    @Test
    void adminRequiresAdminRole() throws Exception {
        // 普通用户登录后访问 admin 应被 403
        RegisterRequest reg = new RegisterRequest("bob_" + System.currentTimeMillis(),
                                                   "secret123", "Bob");
        HttpHeaders h = new HttpHeaders();
        h.setContentType(MediaType.APPLICATION_JSON);
        ResponseEntity<String> regRes = http.postForEntity(
                url("/api/auth/register"),
                new HttpEntity<>(json.writeValueAsString(reg), h), String.class);
        assertEquals(200, regRes.getStatusCode().value());
        String access = json.readTree(regRes.getBody())
                             .path("data").path("accessToken").asText();
        HttpHeaders auth = new HttpHeaders();
        auth.setBearerAuth(access);
        try {
            http.exchange(url("/api/admin/users"), HttpMethod.GET,
                          new HttpEntity<>(auth), String.class);
            fail("非 admin 应被拒");
        } catch (HttpStatusCodeException e) {
            assertEquals(403, e.getStatusCode().value());
        }
    }

    @Test
    void accountPatternEnforced() throws Exception {
        // 含特殊字符的 account 应被拒
        RegisterRequest bad = new RegisterRequest("bad-name!", "secret123", "x");
        HttpHeaders h = new HttpHeaders();
        h.setContentType(MediaType.APPLICATION_JSON);
        try {
            http.postForEntity(url("/api/auth/register"),
                               new HttpEntity<>(json.writeValueAsString(bad), h), String.class);
            fail("特殊字符 account 应被拒");
        } catch (HttpStatusCodeException e) {
            assertEquals(400, e.getStatusCode().value());
        }
    }

    @Test
    void logoutRevokesRefreshToken() throws Exception {
        RegisterRequest reg = new RegisterRequest("carol_" + System.currentTimeMillis(),
                                                   "secret123", "Carol");
        HttpHeaders h = new HttpHeaders();
        h.setContentType(MediaType.APPLICATION_JSON);
        ResponseEntity<String> regRes = http.postForEntity(
                url("/api/auth/register"),
                new HttpEntity<>(json.writeValueAsString(reg), h), String.class);
        String refresh = json.readTree(regRes.getBody())
                             .path("data").path("refreshToken").asText();

        // logout
        ResponseEntity<String> logoutRes = http.postForEntity(
                url("/api/auth/logout"),
                new HttpEntity<>(json.writeValueAsString(new LogoutRequest(refresh)), h), String.class);
        assertEquals(200, logoutRes.getStatusCode().value());

        // 再用这个 refresh 应当失败
        try {
            http.postForEntity(url("/api/auth/refresh"),
                               new HttpEntity<>(json.writeValueAsString(new RefreshRequest(refresh)), h),
                               String.class);
            fail("登出后 refresh 应被拒");
        } catch (HttpStatusCodeException e) {
            assertEquals(401, e.getStatusCode().value());
        }
    }
}
