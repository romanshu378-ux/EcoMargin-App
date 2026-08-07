package com.ecomargin.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class ApiKeyAuthenticationFilter extends OncePerRequestFilter {

    @Value("${api.key.header:X-API-KEY}")
    private String apiKeyHeader;

    @Value("${api.key.value:ecomargin-secret-api-key-value}")
    private String apiKeyValue;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        // Apply API Key security only to specific integration endpoints
        if (request.getRequestURI().startsWith("/api/v1/integration")) {
            String requestApiKey = request.getHeader(apiKeyHeader);

            if (requestApiKey == null || !requestApiKey.equals(apiKeyValue)) {
                response.setStatus(HttpStatus.UNAUTHORIZED.value());
                response.getWriter().write("Unauthorized: Invalid API Key");
                return;
            }
        }

        filterChain.doFilter(request, response);
    }
}
