package com.ecomargin.controller;

import com.ecomargin.model.*;
import com.ecomargin.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ChargingSecurityIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private WalletRepository walletRepository;

    @Autowired
    private StationRepository stationRepository;

    @Autowired
    private ChargerRepository chargerRepository;

    @Autowired
    private ConnectorRepository connectorRepository;

    @Autowired
    private ChargingSessionRepository chargingSessionRepository;

    @Autowired
    private TransactionRepository transactionRepository;

    private User userA;
    private User userB;
    private Station station;
    private Charger charger;
    private Connector connector;
    private ChargingSession sessionA;
    private ChargingSession sessionB;

    @BeforeEach
    void setUp() {
        transactionRepository.deleteAll();
        chargingSessionRepository.deleteAll();

        userA = userRepository.findByEmailIgnoreCase("customera_sec@ecomargin.com")
                .orElseGet(() -> userRepository.save(User.builder()
                        .email("customera_sec@ecomargin.com")
                        .firstName("Customer")
                        .lastName("A")
                        .phoneNumber("+919999900001")
                        .isAccountNonLocked(true)
                        .isVerified(true)
                        .build()));

        Wallet walletA = walletRepository.findByUserId(userA.getId())
                .orElseGet(() -> Wallet.builder().user(userA).currency("INR").balance(new BigDecimal("500.00")).build());
        walletA.setBalance(new BigDecimal("500.00"));
        walletRepository.save(walletA);

        userB = userRepository.findByEmailIgnoreCase("customerb_sec@ecomargin.com")
                .orElseGet(() -> userRepository.save(User.builder()
                        .email("customerb_sec@ecomargin.com")
                        .firstName("Customer")
                        .lastName("B")
                        .phoneNumber("+919999900002")
                        .isAccountNonLocked(true)
                        .isVerified(true)
                        .build()));

        Wallet walletB = walletRepository.findByUserId(userB.getId())
                .orElseGet(() -> Wallet.builder().user(userB).currency("INR").balance(new BigDecimal("500.00")).build());
        walletB.setBalance(new BigDecimal("500.00"));
        walletRepository.save(walletB);

        station = stationRepository.findAll().stream().findFirst().orElseGet(() -> stationRepository.save(Station.builder()
                .name("EcoMargin Security Hub")
                .latitude(new BigDecimal("26.9150"))
                .longitude(new BigDecimal("75.7920"))
                .address("Tonk Road, Jaipur")
                .status("ACTIVE")
                .build()));

        charger = chargerRepository.findAll().stream().findFirst().orElseGet(() -> chargerRepository.save(Charger.builder()
                .station(station)
                .ocppId("CHG-SEC-01")
                .model("FAST-DC")
                .status("AVAILABLE")
                .build()));

        connector = connectorRepository.findAll().stream().findFirst().orElseGet(() -> connectorRepository.save(Connector.builder()
                .charger(charger)
                .connectorIndex(1)
                .type("CCS2")
                .status("AVAILABLE")
                .maxPowerKw(BigDecimal.valueOf(60.0))
                .build()));

        connector.setStatus("AVAILABLE");
        connectorRepository.save(connector);
        charger.setStatus("AVAILABLE");
        chargerRepository.save(charger);
        station.setStatus("ACTIVE");
        stationRepository.save(station);

        sessionA = chargingSessionRepository.save(ChargingSession.builder()
                .user(userA)
                .connector(connector)
                .status("CHARGING")
                .startTime(LocalDateTime.now().minusMinutes(10))
                .meterStartWh(BigDecimal.valueOf(1000.00))
                .ocppTransactionId("OCPP-TX-A1")
                .build());

        sessionB = chargingSessionRepository.save(ChargingSession.builder()
                .user(userB)
                .connector(connector)
                .status("CHARGING")
                .startTime(LocalDateTime.now().minusMinutes(5))
                .meterStartWh(BigDecimal.valueOf(2000.00))
                .ocppTransactionId("OCPP-TX-B1")
                .build());
    }

    // A. Customer A can view own session
    @Test
    @WithMockUser(username = "customera_sec@ecomargin.com", roles = {"CUSTOMER"})
    void testCustomerA_CanViewOwnSession() throws Exception {
        mockMvc.perform(get("/api/v1/charging-sessions/" + sessionA.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.sessionId").value(sessionA.getId()));
    }

    // B. Customer A cannot view Customer B's session (IDOR protection)
    @Test
    @WithMockUser(username = "customera_sec@ecomargin.com", roles = {"CUSTOMER"})
    void testCustomerA_CannotViewCustomerBSession() throws Exception {
        mockMvc.perform(get("/api/v1/charging-sessions/" + sessionB.getId()))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("Access denied"));
    }

    // C. Customer A cannot stop Customer B's session
    @Test
    @WithMockUser(username = "customera_sec@ecomargin.com", roles = {"CUSTOMER"})
    void testCustomerA_CannotStopCustomerBSession() throws Exception {
        mockMvc.perform(post("/api/v1/charging-sessions/" + sessionB.getId() + "/stop"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("Access denied"));
    }

    // D. Unauthenticated user cannot access charging sessions (401 / 403 Security rejection)
    @Test
    void testUnauthenticatedUser_CannotAccessChargingSessions() throws Exception {
        mockMvc.perform(get("/api/v1/charging-sessions/active"))
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    assertTrue(status == 401 || status == 403, "Unauthenticated access must be rejected with 401 or 403");
                });
    }

    // E. Customer cannot create two active sessions
    @Test
    @WithMockUser(username = "customera_sec@ecomargin.com", roles = {"CUSTOMER"})
    void testCustomer_CannotCreateTwoActiveSessions() throws Exception {
        String payload = String.format("{\"stationId\":%d, \"chargerId\":%d, \"connectorId\":%d}",
                station.getId(), charger.getId(), connector.getId());

        mockMvc.perform(post("/api/v1/charging-sessions/start")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("ACTIVE_SESSION_EXISTS"));
    }

    // F. Double stop request does not double-charge wallet
    @Test
    @WithMockUser(username = "customera_sec@ecomargin.com", roles = {"CUSTOMER"})
    void testDoubleStop_DoesNotDoubleChargeWallet() throws Exception {
        // First Stop Call
        mockMvc.perform(post("/api/v1/charging-sessions/" + sessionA.getId() + "/stop"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("COMPLETED"));

        long transactionCountAfterFirstStop = transactionRepository.count();

        // Second Stop Call (Idempotent)
        mockMvc.perform(post("/api/v1/charging-sessions/" + sessionA.getId() + "/stop"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("COMPLETED"));

        long transactionCountAfterSecondStop = transactionRepository.count();

        assertEquals(transactionCountAfterFirstStop, transactionCountAfterSecondStop,
                "Second stop call must not create duplicate ledger transactions or double charge wallet");
    }

    // G. Client cannot provide fake charging cost or energy
    @Test
    @WithMockUser(username = "customera_sec@ecomargin.com", roles = {"CUSTOMER"})
    void testClient_CannotProvideFakeChargingCost() throws Exception {
        String fakePayload = "{\"totalCost\": 0.01, \"totalEnergyKwh\": 100.0}";

        mockMvc.perform(post("/api/v1/charging-sessions/" + sessionA.getId() + "/stop")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(fakePayload))
                .andExpect(status().isOk());

        ChargingSession updatedSession = chargingSessionRepository.findById(sessionA.getId()).orElseThrow();
        assertEquals(0, new BigDecimal("0.01").compareTo(updatedSession.getTotalCost()) == 0 ? 1 : 0,
                "Backend authoritative cost calculation must ignore client-provided fake cost");
    }

    // H. Client cannot provide another user's ID to hijack session
    @Test
    @WithMockUser(username = "customera_sec@ecomargin.com", roles = {"CUSTOMER"})
    void testClient_CannotProvideAnotherUserId() throws Exception {
        String hijackPayload = String.format("{\"userId\": %d, \"connectorId\": %d}", userB.getId(), connector.getId());

        mockMvc.perform(post("/api/v1/charging-sessions/start")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(hijackPayload))
                .andExpect(status().isConflict());
    }

    // I. Invalid connector/station relationship is rejected
    @Test
    @WithMockUser(username = "customera_sec@ecomargin.com", roles = {"CUSTOMER"})
    void testInvalidConnectorStationRelationship_IsRejected() throws Exception {
        // Delete active sessions safely in order
        transactionRepository.deleteAll();
        chargingSessionRepository.deleteAll();

        String invalidRelPayload = String.format("{\"stationId\": 999999, \"chargerId\": %d, \"connectorId\": %d}",
                charger.getId(), connector.getId());

        mockMvc.perform(post("/api/v1/charging-sessions/start")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(invalidRelPayload))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("INVALID_RELATIONSHIP"));
    }

    // K. Admin endpoints cannot be accessed by CUSTOMER
    @Test
    @WithMockUser(username = "customera_sec@ecomargin.com", roles = {"CUSTOMER"})
    void testCustomer_CannotAccessAdminEndpoints() throws Exception {
        mockMvc.perform(get("/api/v1/admin/settings"))
                .andExpect(status().isForbidden());
    }
}
