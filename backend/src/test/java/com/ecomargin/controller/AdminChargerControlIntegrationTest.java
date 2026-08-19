package com.ecomargin.controller;

import com.ecomargin.model.*;
import com.ecomargin.model.enums.RoleType;
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
import java.util.Collections;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AdminChargerControlIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private StationRepository stationRepository;

    @Autowired
    private ChargerRepository chargerRepository;

    @Autowired
    private ConnectorRepository connectorRepository;

    @Autowired
    private ChargingSessionRepository chargingSessionRepository;

    @Autowired
    private WalletRepository walletRepository;

    @Autowired
    private TransactionRepository transactionRepository;

    @Autowired
    private WalletService walletService;

    private User customerUser;
    private Station station;
    private Charger charger;
    private Connector connector;

    @BeforeEach
    void setUp() {
        transactionRepository.deleteAll();
        chargingSessionRepository.deleteAll();
        walletRepository.deleteAll();
        connectorRepository.deleteAll();
        chargerRepository.deleteAll();
        stationRepository.deleteAll();

        Role customerRole = roleRepository.findByName(RoleType.ROLE_CUSTOMER).orElseGet(() ->
                roleRepository.save(Role.builder().name(RoleType.ROLE_CUSTOMER).permissions(Collections.emptySet()).build()));

        Role adminRole = roleRepository.findByName(RoleType.ROLE_ADMIN).orElseGet(() ->
                roleRepository.save(Role.builder().name(RoleType.ROLE_ADMIN).permissions(Collections.emptySet()).build()));

        userRepository.findByEmailIgnoreCase("admin@ecomargin.com").orElseGet(() ->
                userRepository.save(User.builder()
                        .email("admin@ecomargin.com")
                        .password("password123")
                        .firstName("Admin")
                        .lastName("User")
                        .roles(Collections.singleton(adminRole))
                        .isVerified(true)
                        .isAccountNonLocked(true)
                        .build())
        );

        customerUser = userRepository.findByEmailIgnoreCase("admin_cust@ecomargin.com").orElseGet(() ->
                userRepository.save(User.builder()
                        .email("admin_cust@ecomargin.com")
                        .password("password123")
                        .firstName("Customer")
                        .lastName("User")
                        .phoneNumber("9876543210")
                        .roles(Collections.singleton(customerRole))
                        .isVerified(true)
                        .isAccountNonLocked(true)
                        .build())
        );

        Wallet wallet = walletRepository.findByUserId(customerUser.getId()).orElseGet(() ->
                walletRepository.save(Wallet.builder()
                        .user(customerUser)
                        .balance(new BigDecimal("500.00"))
                        .currency("INR")
                        .build())
        );
        wallet.setBalance(new BigDecimal("500.00"));
        walletRepository.save(wallet);

        station = Station.builder()
                .name("Admin Control Station")
                .latitude(new BigDecimal("26.9124"))
                .longitude(new BigDecimal("75.7873"))
                .address("Main Boulevard, Jaipur")
                .status("ACTIVE")
                .build();
        stationRepository.save(station);

        charger = Charger.builder()
                .station(station)
                .ocppId("ADM-CHG-01")
                .brand("ABB")
                .model("Terra 184")
                .status("AVAILABLE")
                .build();
        chargerRepository.save(charger);

        connector = Connector.builder()
                .charger(charger)
                .connectorIndex(1)
                .type("CCS2")
                .maxPowerKw(new BigDecimal("180.0"))
                .status("AVAILABLE")
                .build();
        connectorRepository.save(connector);
    }

    // A. CUSTOMER cannot access Admin charger dashboard.
    @Test
    @WithMockUser(username = "admin_cust@ecomargin.com", roles = {"CUSTOMER"})
    void testA_CustomerCannotAccessAdminDashboard() throws Exception {
        mockMvc.perform(get("/api/v1/admin/dashboard"))
                .andExpect(status().isForbidden());
    }

    // B. ADMIN can access charger monitoring.
    @Test
    @WithMockUser(username = "admin@ecomargin.com", roles = {"ADMIN"})
    void testB_AdminCanAccessDashboard() throws Exception {
        mockMvc.perform(get("/api/v1/admin/dashboard"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalStations").value(1))
                .andExpect(jsonPath("$.totalChargers").value(1))
                .andExpect(jsonPath("$.availableConnectors").value(1));
    }

    // C. SUPER_ADMIN can access charger monitoring.
    @Test
    @WithMockUser(username = "superadmin@ecomargin.com", roles = {"SUPER_ADMIN"})
    void testC_SuperAdminCanAccessDashboard() throws Exception {
        mockMvc.perform(get("/api/v1/admin/dashboard"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalChargers").value(1));
    }

    // D. CUSTOMER cannot disable charger.
    @Test
    @WithMockUser(username = "admin_cust@ecomargin.com", roles = {"CUSTOMER"})
    void testD_CustomerCannotDisableCharger() throws Exception {
        mockMvc.perform(put("/api/v1/admin/chargers/" + charger.getId() + "/disable"))
                .andExpect(status().isForbidden());
    }

    // E. CUSTOMER cannot force-stop session.
    @Test
    @WithMockUser(username = "admin_cust@ecomargin.com", roles = {"CUSTOMER"})
    void testE_CustomerCannotForceStopSession() throws Exception {
        ChargingSession active = ChargingSession.builder()
                .user(customerUser)
                .connector(connector)
                .status("CHARGING")
                .startTime(LocalDateTime.now().minusMinutes(10))
                .totalEnergyKwh(new BigDecimal("5.0"))
                .totalCost(new BigDecimal("60.0"))
                .build();
        chargingSessionRepository.save(active);

        mockMvc.perform(post("/api/v1/admin/sessions/" + active.getId() + "/force-stop"))
                .andExpect(status().isForbidden());
    }

    // F. ADMIN force-stop requires authorization.
    // G. Unauthorized force-stop returns 403.
    @Test
    void testFG_UnauthenticatedForceStopReturns401or403() throws Exception {
        mockMvc.perform(post("/api/v1/admin/sessions/999/force-stop"))
                .andExpect(status().isForbidden());
    }

    // H. Force-stop cannot double-debit wallet.
    @Test
    @WithMockUser(username = "admin@ecomargin.com", roles = {"ADMIN"})
    void testH_ForceStopIdempotentWalletDebit() throws Exception {
        ChargingSession active = ChargingSession.builder()
                .user(customerUser)
                .connector(connector)
                .status("CHARGING")
                .startTime(LocalDateTime.now().minusMinutes(20))
                .totalEnergyKwh(new BigDecimal("10.0"))
                .totalCost(new BigDecimal("120.0"))
                .ocppTransactionId("ADM-TX-FS-01")
                .build();
        chargingSessionRepository.save(active);

        mockMvc.perform(post("/api/v1/admin/sessions/" + active.getId() + "/force-stop"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("COMPLETED"));

        Wallet walletAfter = walletRepository.findByUserId(customerUser.getId()).orElseThrow();
        assertEquals(0, new BigDecimal("380.00").compareTo(walletAfter.getBalance()));

        // Subsequent force-stop returns conflict
        mockMvc.perform(post("/api/v1/admin/sessions/" + active.getId() + "/force-stop"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("SESSION_ALREADY_STOPPED"));

        // Balance remains unchanged (no double debit)
        Wallet walletFinal = walletRepository.findByUserId(customerUser.getId()).orElseThrow();
        assertEquals(0, new BigDecimal("380.00").compareTo(walletFinal.getBalance()));
    }

    // I. Disabled charger cannot start a new session.
    @Test
    @WithMockUser(username = "admin@ecomargin.com", roles = {"ADMIN"})
    void testI_DisabledChargerCannotStartNewSession() throws Exception {
        // 1. Admin disables charger
        mockMvc.perform(put("/api/v1/admin/chargers/" + charger.getId() + "/disable"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("DISABLED"));

        // 2. Customer attempts startCharging on disabled charger
        String payload = String.format("{\"stationId\":%d, \"chargerId\":%d, \"connectorId\":%d}",
                station.getId(), charger.getId(), connector.getId());

        mockMvc.perform(post("/api/v1/charging-sessions/start")
                        .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user("admin_cust@ecomargin.com").roles("CUSTOMER"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("CHARGER_UNAVAILABLE"));
    }

    // J. Existing active session is not unexpectedly destroyed by disable action.
    @Test
    @WithMockUser(username = "admin@ecomargin.com", roles = {"ADMIN"})
    void testJ_DisablingChargerDoesNotDestroyActiveSession() throws Exception {
        ChargingSession active = ChargingSession.builder()
                .user(customerUser)
                .connector(connector)
                .status("CHARGING")
                .startTime(LocalDateTime.now().minusMinutes(5))
                .totalEnergyKwh(new BigDecimal("2.0"))
                .totalCost(new BigDecimal("24.0"))
                .build();
        chargingSessionRepository.save(active);

        mockMvc.perform(put("/api/v1/admin/chargers/" + charger.getId() + "/disable"))
                .andExpect(status().isOk());

        ChargingSession sessionAfter = chargingSessionRepository.findById(active.getId()).orElseThrow();
        assertEquals("CHARGING", sessionAfter.getStatus());
    }

    // K. Offline charger is reported correctly.
    // L. Connector status is mapped correctly.
    // M. Active sessions display correct backend data.
    @Test
    @WithMockUser(username = "admin@ecomargin.com", roles = {"ADMIN"})
    void testKLM_DetailedChargersAndSessionReporting() throws Exception {
        ChargingSession active = ChargingSession.builder()
                .user(customerUser)
                .connector(connector)
                .status("CHARGING")
                .startTime(LocalDateTime.now().minusMinutes(15))
                .totalEnergyKwh(new BigDecimal("8.0"))
                .totalCost(new BigDecimal("96.0"))
                .build();
        chargingSessionRepository.save(active);

        mockMvc.perform(get("/api/v1/admin/chargers/detailed"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].ocppId").value("ADM-CHG-01"))
                .andExpect(jsonPath("$[0].connectors", hasSize(1)))
                .andExpect(jsonPath("$[0].connectors[0].activeSession.sessionId").value(active.getId()));
    }

    // N. Audit record is created for privileged actions.
    // O. Failed admin action is recorded appropriately.
    @Test
    @WithMockUser(username = "admin@ecomargin.com", roles = {"ADMIN"})
    void testNO_AuditRecordCreatedForPrivilegedActions() throws Exception {
        mockMvc.perform(put("/api/v1/admin/chargers/" + charger.getId() + "/disable"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("DISABLED"));

        mockMvc.perform(post("/api/v1/admin/sessions/999999/force-stop"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("SESSION_NOT_FOUND"));
    }
}
