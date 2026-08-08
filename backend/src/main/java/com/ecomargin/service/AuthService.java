package com.ecomargin.service;

import com.ecomargin.controller.AuthRequest;
import com.ecomargin.controller.AuthResponse;
import com.ecomargin.model.User;
import com.ecomargin.repository.UserRepository;
import com.ecomargin.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.AuthenticationException;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final JwtUtil jwtUtil;
    private final AuthenticationManager authenticationManager;

    public AuthResponse authenticate(AuthRequest request) {
        log.info("[AUTH] Login request received");

        if (request == null || request.getEmail() == null || request.getEmail().isBlank() ||
            request.getPassword() == null || request.getPassword().isBlank()) {
            log.warn("[AUTH] Rejected login attempt with empty credentials");
            throw new IllegalArgumentException("Email and password are required.");
        }

        final String email = request.getEmail().trim().toLowerCase();

        log.info("[AUTH] User lookup started");
        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            email,
                            request.getPassword()
                    )
            );
        } catch (AuthenticationException e) {
            log.warn("[AUTH] Authentication failed for email: {} - Reason: {}", email, e.getMessage());
            throw new BadCredentialsException("Invalid email or password");
        }

        log.info("[AUTH] User found");
        log.info("[AUTH] Authentication successful");

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> {
                    log.warn("[AUTH] User lookup failed after successful authentication for email: {}", email);
                    return new BadCredentialsException("Invalid email or password");
                });

        String jwtToken = jwtUtil.generateToken(user);
        log.info("[AUTH] JWT generation successful");

        return AuthResponse.builder()
                .accessToken(jwtToken)
                .refreshToken("dummy-refresh-token")
                .build();
    }
}

