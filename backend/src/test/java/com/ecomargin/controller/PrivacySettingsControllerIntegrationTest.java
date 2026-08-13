package com.ecomargin.controller;

import com.ecomargin.model.User;
import com.ecomargin.repository.PrivacySettingsRepository;
import com.ecomargin.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class PrivacySettingsControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private PrivacySettingsRepository privacySettingsRepository;

    @Autowired
    private UserRepository userRepository;

    private User testUser;

    @BeforeEach
    void setUp() {
        privacySettingsRepository.deleteAll();
        testUser = userRepository.findByEmailIgnoreCase("test@ecomargin.com")
                .orElseGet(() -> userRepository.save(User.builder()
                        .email("test@ecomargin.com")
                        .password("password123")
                        .firstName("Test")
                        .lastName("User")
                        .phoneNumber("+917777777777")
                        .isVerified(true)
                        .isAccountNonLocked(true)
                        .build()));
    }

    @Test
    @WithMockUser(username = "test@ecomargin.com")
    void testGetPrivacySettingsAutoCreatesDefault() throws Exception {
        mockMvc.perform(get("/api/v1/privacy"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.locationPermission").value(true))
                .andExpect(jsonPath("$.locationSharing").value(true))
                .andExpect(jsonPath("$.pushNotifications").value(true));
    }

    @Test
    @WithMockUser(username = "test@ecomargin.com")
    void testUpdatePrivacySettings() throws Exception {
        String payload = """
                {
                    "locationPermission": false,
                    "locationSharing": false,
                    "pushNotifications": false
                }
                """;

        mockMvc.perform(put("/api/v1/privacy")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.locationPermission").value(false))
                .andExpect(jsonPath("$.locationSharing").value(false))
                .andExpect(jsonPath("$.pushNotifications").value(false));
    }
}
