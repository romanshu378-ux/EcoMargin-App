package com.ecomargin.controller;

import com.ecomargin.controller.dto.StationRequest;
import com.ecomargin.model.*;
import com.ecomargin.model.enums.RoleType;
import com.ecomargin.repository.*;
import com.ecomargin.service.WalletService;
import com.fasterxml.jackson.databind.ObjectMapper;
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
import java.util.List;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AdminStationManagementIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

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
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    private User adminUser;
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

        Role adminRole = roleRepository.findByName(RoleType.ROLE_ADMIN).orElseGet(() ->
                roleRepository.save(Role.builder().name(RoleType.ROLE_ADMIN).permissions(Collections.emptySet()).build()));

        Role customerRole = roleRepository.findByName(RoleType.ROLE_CUSTOMER).orElseGet(() ->
                roleRepository.save(Role.builder().name(RoleType.ROLE_CUSTOMER).permissions(Collections.emptySet()).build()));

        adminUser = userRepository.findByEmailIgnoreCase("admin_stn@ecomargin.com").orElseGet(() ->
                userRepository.save(User.builder()
                        .email("admin_stn@ecomargin.com")
                        .password("password123")
                        .firstName("Admin")
                        .lastName("User")
                        .roles(Collections.singleton(adminRole))
                        .isVerified(true)
                        .isAccountNonLocked(true)
                        .build())
        );

        customerUser = userRepository.findByEmailIgnoreCase("cust_stn@ecomargin.com").orElseGet(() ->
                userRepository.save(User.builder()
                        .email("cust_stn@ecomargin.com")
                        .password("password123")
                        .firstName("Customer")
                        .lastName("User")
                        .phoneNumber("9988776655")
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
                .name("Jaipur Central Station")
                .address("MI Road, Jaipur")
                .city("Jaipur")
                .state("Rajasthan")
                .country("India")
                .latitude(new BigDecimal("26.9124"))
                .longitude(new BigDecimal("75.7873"))
                .status("ACTIVE")
                .build();
        stationRepository.save(station);

        charger = Charger.builder()
                .station(station)
                .ocppId("JPR-CP-01")
                .brand("ABB")
                .model("Terra 184")
                .status("AVAILABLE")
                .build();
        chargerRepository.save(charger);

        connector = Connector.builder()
                .charger(charger)
                .connectorIndex(1)
                .type("CCS2")
                .maxPowerKw(new BigDecimal("60.0"))
                .status("AVAILABLE")
                .build();
        connectorRepository.save(connector);
    }

    // A. Admin can list stations.
    @Test
    @WithMockUser(username = "admin_stn@ecomargin.com", roles = {"ADMIN"})
    void testA_AdminCanListStations() throws Exception {
        mockMvc.perform(get("/api/v1/admin/stations/detailed"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(greaterThanOrEqualTo(1))))
                .andExpect(jsonPath("$[0].name").value("Jaipur Central Station"))
                .andExpect(jsonPath("$[0].city").value("Jaipur"));
    }

    // B. Customer cannot access station management.
    // N. Unauthorized modification returns 403.
    @Test
    @WithMockUser(username = "cust_stn@ecomargin.com", roles = {"CUSTOMER"})
    void testB_CustomerCannotAccessStationManagement() throws Exception {
        mockMvc.perform(get("/api/v1/admin/stations/detailed"))
                .andExpect(status().isForbidden());

        StationRequest req = new StationRequest();
        req.setName("Unauthorized Station");
        req.setLatitude(new BigDecimal("20.0"));
        req.setLongitude(new BigDecimal("70.0"));
        req.setStatus("ACTIVE");

        mockMvc.perform(post("/api/v1/admin/stations")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isForbidden());
    }

    // C. Admin can create station.
    @Test
    @WithMockUser(username = "admin_stn@ecomargin.com", roles = {"ADMIN"})
    void testC_AdminCanCreateStation() throws Exception {
        StationRequest req = new StationRequest();
        req.setName("Delhi South Hub");
        req.setAddress("Saket District Centre");
        req.setCity("New Delhi");
        req.setState("Delhi");
        req.setCountry("India");
        req.setLatitude(new BigDecimal("28.5244"));
        req.setLongitude(new BigDecimal("77.2188"));
        req.setStatus("ACTIVE");

        mockMvc.perform(post("/api/v1/admin/stations")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Delhi South Hub"))
                .andExpect(jsonPath("$.city").value("New Delhi"))
                .andExpect(jsonPath("$.status").value("ACTIVE"));
    }

    // D. Invalid latitude rejected.
    @Test
    @WithMockUser(username = "admin_stn@ecomargin.com", roles = {"ADMIN"})
    void testD_InvalidLatitudeRejected() throws Exception {
        StationRequest req = new StationRequest();
        req.setName("Invalid Lat Station");
        req.setLatitude(new BigDecimal("95.0000")); // > 90
        req.setLongitude(new BigDecimal("75.0000"));
        req.setStatus("ACTIVE");

        mockMvc.perform(post("/api/v1/admin/stations")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest());
    }

    // E. Invalid longitude rejected.
    @Test
    @WithMockUser(username = "admin_stn@ecomargin.com", roles = {"ADMIN"})
    void testE_InvalidLongitudeRejected() throws Exception {
        StationRequest req = new StationRequest();
        req.setName("Invalid Lon Station");
        req.setLatitude(new BigDecimal("25.0000"));
        req.setLongitude(new BigDecimal("-195.0000")); // < -180
        req.setStatus("ACTIVE");

        mockMvc.perform(post("/api/v1/admin/stations")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest());
    }

    // F. Required station fields validated.
    @Test
    @WithMockUser(username = "admin_stn@ecomargin.com", roles = {"ADMIN"})
    void testF_RequiredFieldsValidated() throws Exception {
        StationRequest req = new StationRequest();
        req.setName(""); // Blank
        req.setLatitude(new BigDecimal("25.0000"));
        req.setLongitude(new BigDecimal("75.0000"));
        req.setStatus("ACTIVE");

        mockMvc.perform(post("/api/v1/admin/stations")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest());
    }

    // G. Admin can update station.
    @Test
    @WithMockUser(username = "admin_stn@ecomargin.com", roles = {"ADMIN"})
    void testG_AdminCanUpdateStation() throws Exception {
        StationRequest req = new StationRequest();
        req.setName("Jaipur Grand Station");
        req.setAddress("Updated MI Road Address");
        req.setCity("Jaipur City");
        req.setState("Rajasthan");
        req.setCountry("India");
        req.setLatitude(new BigDecimal("26.9200"));
        req.setLongitude(new BigDecimal("75.7900"));
        req.setStatus("ACTIVE");

        mockMvc.perform(put("/api/v1/admin/stations/" + station.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Jaipur Grand Station"))
                .andExpect(jsonPath("$.address").value("Updated MI Road Address"));
    }

    // H. Admin can disable station.
    @Test
    @WithMockUser(username = "admin_stn@ecomargin.com", roles = {"ADMIN"})
    void testH_AdminCanDisableStation() throws Exception {
        mockMvc.perform(put("/api/v1/admin/stations/" + station.getId() + "/disable"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("INACTIVE"));

        Station reloaded = stationRepository.findById(station.getId()).orElseThrow();
        assertEquals("INACTIVE", reloaded.getStatus());
    }

    // I. Disabled station cannot accept new charging sessions.
    @Test
    @WithMockUser(username = "admin_stn@ecomargin.com", roles = {"ADMIN"})
    void testI_DisabledStationCannotStartNewSession() throws Exception {
        // Disable station
        station.setStatus("INACTIVE");
        stationRepository.save(station);

        String payload = String.format("{\"stationId\":%d, \"chargerId\":%d, \"connectorId\":%d}",
                station.getId(), charger.getId(), connector.getId());

        mockMvc.perform(post("/api/v1/charging-sessions/start")
                        .with(user("cust_stn@ecomargin.com").roles("CUSTOMER"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("STATION_UNAVAILABLE"));
    }

    // J. Existing active session is not unexpectedly terminated.
    @Test
    @WithMockUser(username = "admin_stn@ecomargin.com", roles = {"ADMIN"})
    void testJ_DisablingStationDoesNotDestroyActiveSession() throws Exception {
        ChargingSession active = ChargingSession.builder()
                .user(customerUser)
                .connector(connector)
                .status("CHARGING")
                .startTime(LocalDateTime.now().minusMinutes(10))
                .totalEnergyKwh(new BigDecimal("5.0"))
                .totalCost(new BigDecimal("90.0"))
                .build();
        chargingSessionRepository.save(active);

        // Admin disables station
        mockMvc.perform(put("/api/v1/admin/stations/" + station.getId() + "/disable"))
                .andExpect(status().isOk());

        ChargingSession reloaded = chargingSessionRepository.findById(active.getId()).orElseThrow();
        assertEquals("CHARGING", reloaded.getStatus());
    }

    // K. Station charger/connector counts are correct.
    // L. Station details return correct charger relationships.
    @Test
    @WithMockUser(username = "admin_stn@ecomargin.com", roles = {"ADMIN"})
    void testKL_StationDetailsAndHierarchyCounts() throws Exception {
        mockMvc.perform(get("/api/v1/admin/stations/" + station.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(station.getId()))
                .andExpect(jsonPath("$.totalChargers").value(1))
                .andExpect(jsonPath("$.totalConnectors").value(1))
                .andExpect(jsonPath("$.availableConnectors").value(1))
                .andExpect(jsonPath("$.chargers[0].ocppId").value("JPR-CP-01"))
                .andExpect(jsonPath("$.chargers[0].connectors[0].type").value("CCS2"));
    }

    // O. Non-existent station returns 404.
    @Test
    @WithMockUser(username = "admin_stn@ecomargin.com", roles = {"ADMIN"})
    void testO_NonExistentStationReturns404() throws Exception {
        mockMvc.perform(get("/api/v1/admin/stations/999999"))
                .andExpect(status().isNotFound());
    }
}
