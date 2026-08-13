package com.ecomargin.controller;

import com.ecomargin.config.DatabaseSeeder;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.is;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AppConfigControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private DatabaseSeeder databaseSeeder;

    @BeforeEach
    void setup() {
        databaseSeeder.run();
    }

    @Test
    @DisplayName("GET /api/v1/app/config returns settings including min_wallet_balance_to_start")
    void testGetAppConfig() throws Exception {
        mockMvc.perform(get("/api/v1/app/config").contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.min_wallet_balance_to_start").exists())
                .andExpect(jsonPath("$.default_charging_rate_per_kwh").exists())
                .andExpect(jsonPath("$.home_sections").exists());
    }

    @Test
    @DisplayName("GET /api/v1/faqs returns seeded FAQs list")
    void testGetFaqs() throws Exception {
        mockMvc.perform(get("/api/v1/faqs"))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON));
    }

    @Test
    @DisplayName("GET /api/v1/offers returns active offers")
    void testGetOffers() throws Exception {
        mockMvc.perform(get("/api/v1/offers"))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON));
    }

    @Test
    @DisplayName("GET /api/v1/support returns support information")
    void testGetSupport() throws Exception {
        mockMvc.perform(get("/api/v1/support"))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON));
    }
}
