package com.ecomargin.service;

import com.ecomargin.controller.AuthRequest;
import com.ecomargin.controller.AuthResponse;
import com.ecomargin.controller.RegisterRequest;
import com.ecomargin.controller.RegisterResponse;
import com.ecomargin.exception.UserAlreadyExistsException;
import com.ecomargin.model.Role;
import com.ecomargin.model.User;
import com.ecomargin.model.Wallet;
import com.ecomargin.model.enums.RoleType;
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

import java.math.BigDecimal;
import java.util.HashSet;
import java.util.Optional;
import java.util.Set;

import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final WalletRepository walletRepository;
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
                .build();

        User savedUser = userRepository.save(user);

        try {
            Wallet wallet = Wallet.builder()
                    .user(savedUser)
                    .balance(new BigDecimal("100.00"))
                    .currency("USD")
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



