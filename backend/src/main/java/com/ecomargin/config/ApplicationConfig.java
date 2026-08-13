package com.ecomargin.config;

import com.ecomargin.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
@RequiredArgsConstructor
public class ApplicationConfig {

    private final UserRepository userRepository;

    @Bean
    public UserDetailsService userDetailsService() {
        return username -> {
            if (username == null || username.isBlank()) {
                throw new UsernameNotFoundException("Empty username provided");
            }
            String cleanInput = username.trim();
            if (cleanInput.contains("@")) {
                return userRepository.findByEmailIgnoreCase(cleanInput.toLowerCase())
                        .orElseThrow(() -> new UsernameNotFoundException("User not found with email: " + cleanInput));
            } else {
                String phoneFormatted = cleanInput;
                if (!phoneFormatted.startsWith("+") && phoneFormatted.length() == 10 && phoneFormatted.matches("\\d+")) {
                    phoneFormatted = "+91" + phoneFormatted;
                }
                final String searchPhone = phoneFormatted;
                return userRepository.findByPhoneNumber(searchPhone)
                        .or(() -> userRepository.findByPhoneNumber(cleanInput))
                        .or(() -> userRepository.findByEmailIgnoreCase(cleanInput.toLowerCase()))
                        .orElseThrow(() -> new UsernameNotFoundException("User not found with identifier: " + cleanInput));
            }
        };
    }

    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider();
        authProvider.setUserDetailsService(userDetailsService());
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
