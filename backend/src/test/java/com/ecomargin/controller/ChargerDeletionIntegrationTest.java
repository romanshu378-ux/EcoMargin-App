package com.ecomargin.controller;

import com.ecomargin.config.DatabaseSeeder;
import com.ecomargin.model.Charger;
import com.ecomargin.model.Connector;
import com.ecomargin.model.Station;
import com.ecomargin.repository.ChargerRepository;
import com.ecomargin.repository.ConnectorRepository;
import com.ecomargin.repository.StationRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
public class ChargerDeletionIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private StationRepository stationRepository;

    @Autowired
    private ChargerRepository chargerRepository;

    @Autowired
    private ConnectorRepository connectorRepository;

    @Autowired
    private DatabaseSeeder databaseSeeder;

    private Station jaipurStation;
    private Charger jaipurCharger;
    private Connector jaipurConn;

    @BeforeEach
    void setUp() {
        jaipurStation = stationRepository.save(Station.builder()
                .name("Jaipur EV Deletion Test Station")
                .latitude(new BigDecimal("26.9150"))
                .longitude(new BigDecimal("75.7920"))
                .address("Tonk Road, Jaipur")
                .city("Jaipur")
                .state("Rajasthan")
                .country("India")
                .status("ACTIVE")
                .build());

        jaipurCharger = chargerRepository.save(Charger.builder()
                .station(jaipurStation)
                .ocppId("IN_JAI_DEL_TEST")
                .brand("ABB")
                .model("Terra 184")
                .status("AVAILABLE")
                .updatedAt(LocalDateTime.now())
                .build());

        jaipurConn = connectorRepository.save(Connector.builder()
                .charger(jaipurCharger)
                .connectorIndex(1)
                .type("CCS2")
                .maxPowerKw(new BigDecimal("180.00"))
                .unitRate(new BigDecimal("18.00"))
                .status("AVAILABLE")
                .updatedAt(LocalDateTime.now())
                .build());
    }

    @Test
    @WithMockUser(username = "admin@ecomargin.com", roles = {"ADMIN"})
    void testChargerDeletionFlow_EndToEnd() throws Exception {
        // 1. Verify charger is returned before deletion
        mockMvc.perform(get("/api/v1/stations/" + jaipurStation.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.chargers[0].ocppId").value("IN_JAI_DEL_TEST"));

        // 2. Admin deletes charger
        mockMvc.perform(delete("/api/v1/admin/chargers/" + jaipurCharger.getId()))
                .andExpect(status().isOk());

        // 3. Direct DB verification
        Charger deletedCharger = chargerRepository.findById(jaipurCharger.getId()).orElseThrow();
        assertNotNull(deletedCharger.getDeletedAt(), "Charger deletedAt must not be null");
        assertEquals("DELETED", deletedCharger.getStatus());

        Connector deletedConn = connectorRepository.findById(jaipurConn.getId()).orElseThrow();
        assertNotNull(deletedConn.getDeletedAt(), "Connector deletedAt must not be null");
        assertEquals("DELETED", deletedConn.getStatus());

        // 4. Verify Customer API no longer returns charger
        mockMvc.perform(get("/api/v1/stations/" + jaipurStation.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.chargers").isEmpty());

        // 5. Verify deleted charger is not in /stations/nearby chargers
        mockMvc.perform(get("/api/v1/stations/nearby?latitude=26.9150&longitude=75.7920"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.id == " + jaipurStation.getId() + ")].chargers[*]").doesNotExist());
    }
}
