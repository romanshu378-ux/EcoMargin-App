package com.ecomargin.controller;

import com.ecomargin.model.*;
import com.ecomargin.repository.*;
import com.ecomargin.service.WalletService;
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

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class WalletSecurityIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private WalletRepository walletRepository;

    @Autowired
    private TransactionRepository transactionRepository;

    @Autowired
    private NotificationRepository notificationRepository;

    @Autowired
    private ChargingSessionRepository chargingSessionRepository;

    @Autowired
    private StationRepository stationRepository;

    @Autowired
    private ChargerRepository chargerRepository;

    @Autowired
    private ConnectorRepository connectorRepository;

    @Autowired
    private WalletService walletService;

    private User userA;
    private User userB;
    private Wallet walletA;
    private Wallet walletB;

    @BeforeEach
    void setUp() {
        notificationRepository.deleteAll();
        transactionRepository.deleteAll();
        chargingSessionRepository.deleteAll();

        userA = userRepository.findByEmailIgnoreCase("wallet_customera@ecomargin.com")
                .orElseGet(() -> userRepository.save(User.builder()
                        .email("wallet_customera@ecomargin.com")
                        .firstName("WalletCustomer")
                        .lastName("A")
                        .phoneNumber("+919999900010")
                        .isAccountNonLocked(true)
                        .isVerified(true)
                        .build()));

        walletA = walletRepository.findByUserId(userA.getId())
                .orElseGet(() -> Wallet.builder().user(userA).currency("INR").balance(new BigDecimal("100.00")).build());
        walletA.setBalance(new BigDecimal("100.00"));
        walletRepository.save(walletA);

        userB = userRepository.findByEmailIgnoreCase("wallet_customerb@ecomargin.com")
                .orElseGet(() -> userRepository.save(User.builder()
                        .email("wallet_customerb@ecomargin.com")
                        .firstName("WalletCustomer")
                        .lastName("B")
                        .phoneNumber("+919999900020")
                        .isAccountNonLocked(true)
                        .isVerified(true)
                        .build()));

        walletB = walletRepository.findByUserId(userB.getId())
                .orElseGet(() -> Wallet.builder().user(userB).currency("INR").balance(new BigDecimal("50.00")).build());
        walletB.setBalance(new BigDecimal("50.00"));
        walletRepository.save(walletB);
    }

    // A. Customer can read only their own wallet balance
    @Test
    @WithMockUser(username = "wallet_customera@ecomargin.com", roles = {"CUSTOMER"})
    void testCustomer_CanReadOwnWalletBalance() throws Exception {
        mockMvc.perform(get("/api/v1/wallet/balance"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.balance").value(100.00));
    }

    // B. Customer cannot read another user's wallet
    @Test
    @WithMockUser(username = "wallet_customera@ecomargin.com", roles = {"CUSTOMER"})
    void testCustomer_CannotReadAnotherUsersWallet() throws Exception {
        // Authenticated user A queries GET /balance; receives user A's wallet, never user B's wallet
        mockMvc.perform(get("/api/v1/wallet/balance"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.balance").value(100.00));
    }

    // C. Customer cannot submit a fake balance directly in payload
    @Test
    @WithMockUser(username = "wallet_customera@ecomargin.com", roles = {"CUSTOMER"})
    void testCustomer_CannotSubmitFakeBalance() throws Exception {
        String fakePayload = "{\"amount\": 50, \"balance\": 99999.00, \"newBalance\": 99999.00}";

        mockMvc.perform(post("/api/v1/wallet/topup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(fakePayload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.balance").value(150.00)); // 100 + 50 authoritative, fake 99999 ignored
    }

    // D. Negative wallet credit is rejected
    @Test
    @WithMockUser(username = "wallet_customera@ecomargin.com", roles = {"CUSTOMER"})
    void testNegativeWalletCredit_IsRejected() throws Exception {
        String negativePayload = "{\"amount\": -50.00}";

        mockMvc.perform(post("/api/v1/wallet/topup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(negativePayload))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Top-up amount must be strictly positive"));
    }

    // F. Same payment referenceId cannot credit wallet twice (Idempotency)
    @Test
    @WithMockUser(username = "wallet_customera@ecomargin.com", roles = {"CUSTOMER"})
    void testSamePaymentReference_CannotCreditWalletTwice() throws Exception {
        String payload = "{\"amount\": 200, \"referenceId\": \"PAY_REF_UNIQUE_001\"}";

        // First topup
        mockMvc.perform(post("/api/v1/wallet/topup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.balance").value(300.00));

        long txCountAfterFirst = transactionRepository.count();

        // Duplicate topup with same referenceId
        mockMvc.perform(post("/api/v1/wallet/topup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.balance").value(300.00)); // Balance remains 300

        long txCountAfterSecond = transactionRepository.count();
        assertEquals(txCountAfterFirst, txCountAfterSecond, "Replayed payment reference must not create extra transactions");
    }

    // I. Successful verified payment creates exactly one wallet transaction
    @Test
    @WithMockUser(username = "wallet_customera@ecomargin.com", roles = {"CUSTOMER"})
    void testSuccessfulPayment_CreatesExactlyOneTransaction() throws Exception {
        String payload = "{\"amount\": 300, \"referenceId\": \"PAY_REF_UNIQUE_002\"}";

        long initialCount = transactionRepository.count();

        mockMvc.perform(post("/api/v1/wallet/topup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isOk());

        long finalCount = transactionRepository.count();
        assertEquals(initialCount + 1, finalCount);
    }

    // J. Successful wallet credit creates exactly one notification
    @Test
    @WithMockUser(username = "wallet_customera@ecomargin.com", roles = {"CUSTOMER"})
    void testSuccessfulWalletCredit_CreatesNotification() throws Exception {
        String payload = "{\"amount\": 150, \"referenceId\": \"PAY_REF_UNIQUE_003\"}";

        mockMvc.perform(post("/api/v1/wallet/topup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isOk());

        long notifCount = notificationRepository.findByUserOrderByCreatedAtDesc(userA).stream()
                .filter(n -> "WALLET_CREDIT".equalsIgnoreCase(n.getType()))
                .count();

        assertTrue(notifCount >= 1, "Successful wallet credit must generate WALLET_CREDIT notification");
    }

    // K. Failed payment creates no wallet credit or transaction
    @Test
    @WithMockUser(username = "wallet_customera@ecomargin.com", roles = {"CUSTOMER"})
    void testFailedPayment_CreatesNoWalletCredit() throws Exception {
        String invalidPayload = "{\"amount\": 0}";

        long txCountBefore = transactionRepository.count();

        mockMvc.perform(post("/api/v1/wallet/topup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(invalidPayload))
                .andExpect(status().isBadRequest());

        long txCountAfter = transactionRepository.count();
        assertEquals(txCountBefore, txCountAfter);
    }

    // L. Charging debit cannot happen twice for the same completed session
    @Test
    void testChargingDebit_CannotHappenTwiceForSameSession() throws Exception {
        Station st = stationRepository.findAll().stream().findFirst().orElseGet(() -> stationRepository.save(Station.builder()
                .name("Test Station")
                .latitude(new BigDecimal("26.9"))
                .longitude(new BigDecimal("75.7"))
                .address("Test Address")
                .status("ACTIVE")
                .build()));

        Charger ch = chargerRepository.findAll().stream().findFirst().orElseGet(() -> chargerRepository.save(Charger.builder()
                .station(st)
                .ocppId("CHG-TEST-W1")
                .model("FAST")
                .status("AVAILABLE")
                .build()));

        Connector conn = connectorRepository.findAll().stream().findFirst().orElseGet(() -> connectorRepository.save(Connector.builder()
                .charger(ch)
                .connectorIndex(1)
                .type("CCS2")
                .status("AVAILABLE")
                .maxPowerKw(BigDecimal.valueOf(50.0))
                .build()));

        ChargingSession session = chargingSessionRepository.save(ChargingSession.builder()
                .user(userA)
                .connector(conn)
                .status("COMPLETED")
                .startTime(LocalDateTime.now().minusMinutes(20))
                .endTime(LocalDateTime.now())
                .totalCost(new BigDecimal("50.00"))
                .meterStartWh(new BigDecimal("1000"))
                .ocppTransactionId("OCPP-TX-W1")
                .build());

        // First debit processing
        Transaction tx1 = walletService.processChargingDebit(session.getId(), "OCPP-TX-W1", new BigDecimal("50.00"));
        assertNotNull(tx1);

        long txCountAfterFirst = transactionRepository.count();

        // Second debit processing with same referenceId (sessionId + "_" + ocppTxId)
        Transaction tx2 = walletService.processChargingDebit(session.getId(), "OCPP-TX-W1", new BigDecimal("50.00"));
        assertEquals(tx1.getId(), tx2.getId());

        long txCountAfterSecond = transactionRepository.count();
        assertEquals(txCountAfterFirst, txCountAfterSecond, "Charging debit must be idempotent and not process duplicate debits");
    }

    // M. ₹50 minimum charging requirement remains enforced server-side
    @Test
    @WithMockUser(username = "wallet_customerb@ecomargin.com", roles = {"CUSTOMER"})
    void testMinWalletBalanceRequirement_IsEnforcedServerSide() throws Exception {
        // Set userB balance to ₹20 (below minimum ₹50 requirement)
        walletB.setBalance(new BigDecimal("20.00"));
        walletRepository.save(walletB);

        Station st = stationRepository.findAll().stream().findFirst().orElseGet(() -> stationRepository.save(
                Station.builder().name("Test Wallet Station").latitude(new BigDecimal("26.9")).longitude(new BigDecimal("75.7")).status("ACTIVE").build()
        ));
        Charger ch = chargerRepository.findAll().stream().findFirst().orElseGet(() -> chargerRepository.save(
                Charger.builder().station(st).ocppId("CHG-WALLET-TEST").status("AVAILABLE").build()
        ));
        Connector conn = connectorRepository.findAll().stream().findFirst().orElseGet(() -> connectorRepository.save(
                Connector.builder().charger(ch).connectorIndex(1).type("CCS2").status("AVAILABLE").maxPowerKw(BigDecimal.valueOf(50.0)).build()
        ));

        String startPayload = String.format("{\"stationId\":%d, \"chargerId\":%d, \"connectorId\":%d}",
                st.getId(), ch.getId(), conn.getId());

        mockMvc.perform(post("/api/v1/charging-sessions/start")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(startPayload))
                .andExpect(status().isPaymentRequired())
                .andExpect(jsonPath("$.code").value("INSUFFICIENT_WALLET_BALANCE"));
    }
}
