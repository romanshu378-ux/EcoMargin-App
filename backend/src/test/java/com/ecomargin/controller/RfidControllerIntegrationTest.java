package com.ecomargin.controller;

import com.ecomargin.model.RfidCard;
import com.ecomargin.model.User;
import com.ecomargin.repository.RfidCardRepository;
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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class RfidControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private RfidCardRepository rfidCardRepository;

    @Autowired
    private UserRepository userRepository;

    private User testUser;

    @BeforeEach
    void setUp() {
        rfidCardRepository.deleteAll();
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
    void testGetRfidCardNotFound() throws Exception {
        mockMvc.perform(get("/api/v1/rfid"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("No RFID card linked to this account."));
    }

    @Test
    @WithMockUser(username = "test@ecomargin.com")
    void testLinkRfidCard() throws Exception {
        String payload = """
                {
                    "cardNumber": "1234-5678-9012-3456",
                    "cardUid": "AA:BB:CC:DD",
                    "linkedVehicle": "Tesla Model Y"
                }
                """;

        mockMvc.perform(post("/api/v1/rfid/link")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.cardNumber").value("XXXX-XXXX-3456"))
                .andExpect(jsonPath("$.cardUid").value("XXXX-XXXX-C:DD"))
                .andExpect(jsonPath("$.status").value("ACTIVE"));
    }

    @Test
    @WithMockUser(username = "test@ecomargin.com")
    void testUnlinkRfidCard() throws Exception {
        RfidCard card = RfidCard.builder()
                .user(testUser)
                .cardNumber("9999-8888-7777-6666")
                .cardUid("EE:FF:00:11")
                .status("ACTIVE")
                .build();
        rfidCardRepository.save(card);

        mockMvc.perform(post("/api/v1/rfid/unlink"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("RFID card unlinked successfully."));
    }

    @Test
    @WithMockUser(username = "test@ecomargin.com")
    void testBlockRfidCard() throws Exception {
        RfidCard card = RfidCard.builder()
                .user(testUser)
                .cardNumber("5555-5555-5555-5555")
                .cardUid("22:33:44:55")
                .status("ACTIVE")
                .build();
        rfidCardRepository.save(card);

        mockMvc.perform(post("/api/v1/rfid/block"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("BLOCKED"));
    }
}
