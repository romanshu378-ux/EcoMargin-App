package com.ecomargin.controller;

import com.ecomargin.model.Station;
import com.ecomargin.repository.ChargerRepository;
import com.ecomargin.repository.ChargingSessionRepository;
import com.ecomargin.repository.ConnectorRepository;
import com.ecomargin.repository.StationRepository;
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

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class StationControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private StationRepository stationRepository;

    @Autowired
    private ChargerRepository chargerRepository;

    @Autowired
    private ConnectorRepository connectorRepository;

    @Autowired
    private ChargingSessionRepository chargingSessionRepository;

    @BeforeEach
    void setUp() {
        chargingSessionRepository.deleteAll();
        connectorRepository.deleteAll();
        chargerRepository.deleteAll();
        stationRepository.deleteAll();

        Station s1 = Station.builder()
                .name("Austin Downtown Hub")
                .latitude(new BigDecimal("30.267153"))
                .longitude(new BigDecimal("-97.743062"))
                .address("120 E 6th St")
                .status("ACTIVE")
                .build();

        Station s2 = Station.builder()
                .name("North Loop Charger Point")
                .latitude(new BigDecimal("30.318858"))
                .longitude(new BigDecimal("-97.723789"))
                .address("5310 Airport Blvd")
                .status("ACTIVE")
                .build();

        stationRepository.save(s1);
        stationRepository.save(s2);
    }

    @Test
    @WithMockUser(username = "admin@ecomargin.com", roles = {"ADMIN"})
    void testGetStationsWithPagingAndFiltering() throws Exception {
        mockMvc.perform(get("/api/v1/stations")
                        .param("status", "ACTIVE")
                        .param("search", "Downtown")
                        .param("page", "0")
                        .param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(1)))
                .andExpect(jsonPath("$.content[0].name").value("Austin Downtown Hub"));
    }

    @Test
    @WithMockUser(username = "admin@ecomargin.com", roles = {"ADMIN"})
    void testCreateStationWithValidationErrors() throws Exception {
        String invalidPayload = """
                {
                    "name": "",
                    "latitude": 120.0,
                    "longitude": -97.743,
                    "status": "ACTIVE"
                }
                """; // Blank name and lat out of range -90 -> 90

        mockMvc.perform(post("/api/v1/stations")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(invalidPayload))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.details.name").exists())
                .andExpect(jsonPath("$.details.latitude").exists());
    }

    @Test
    @WithMockUser(username = "customer@ecomargin.com", roles = {"CUSTOMER"})
    void testGetNearbyStations_WithCoordinatesAndDistanceCalculation() throws Exception {
        mockMvc.perform(get("/api/v1/stations/nearby")
                        .param("latitude", "30.267153")
                        .param("longitude", "-97.743062")
                        .param("radiusKm", "10.0"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[0].name").value("Austin Downtown Hub"))
                .andExpect(jsonPath("$[0].distanceStr").exists());
    }
}
