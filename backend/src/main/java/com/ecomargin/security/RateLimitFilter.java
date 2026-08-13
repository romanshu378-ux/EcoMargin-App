package com.ecomargin.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class RateLimitFilter extends OncePerRequestFilter {

    @Autowired(required = false)
    private StringRedisTemplate redisTemplate;

    private static final int DEFAULT_LIMIT = 120; 
    private static final int SENSITIVE_AUTH_LIMIT = 30;
    private static final int SENSITIVE_ACTION_LIMIT = 30;
    
    // Fallback in-memory store
    private final ConcurrentHashMap<String, RequestCounter> inMemoryCache = new ConcurrentHashMap<>();
    private final ObjectMapper objectMapper = new ObjectMapper();

    private static class RequestCounter {
        long count;
        long expiryTime;

        RequestCounter(long count, long expiryTime) {
            this.count = count;
            this.expiryTime = expiryTime;
        }
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        String clientIp = request.getHeader("X-Forwarded-For");
        if (clientIp != null && !clientIp.isBlank()) {
            clientIp = clientIp.split(",")[0].trim();
        } else {
            clientIp = request.getHeader("CF-Connecting-IP");
            if (clientIp == null || clientIp.isBlank()) {
                clientIp = request.getRemoteAddr();
            }
        }
        String path = request.getRequestURI();
        String method = request.getMethod();
        
        int maxRequests = DEFAULT_LIMIT;
        
        if ("POST".equalsIgnoreCase(method)) {
            if (path.endsWith("/auth/login") || path.endsWith("/auth/register") || path.endsWith("/auth/refresh")
                || path.contains("/auth/forgot-password") || path.contains("/auth/verify-otp")) {
                maxRequests = SENSITIVE_AUTH_LIMIT;
            } else if (path.endsWith("/wallet/topup") || path.endsWith("/charging/start") || path.contains("/charging-sessions/start")
                || path.endsWith("/charging/stop") || path.contains("/charging-sessions/stop") 
                || path.endsWith("/rfid/link") || path.endsWith("/rfid/block")) {
                maxRequests = SENSITIVE_ACTION_LIMIT;
            }
        }

        String redisKey = "rate_limit:" + clientIp + ":" + path;

        boolean isLimited = false;

        if (redisTemplate != null) {
            try {
                Long requests = redisTemplate.opsForValue().increment(redisKey);
                if (requests != null && requests == 1) {
                    redisTemplate.expire(redisKey, Duration.ofMinutes(1));
                }
                if (requests != null && requests > maxRequests) {
                    isLimited = true;
                }
            } catch (Exception e) {
                // Redis down, fallback to memory
                isLimited = isRateLimitedInMemory(redisKey, maxRequests);
            }
        } else {
            isLimited = isRateLimitedInMemory(redisKey, maxRequests);
        }

        if (isLimited) {
            response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
            response.setContentType("application/json");
            
            Map<String, Object> body = new HashMap<>();
            body.put("success", false);
            body.put("code", "RATE_LIMIT_EXCEEDED");
            body.put("message", "Too many requests. Please try again later.");
            body.put("timestamp", LocalDateTime.now().toString());
            
            String requestId = (String) request.getAttribute("requestId");
            if (requestId == null) {
                requestId = response.getHeader("X-Request-ID");
            }
            body.put("requestId", requestId);
            
            response.getWriter().write(objectMapper.writeValueAsString(body));
            return;
        }

        filterChain.doFilter(request, response);
    }
    
    private boolean isRateLimitedInMemory(String key, int maxLimit) {
        long now = System.currentTimeMillis();
        RequestCounter counter = inMemoryCache.compute(key, (k, v) -> {
            if (v == null || now > v.expiryTime) {
                return new RequestCounter(1, now + 60000); // 1 min window
            } else {
                v.count++;
                return v;
            }
        });
        return counter.count > maxLimit;
    }
}
