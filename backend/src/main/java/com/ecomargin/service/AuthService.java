package com.ecomargin.service;

import com.ecomargin.controller.AuthRequest;
import com.ecomargin.controller.AuthResponse;
import com.ecomargin.controller.RegisterRequest;
import com.ecomargin.controller.RegisterResponse;
import com.ecomargin.exception.UserAlreadyExistsException;
import com.ecomargin.model.RefreshToken;
import com.ecomargin.model.Role;
import com.ecomargin.model.User;
import com.ecomargin.model.Wallet;
import com.ecomargin.model.enums.RoleType;
import com.ecomargin.repository.RefreshTokenRepository;
import com.ecomargin.repository.RoleRepository;
import com.ecomargin.repository.UserRepository;
import com.ecomargin.repository.WalletRepository;
import com.ecomargin.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.HashSet;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final WalletRepository walletRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final JwtUtil jwtUtil;
    private final AuthenticationManager authenticationManager;
    private final PasswordEncoder passwordEncoder;

    public RegisterResponse register(RegisterRequest request) {
        log.info("[AUTH] Registration request received");

        if (request == null || request.getEmail() == null || request.getEmail().isBlank() ||
            request.getPassword() == null || request.getPassword().isBlank()) {
            throw new IllegalArgumentException("Email and password are required.");
        }

        if (request.getPassword().length() < 8) {
            throw new IllegalArgumentException("Password must be at least 8 characters.");
        }

        final String cleanEmail = request.getEmail().trim().toLowerCase();

        if (userRepository.findByEmailIgnoreCase(cleanEmail).isPresent()) {
            log.warn("[AUTH] Registration rejected - email already exists: {}", cleanEmail);
            throw new UserAlreadyExistsException("Email is already registered.");
        }

        String rawName = request.getName() != null && !request.getName().isBlank()
                ? request.getName()
                : request.getFullName();

        String firstName = request.getFirstName();
        String lastName = request.getLastName();
        if ((firstName == null || firstName.isBlank()) && rawName != null && !rawName.isBlank()) {
            String[] parts = rawName.trim().split("\\s+", 2);
            firstName = parts[0];
            lastName = parts.length > 1 ? parts[1] : "";
        }

        String rawPhone = request.getPhoneNumber() != null && !request.getPhoneNumber().isBlank()
                ? request.getPhoneNumber()
                : request.getPhone();

        Set<Role> roles = new HashSet<>();
        Role customerRole = roleRepository.findByName(RoleType.ROLE_CUSTOMER)
                .orElseGet(() -> {
                    log.info("[AUTH] ROLE_CUSTOMER missing in DB; creating role on the fly");
                    return roleRepository.save(Role.builder().name(RoleType.ROLE_CUSTOMER).build());
                });
        roles.add(customerRole);

        String phoneVal = (rawPhone != null && !rawPhone.isBlank()) ? rawPhone.trim() : null;

        User user = User.builder()
                .email(cleanEmail)
                .password(passwordEncoder.encode(request.getPassword()))
                .firstName(firstName != null && !firstName.isBlank() ? firstName : "Customer")
                .lastName(lastName != null ? lastName : "")
                .phoneNumber(phoneVal)
                .isVerified(true)
                .isAccountNonLocked(true)
                .roles(roles)
                .jwtVersion(0)
                .build();

        User savedUser = userRepository.save(user);

        try {
            Wallet wallet = Wallet.builder()
                    .user(savedUser)
                    .balance(new BigDecimal("100.00"))
                    .currency("INR")
                    .build();
            walletRepository.save(wallet);
        } catch (Exception e) {
            log.warn("[AUTH] Initial wallet creation deferred or skipped: {}", e.getMessage());
        }

        log.info("[AUTH] User registration successful for email: {}", cleanEmail);

        return RegisterResponse.builder()
                .message("Account created successfully. Please login.")
                .email(cleanEmail)
                .build();
    }

    public AuthResponse authenticate(AuthRequest request) {
        if (request == null || request.getEmail() == null || request.getEmail().isBlank() ||
            request.getPassword() == null || request.getPassword().isBlank()) {
            log.warn("[AUTH] Rejected login attempt with empty credentials");
            throw new IllegalArgumentException("Email and password are required.");
        }

        final String email = request.getEmail().trim().toLowerCase();

        Optional<User> userOpt = userRepository.findByEmailIgnoreCase(email);
        if (userOpt.isEmpty()) {
            log.warn("[AUTH] Password authentication failed");
            throw new BadCredentialsException("Invalid email or password");
        }

        User user = userOpt.get();

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

        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(email, request.getPassword())
            );
        } catch (AuthenticationException e) {
            log.warn("[AUTH] Password authentication failed");
            throw new BadCredentialsException("Invalid email or password");
        }

        String jwtToken = jwtUtil.generateToken(user);
        RefreshToken refreshToken = createRefreshToken(user);

        return AuthResponse.builder()
                .accessToken(jwtToken)
                .refreshToken(refreshToken.getToken())
                .build();
    }

    public AuthResponse refreshToken(String requestRefreshToken) {
        return refreshTokenRepository.findByToken(requestRefreshToken)
                .map(token -> {
                    User user = token.getUser();
                    
                    if (token.isRevoked() || token.isUsed()) {
                        log.warn("[AUTH-CRITICAL] Token reuse detected! Revoking all sessions for user_id={}", user.getId());
                        revokeAllUserTokens(user);
                        throw new BadCredentialsException("Token compromised. Please login again.");
                    }
                    
                    if (token.getExpiryDate().compareTo(Instant.now()) < 0) {
                        token.setRevoked(true);
                        refreshTokenRepository.save(token);
                        throw new BadCredentialsException("Refresh token was expired. Please make a new signin request");
                    }
                    
                    // Rotate the token
                    token.setUsed(true);
                    refreshTokenRepository.save(token);
                    
                    String jwtToken = jwtUtil.generateToken(user);
                    RefreshToken newRefreshToken = createRefreshToken(user);
                    
                    return AuthResponse.builder()
                            .accessToken(jwtToken)
                            .refreshToken(newRefreshToken.getToken())
                            .build();
                })
                .orElseThrow(() -> new BadCredentialsException("Refresh token is not in database!"));
    }

    public void logout(String requestRefreshToken) {
        if (requestRefreshToken != null && !requestRefreshToken.isBlank()) {
            refreshTokenRepository.findByToken(requestRefreshToken).ifPresent(token -> {
                token.setRevoked(true);
                refreshTokenRepository.save(token);
                log.info("[AUTH] User logged out and token revoked.");
            });
        }
    }
    
    private void revokeAllUserTokens(User user) {
        refreshTokenRepository.findByUser(user).forEach(t -> {
            t.setRevoked(true);
            refreshTokenRepository.save(t);
        });
    }

    private RefreshToken createRefreshToken(User user) {
        RefreshToken refreshToken = RefreshToken.builder()
                .user(user)
                .token(UUID.randomUUID().toString())
                .expiryDate(Instant.now().plus(7, ChronoUnit.DAYS))
                .revoked(false)
                .used(false)
                .build();
        return refreshTokenRepository.save(refreshToken);
    }
}
