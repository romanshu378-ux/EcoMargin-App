package com.ecomargin.controller;

import com.ecomargin.model.Charger;
import com.ecomargin.model.Connector;
import com.ecomargin.model.Station;
import com.ecomargin.model.User;
import com.ecomargin.ocpp.handler.StatusNotificationHandler;
import com.ecomargin.ocpp.protocol.OcppAction;
import com.ecomargin.ocpp.protocol.OcppMessage;
import com.ecomargin.repository.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
public class ChargerStatusIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private StationRepository stationRepository;

    @Autowired
    private ChargerRepository chargerRepository;

    @Autowired
    private ConnectorRepository connectorRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private WalletRepository walletRepository;

    @Autowired
    private StatusNotificationHandler statusNotificationHandler;

    @Autowired
    private ObjectMapper objectMapper;

    private User testUser;
    private Station testStation;
    private Charger txAusNl01;
    private Connector conn1;

    @BeforeEach
    void setUp() {
        testUser = userRepository.save(User.builder()
                .email("testcustomer_chg@example.com")
                .firstName("Test")
                .lastName("Customer")
                .password("Password123!")
                .isVerified(true)
                .build());

        walletRepository.save(com.ecomargin.model.Wallet.builder()
                .user(testUser)
                .balance(new BigDecimal("500.00"))
                .currency("INR")
                .updatedAt(LocalDateTime.now())
                .build());

        testStation = stationRepository.save(Station.builder()
                .name("Austin North Hub")
                .latitude(new BigDecimal("30.2672"))
                .longitude(new BigDecimal("-97.7431"))
                .address("100 N Lamar Blvd, Austin, TX")
                .city("Austin")
                .state("Texas")
                .country("USA")
                .status("ACTIVE")
                .build());

        txAusNl01 = chargerRepository.save(Charger.builder()
                .station(testStation)
                .ocppId("TX_AUS_NL_01")
                .brand("ABB")
                .model("Terra 184")
                .status("AVAILABLE")
                .updatedAt(LocalDateTime.now())
                .build());

        conn1 = connectorRepository.save(Connector.builder()
                .charger(txAusNl01)
                .connectorIndex(1)
                .type("CCS2")
                .maxPowerKw(new BigDecimal("180.00"))
                .unitRate(new BigDecimal("18.00"))
                .status("AVAILABLE")
                .updatedAt(LocalDateTime.now())
                .build());
    }

    @Test
    @WithMockUser(username = "testcustomer_chg@example.com", roles = {"CUSTOMER"})
    void testStartCharging_Success_WhenChargerAndConnectorAvailable() throws Exception {
        mockMvc.perform(post("/api/v1/charging/start")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"stationId\":" + testStation.getId() + ",\"connectorId\":" + conn1.getId() + "}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("CHARGING"));
    }

    @Test
    @WithMockUser(username = "testcustomer_chg@example.com", roles = {"CUSTOMER"})
    void testStartCharging_Returns409Conflict_WhenChargerIsUnavailable() throws Exception {
        txAusNl01.setStatus("UNAVAILABLE");
        chargerRepository.save(txAusNl01);

        mockMvc.perform(post("/api/v1/charging/start")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"stationId\":" + testStation.getId() + ",\"connectorId\":" + conn1.getId() + "}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("CHARGER_UNAVAILABLE"));
    }

    @Test
    @WithMockUser(username = "admin@ecomargin.com", roles = {"ADMIN"})
    void testAdminEditConnector_PreservesChargerStatus() throws Exception {
        String updatePayload = "{"
                + "\"name\":\"Austin North Hub Updated\","
                + "\"address\":\"100 N Lamar Blvd\","
                + "\"city\":\"Austin\","
                + "\"state\":\"Texas\","
                + "\"country\":\"USA\","
                + "\"latitude\":30.2672,"
                + "\"longitude\":-97.7431,"
                + "\"status\":\"ACTIVE\","
                + "\"chargers\":[{"
                + "  \"id\":" + txAusNl01.getId() + ","
                + "  \"ocppId\":\"TX_AUS_NL_01\","
                + "  \"brand\":\"ABB\","
                + "  \"model\":\"Terra 184\","
                + "  \"connectors\":[{"
                + "    \"id\":" + conn1.getId() + ","
                + "    \"type\":\"CCS2\","
                + "    \"maxPowerKw\":200.00,"
                + "    \"unitRate\":22.00"
                + "  }]"
                + "}]"
                + "}";

        mockMvc.perform(put("/api/v1/admin/stations/" + testStation.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(updatePayload))
                .andExpect(status().isOk());

        Charger updatedCharger = chargerRepository.findById(txAusNl01.getId()).orElseThrow();
        assertEquals("AVAILABLE", updatedCharger.getStatus());

        Connector updatedConn = connectorRepository.findById(conn1.getId()).orElseThrow();
        assertEquals(new BigDecimal("200.00"), updatedConn.getMaxPowerKw());
        assertEquals("AVAILABLE", updatedConn.getStatus());
    }

    @Test
    void testOcppStatusNotification_UpdatesChargerAndConnectorStatus() {
        ObjectNode payload = objectMapper.createObjectNode();
        payload.put("connectorId", 1);
        payload.put("status", "Charging");

        OcppMessage message = OcppMessage.builder()
                .messageTypeId(2)
                .uniqueId("MSG-001")
                .action(OcppAction.StatusNotification.name())
                .payload(payload)
                .build();

        statusNotificationHandler.handle("TX_AUS_NL_01", message);

        Charger updatedCharger = chargerRepository.findById(txAusNl01.getId()).orElseThrow();
        Connector updatedConn = connectorRepository.findById(conn1.getId()).orElseThrow();

        assertEquals("CHARGING", updatedConn.getStatus());
        assertEquals("CHARGING", updatedCharger.getStatus());
    }
}
