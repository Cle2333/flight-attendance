package com.cle2333.flightattendance.security;

import com.cle2333.flightattendance.dto.ApiResponse;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 简单的进程内滑动窗口限流。
 * 只对 /api/auth/login 和 /api/auth/register 生效。
 * 够用、零依赖，分布式部署时换 Bucket4j + Redis 即可。
 */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 10)
public class RateLimitFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(RateLimitFilter.class);

    // 规则：路径 → (窗口秒数, 窗口内最大请求数)
    private record Rule(int windowSeconds, int maxRequests) {}

    private static final Map<String, Rule> RULES = Map.of(
        "/api/auth/login",    new Rule(60, 10),    // 10 次/分钟/IP
        "/api/auth/register", new Rule(3600, 5)    // 5 次/小时/IP
    );

    private final Map<String, Deque<Long>> hits = new ConcurrentHashMap<>();
    private final ObjectMapper mapper = new ObjectMapper();

    @Override
    protected void doFilterInternal(HttpServletRequest req,
                                    HttpServletResponse res,
                                    FilterChain chain) throws ServletException, IOException {
        Rule rule = RULES.get(req.getRequestURI());
        if (rule == null) {
            chain.doFilter(req, res);
            return;
        }

        String ip = req.getRemoteAddr();
        long now = System.currentTimeMillis();
        long cutoff = now - rule.windowSeconds() * 1000L;

        Deque<Long> window = hits.computeIfAbsent(ip, k -> new ArrayDeque<>());
        synchronized (window) {
            // 弹出窗口外的
            while (!window.isEmpty() && window.peekFirst() < cutoff) {
                window.pollFirst();
            }
            if (window.size() >= rule.maxRequests()) {
                log.warn("限流触发 ip={} path={} hits={}/{}s",
                         ip, req.getRequestURI(), window.size(), rule.windowSeconds());
                res.setStatus(429);
                res.setContentType(MediaType.APPLICATION_JSON_VALUE);
                res.setHeader("Retry-After", String.valueOf(rule.windowSeconds()));
                mapper.writeValue(res.getWriter(),
                        ApiResponse.error("请求过于频繁，请稍后再试"));
                return;
            }
            window.offerLast(now);
        }

        chain.doFilter(req, res);
    }

    /** 测试用：清理计数。生产可加 @Scheduled 每小时清空过期的 ip。 */
    public void reset() {
        hits.clear();
    }
}
