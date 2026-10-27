package com.cle2333.flightattendance.security;

import com.cle2333.flightattendance.dto.ApiResponse;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(JwtAuthenticationFilter.class);

    private final JwtTokenProvider jwt;
    private final ObjectMapper mapper = new ObjectMapper();

    public JwtAuthenticationFilter(JwtTokenProvider jwt) {
        this.jwt = jwt;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest req,
                                    HttpServletResponse res,
                                    FilterChain chain) throws ServletException, IOException {
        String header = req.getHeader("Authorization");
        if (header == null || !header.startsWith("Bearer ")) {
            chain.doFilter(req, res);
            return;
        }
        String token = header.substring(7).trim();
        try {
            Claims claims = jwt.parse(token);

            // 拒绝 refresh token 走这个过滤器（refresh 走 /api/auth/refresh）
            // 兼容老 token：typ 缺失 = 当作 access（老 JwtTokenProvider 没这字段）
            String typ = claims.get("typ", String.class);
            if ("refresh".equals(typ)) {
                sendUnauthorized(res, "Token 类型错误");
                return;
            }

            Long userId = Long.parseLong(claims.getSubject());
            String account = claims.get("account", String.class);
            String role = claims.get("role", String.class);
            if (role == null || role.isBlank()) {
                role = "USER";
            }

            UserPrincipal principal = new UserPrincipal(userId, account, role);
            var auth = new UsernamePasswordAuthenticationToken(
                    principal, null,
                    List.of(new SimpleGrantedAuthority("ROLE_" + role)));
            auth.setDetails(new WebAuthenticationDetailsSource().buildDetails(req));
            SecurityContextHolder.getContext().setAuthentication(auth);
            chain.doFilter(req, res);
        } catch (JwtException | IllegalArgumentException e) {
            // 审计：记下失败请求（IP + UA + 原因），便于事后排查攻击
            log.warn("JWT 解析失败 ip={} ua=\"{}\" cause={}",
                     req.getRemoteAddr(), req.getHeader("User-Agent"), e.getMessage());
            sendUnauthorized(res, "Token 无效或已过期");
        }
    }

    private void sendUnauthorized(HttpServletResponse res, String msg) throws IOException {
        res.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        res.setContentType("application/json;charset=UTF-8");
        mapper.writeValue(res.getWriter(), ApiResponse.error(msg));
    }
}
