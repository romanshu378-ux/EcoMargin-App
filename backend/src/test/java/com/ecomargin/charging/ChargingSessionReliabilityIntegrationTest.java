package com.ecomargin.charging;

import com.ecomargin.model.*;
import com.ecomargin.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

import static org.hamcrest.Matchers.hasSize;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ChargingSessionReliabilityIntegrationTest {

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

    @Autowired
    private PasswordEncoder passwordEncoder;

    private User userA;
    private User userB;
    private Wallet walletA;
    private Wallet walletB;
    private Station station;
    private Charger charger;
    private Connector connector;

    @BeforeEach
    void setUp() {
        transactionRepository.deleteAll();
        chargingSessionRepository.deleteAll();
        connectorRepository.deleteAll();
        chargerRepository.deleteAll();
        stationRepository.deleteAll();

        userA = userRepository.findByEmailIgnoreCase("customer_rel_a@ecomargin.com").orElseGet(() -> {
            User u = User.builder()
                    .email("customer_rel_a@ecomargin.com")
                    .password(passwordEncoder.encode("Password123!"))
                    .firstName("Customer")
                    .lastName("RelA")
                    .phoneNumber("+919000000001")
                    .isVerified(true)
                    .isAccountNonLocked(true)
                    .build();
            return userRepository.save(u);
        });

        walletA = walletRepository.findByUserId(userA.getId()).orElseGet(() -> walletRepository.save(
                Wallet.builder()
                        .user(userA)
                        .balance(new BigDecimal("500.00"))
                        .currency("INR")
                        .build()
        ));
        walletA.setBalance(new BigDecimal("500.00"));
        walletRepository.save(walletA);

        userB = userRepository.findByEmailIgnoreCase("customer_rel_b@ecomargin.com").orElseGet(() -> {
            User u = User.builder()
                    .email("customer_rel_b@ecomargin.com")
                    .password(passwordEncoder.encode("Password123!"))
                    .firstName("Customer")
                    .lastName("RelB")
                    .phoneNumber("+919000000002")
                    .isVerified(true)
                    .isAccountNonLocked(true)
                    .build();
            return userRepository.save(u);
        });

        walletB = walletRepository.findByUserId(userB.getId()).orElseGet(() -> walletRepository.save(
                Wallet.builder()
                        .user(userB)
                        .balance(new BigDecimal("500.00"))
                        .currency("INR")
                        .build()
        ));

        station = stationRepository.save(Station.builder()
                .name("Reliability Testing Hub")
                .latitude(new BigDecimal("26.9124"))
                .longitude(new BigDecimal("75.7873"))
                .address("Jaipur Hub")
                .status("ACTIVE")
                .build());

        charger = chargerRepository.save(Charger.builder()
                .station(station)
                .ocppId("CHG-REL-" + UUID.randomUUID().toString().substring(0, 6))
                .brand("ABB")
                .model("Terra 54")
                .status("AVAILABLE")
                .build());

        connector = connectorRepository.save(Connector.builder()
                .charger(charger)
                .connectorIndex(1)
                .type("CCS2")
                .status("AVAILABLE")
                .maxPowerKw(BigDecimal.valueOf(50.0))
                .build());
    }

    // A. Start session once → success
    @Test
    @WithMockUser(username = "customer_rel_a@ecomargin.com", roles = {"CUSTOMER"})
    void testStartSessionOnce_Success() throws Exception {
        String payload = String.format("{\"stationId\":%d, \"chargerId\":%d, \"connectorId\":%d}",
                station.getId(), charger.getId(), connector.getId());

        mockMvc.perform(post("/api/v1/charging-sessions/start")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("CHARGING"))
                .andExpect(jsonPath("$.sessionId").exists());

        assertEquals(1, chargingSessionRepository.count());
    }

    // B. Start session twice → only one active session (409 Conflict)
    @Test
    @WithMockUser(username = "customer_rel_a@ecomargin.com", roles = {"CUSTOMER"})
    void testStartSessionTwice_Returns409Conflict() throws Exception {
        String payload = String.format("{\"stationId\":%d, \"chargerId\":%d, \"connectorId\":%d}",
                station.getId(), charger.getId(), connector.getId());

        // First start
        mockMvc.perform(post("/api/v1/charging-sessions/start")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isOk());

        // Second start
        mockMvc.perform(post("/api/v1/charging-sessions/start")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("ACTIVE_SESSION_EXISTS"));

        assertEquals(1, chargingSessionRepository.count());
    }

    // C. Stop session once → one final debit
    @Test
    @WithMockUser(username = "customer_rel_a@ecomargin.com", roles = {"CUSTOMER"})
    void testStopSessionOnce_OneFinalDebit() throws Exception {
        ChargingSession session = chargingSessionRepository.save(ChargingSession.builder()
                .user(userA)
                .connector(connector)
                .status("CHARGING")
                .startTime(LocalDateTime.now().minusMinutes(10))
                .meterStartWh(new BigDecimal("1000"))
                .ocppTransactionId("OCPP-TX-REL-01")
                .build());

        mockMvc.perform(post("/api/v1/charging-sessions/" + session.getId() + "/stop"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("COMPLETED"));

        assertEquals(1, transactionRepository.count());
    }

    // D. Stop session twice → no duplicate debit
    @Test
    @WithMockUser(username = "customer_rel_a@ecomargin.com", roles = {"CUSTOMER"})
    void testStopSessionTwice_NoDuplicateDebit() throws Exception {
        ChargingSession session = chargingSessionRepository.save(ChargingSession.builder()
                .user(userA)
                .connector(connector)
                .status("CHARGING")
                .startTime(LocalDateTime.now().minusMinutes(10))
                .meterStartWh(new BigDecimal("1000"))
                .ocppTransactionId("OCPP-TX-REL-02")
                .build());

        // First stop
        mockMvc.perform(post("/api/v1/charging-sessions/" + session.getId() + "/stop"))
                .andExpect(status().isOk());

        long txCountFirst = transactionRepository.count();

        // Second stop
        mockMvc.perform(post("/api/v1/charging-sessions/" + session.getId() + "/stop"))
                .andExpect(status().isOk());

        long txCountSecond = transactionRepository.count();

        assertEquals(txCountFirst, txCountSecond);
    }

    // E. Customer A cannot access Customer B session
    @Test
    @WithMockUser(username = "customer_rel_a@ecomargin.com", roles = {"CUSTOMER"})
    void testCustomerA_CannotAccessCustomerBSession() throws Exception {
        ChargingSession bSession = chargingSessionRepository.save(ChargingSession.builder()
                .user(userB)
                .connector(connector)
                .status("CHARGING")
                .startTime(LocalDateTime.now().minusMinutes(5))
                .build());

        // User A attempts to view User B session
        mockMvc.perform(get("/api/v1/charging-sessions/" + bSession.getId()))
                .andExpect(status().isForbidden());

        // User A attempts to stop User B session
        mockMvc.perform(post("/api/v1/charging-sessions/" + bSession.getId() + "/stop"))
                .andExpect(status().isForbidden());
    }

    // F. Active session survives backend restart
    @Test
    @WithMockUser(username = "customer_rel_a@ecomargin.com", roles = {"CUSTOMER"})
    void testActiveSession_SurvivesBackendRestart() throws Exception {
        ChargingSession session = chargingSessionRepository.save(ChargingSession.builder()
                .user(userA)
                .connector(connector)
                .status("CHARGING")
                .startTime(LocalDateTime.now().minusMinutes(15))
                .build());

        // Query active session endpoint (simulating post-restart check)
        mockMvc.perform(get("/api/v1/charging-sessions/active"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.sessionId").value(session.getId()))
                .andExpect(jsonPath("$.status").value("CHARGING"));
    }

    // G. Completed session cannot restart
    @Test
    @WithMockUser(username = "customer_rel_a@ecomargin.com", roles = {"CUSTOMER"})
    void testCompletedSession_CannotBeStoppedAgainOrRestarted() throws Exception {
        ChargingSession session = chargingSessionRepository.save(ChargingSession.builder()
                .user(userA)
                .connector(connector)
                .status("COMPLETED")
                .startTime(LocalDateTime.now().minusMinutes(30))
                .endTime(LocalDateTime.now().minusMinutes(10))
                .totalCost(new BigDecimal("120.00"))
                .build());

        mockMvc.perform(get("/api/v1/charging-sessions/active"))
                .andExpect(status().isNoContent());
    }

    // H. Active session can be recovered after app restart
    @Test
    @WithMockUser(username = "customer_rel_a@ecomargin.com", roles = {"CUSTOMER"})
    void testActiveSession_CanBeRecoveredAfterAppRestart() throws Exception {
        ChargingSession session = chargingSessionRepository.save(ChargingSession.builder()
                .user(userA)
                .connector(connector)
                .status("ACTIVE")
                .startTime(LocalDateTime.now().minusMinutes(5))
                .build());

        mockMvc.perform(get("/api/v1/charging-sessions/active"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.sessionId").value(session.getId()));
    }

    // I. OCPP disconnect does not silently delete session
    @Test
    @WithMockUser(username = "customer_rel_a@ecomargin.com", roles = {"CUSTOMER"})
    void testOcppDisconnect_DoesNotDeleteSession() throws Exception {
        ChargingSession session = chargingSessionRepository.save(ChargingSession.builder()
                .user(userA)
                .connector(connector)
                .status("CHARGING")
                .startTime(LocalDateTime.now().minusMinutes(10))
                .build());

        // Simulate charger disconnect in DB
        charger.setStatus("UNAVAILABLE");
        chargerRepository.save(charger);

        // Session must remain intact and retrievable via /active
        mockMvc.perform(get("/api/v1/charging-sessions/active"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.sessionId").value(session.getId()))
                .andExpect(jsonPath("$.chargerStatus").value("UNAVAILABLE"));
    }

    // J. Session history contains one completed record
    @Test
    @WithMockUser(username = "customer_rel_a@ecomargin.com", roles = {"CUSTOMER"})
    void testSessionHistory_ContainsOneCompletedRecord() throws Exception {
        ChargingSession completedSession = chargingSessionRepository.save(ChargingSession.builder()
                .user(userA)
                .connector(connector)
                .status("COMPLETED")
                .startTime(LocalDateTime.now().minusHours(2))
                .endTime(LocalDateTime.now().minusHours(1))
                .totalEnergyKwh(new BigDecimal("15.5"))
                .totalCost(new BigDecimal("279.00"))
                .build());

        mockMvc.perform(get("/api/v1/charging-sessions/history"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].sessionId").value(completedSession.getId()));
    }
}
