package com.ecomargin.service;

import com.ecomargin.controller.AuthRequest;
import com.ecomargin.controller.AuthResponse;
import com.ecomargin.controller.RegisterRequest;
import com.ecomargin.controller.RegisterResponse;
import com.ecomargin.exception.UserAlreadyExistsException;
import com.ecomargin.model.User;
import com.ecomargin.repository.RoleRepository;
import com.ecomargin.repository.UserRepository;
import com.ecomargin.repository.WalletRepository;
import com.ecomargin.security.JwtUtil;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private RoleRepository roleRepository;

    @Mock
    private WalletRepository walletRepository;

    @Mock
    private JwtUtil jwtUtil;

    @Mock
    private com.ecomargin.repository.RefreshTokenRepository refreshTokenRepository;

    @Mock
    private AuthenticationManager authenticationManager;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private AuthService authService;

    private User sampleUser;

    @BeforeEach
    void setUp() {
        sampleUser = User.builder()
                .id(1L)
                .email("customer@ecomargin.com")
                .password("$2a$12$R.S4wN6M2Xq8vK/h7F0.Qe.Hvx7K4U5tQ3BswY00sN1b8lO.Wd7iG")
                .isVerified(true)
                .build();
    }

    @Test
    @DisplayName("register: Successful registration creates user and returns 201 equivalent message")
    void testRegister_Success() {
        RegisterRequest request = RegisterRequest.builder()
                .name("Alex Rivers")
                .email("newcustomer@ecomargin.com")
                .password("password123")
                .phoneNumber("1234567890")
                .build();

        when(userRepository.findByEmailIgnoreCase("newcustomer@ecomargin.com")).thenReturn(Optional.empty());
        when(passwordEncoder.encode("password123")).thenReturn("bcrypt_encoded_password");
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User u = invocation.getArgument(0);
            u.setId(2L);
            return u;
        });

        RegisterResponse response = authService.register(request);

        assertNotNull(response);
        assertEquals("newcustomer@ecomargin.com", response.getEmail());
        assertTrue(response.getMessage().contains("Account created successfully"));
        verify(userRepository, times(1)).save(any(User.class));
    }

    @Test
    @DisplayName("register: Duplicate email throws UserAlreadyExistsException (409)")
    void testRegister_DuplicateEmail() {
        RegisterRequest request = RegisterRequest.builder()
                .name("Jane Driver")
                .email("customer@ecomargin.com")
                .password("password123")
                .build();

        when(userRepository.findByEmailIgnoreCase("customer@ecomargin.com")).thenReturn(Optional.of(sampleUser));

        assertThrows(UserAlreadyExistsException.class, () -> authService.register(request));
    }

    @Test
    @DisplayName("authenticate: Valid credentials return HTTP 200 equivalent token response")
    void testAuthenticate_Success() {
        AuthRequest request = AuthRequest.builder()
                .email("  CUSTOMER@EcoMargin.com  ")
                .password("password123")
                .build();

        when(userRepository.findByEmailIgnoreCase("customer@ecomargin.com")).thenReturn(Optional.of(sampleUser));
        when(jwtUtil.generateToken(sampleUser)).thenReturn("jwt.token.string");
        when(refreshTokenRepository.save(any())).thenAnswer(invocation -> com.ecomargin.model.RefreshToken.builder().token("mock-refresh-token").build());

        AuthResponse response = authService.authenticate(request);

        assertNotNull(response);
        assertEquals("jwt.token.string", response.getAccessToken());
        assertNotNull(response.getRefreshToken());
        verify(authenticationManager, times(1)).authenticate(any(UsernamePasswordAuthenticationToken.class));
    }

    @Test
    @DisplayName("authenticate: Invalid password throws BadCredentialsException")
    void testAuthenticate_InvalidPassword() {
        AuthRequest request = AuthRequest.builder()
                .email("customer@ecomargin.com")
                .password("wrongpassword")
                .build();

        when(userRepository.findByEmailIgnoreCase("customer@ecomargin.com")).thenReturn(Optional.of(sampleUser));
        doThrow(new BadCredentialsException("Bad credentials"))
                .when(authenticationManager).authenticate(any(UsernamePasswordAuthenticationToken.class));

        assertThrows(BadCredentialsException.class, () -> authService.authenticate(request));
    }

    @Test
    @DisplayName("authenticate: Unknown email throws BadCredentialsException (401)")
    void testAuthenticate_UnknownEmail() {
        AuthRequest request = AuthRequest.builder()
                .email("unknown@ecomargin.com")
                .password("password123")
                .build();

        when(userRepository.findByEmailIgnoreCase("unknown@ecomargin.com")).thenReturn(Optional.empty());

        assertThrows(BadCredentialsException.class, () -> authService.authenticate(request));
    }

    @Test
    @DisplayName("authenticate: Empty email or password throws IllegalArgumentException (400)")
    void testAuthenticate_EmptyCredentials() {
        AuthRequest request = AuthRequest.builder()
                .email("")
                .password("")
                .build();

        assertThrows(IllegalArgumentException.class, () -> authService.authenticate(request));
    }
}


