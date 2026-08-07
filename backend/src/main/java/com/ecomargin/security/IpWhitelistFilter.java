package com.ecomargin.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Arrays;
import java.util.List;

@Slf4j
@Component
public class IpWhitelistFilter extends OncePerRequestFilter {

    @Value("${security.ip.whitelist:127.0.0.1,0:0:0:0:0:0:0:1}") // Configurable allowed IPs
    private String whitelistedIpsString;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        // Restrict OCPP endpoint access or system configurations to specific IP whitelist blocks
        if (request.getRequestURI().startsWith("/api/v1/admin/secure")) {
            String clientIp = request.getRemoteAddr();
            List<String> allowedIps = Arrays.asList(whitelistedIpsString.split(","));

            if (!allowedIps.contains(clientIp)) {
                log.warn("Unauthorized administration access attempt rejected from IP: {}", clientIp);
                response.setStatus(HttpStatus.FORBIDDEN.value());
                response.getWriter().write("Forbidden: Client IP not whitelisted");
                return;
            }
        }

        filterChain.doFilter(request, response);
    }
}
