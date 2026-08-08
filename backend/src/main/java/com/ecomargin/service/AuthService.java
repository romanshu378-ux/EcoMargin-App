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
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final JwtUtil jwtUtil;
    private final AuthenticationManager authenticationManager;
    private final PasswordEncoder passwordEncoder;

    public AuthResponse authenticate(AuthRequest request) {
        if (request == null || request.getEmail() == null || request.getEmail().isBlank() ||
            request.getPassword() == null || request.getPassword().isBlank()) {
            log.warn("[AUTH] Rejected login attempt with empty credentials");
            throw new IllegalArgumentException("Email and password are required.");
        }

        final String rawEmail = request.getEmail();
        final String email = rawEmail.trim().toLowerCase();

        log.info("[AUTH] Login email received");

        Optional<User> userOpt = userRepository.findByEmailIgnoreCase(email);
        boolean userFound = userOpt.isPresent();
        log.info("[AUTH] User found: {}", userFound);

        if (!userFound) {
            log.warn("[AUTH] Password authentication failed");
            throw new BadCredentialsException("Invalid email or password");
        }

        User user = userOpt.get();

        // Safe auto-migration for legacy plain-text password records
        if (user.getPassword() != null &&
            !user.getPassword().startsWith("$2a$") &&
            !user.getPassword().startsWith("$2b$") &&
            !user.getPassword().startsWith("$2y$")) {
            if (request.getPassword().equals(user.getPassword())) {
                log.info("[AUTH] Migrating legacy plain-text password to BCrypt hash");
                user.setPassword(passwordEncoder.encode(request.getPassword()));
                userRepository.save(user);
            }
        }

        log.info("[AUTH] Password authentication started");
        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            email,
                            request.getPassword()
                    )
            );
            log.info("[AUTH] Password authentication successful");
        } catch (AuthenticationException e) {
            log.warn("[AUTH] Password authentication failed");
            throw new BadCredentialsException("Invalid email or password");
        }

        String jwtToken = jwtUtil.generateToken(user);
        log.info("[AUTH] JWT generation successful");

        return AuthResponse.builder()
                .accessToken(jwtToken)
                .refreshToken("dummy-refresh-token")
                .build();
    }
}


