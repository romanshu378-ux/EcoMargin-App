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

import java.io.IOException;
import java.time.Duration;

@Component
@ConditionalOnProperty(name = "spring.redis.enabled", havingValue = "true", matchIfMissing = false)
public class RateLimitFilter extends OncePerRequestFilter {

    @Autowired(required = false)
    private StringRedisTemplate redisTemplate;

    private static final int MAX_REQUESTS_PER_MINUTE = 60; // configurable

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        if (redisTemplate == null) {
            filterChain.doFilter(request, response);
            return;
        }

        String clientIp = request.getRemoteAddr();
        String redisKey = "rate_limit:" + clientIp;

        try {
            Long requests = redisTemplate.opsForValue().increment(redisKey);
            
            if (requests != null && requests == 1) {
                redisTemplate.expire(redisKey, Duration.ofMinutes(1));
            }

            if (requests != null && requests > MAX_REQUESTS_PER_MINUTE) {
                response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
                response.getWriter().write("Too many requests. Please try again later.");
                return;
            }
        } catch (Exception e) {
            // If Redis is down, bypass rate limiting to avoid blocking traffic
        }

        filterChain.doFilter(request, response);
    }
}
