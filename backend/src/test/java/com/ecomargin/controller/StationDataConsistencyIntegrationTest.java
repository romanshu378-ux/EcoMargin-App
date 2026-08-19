package com.ecomargin.controller;

import com.ecomargin.model.Charger;
import com.ecomargin.model.Connector;
import com.ecomargin.model.Station;
import com.ecomargin.repository.ChargerRepository;
import com.ecomargin.repository.ConnectorRepository;
import com.ecomargin.repository.StationRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
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
import java.util.List;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
public class StationDataConsistencyIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private StationRepository stationRepository;

    @Autowired
    private ChargerRepository chargerRepository;

    @Autowired
    private ConnectorRepository connectorRepository;

    @Autowired
    private jakarta.persistence.EntityManager entityManager;

    private Station testStation;

    @BeforeEach
    void setUp() {
        Station station = Station.builder()
                .name("E2E Audit Charging Hub")
                .address("Tonk Road, Jaipur")
                .city("Jaipur")
                .state("Rajasthan")
                .country("India")
                .latitude(BigDecimal.valueOf(26.9150))
                .longitude(BigDecimal.valueOf(75.7920))
                .status("ACTIVE")
                .build();
        testStation = stationRepository.save(station);

        Charger charger = Charger.builder()
                .station(testStation)
                .ocppId("E2E-CHG-99")
                .brand("EcoMargin")
                .model("Fast-119")
                .status("AVAILABLE")
                .build();
        Charger savedCharger = chargerRepository.save(charger);

        Connector conn1 = Connector.builder()
                .charger(savedCharger)
                .connectorIndex(1)
                .type("CCS2")
                .status("AVAILABLE")
                .maxPowerKw(BigDecimal.valueOf(119.00))
                .unitRate(BigDecimal.valueOf(22.00))
                .build();

        Connector conn2 = Connector.builder()
                .charger(savedCharger)
                .connectorIndex(2)
                .type("CCS2")
                .status("AVAILABLE")
                .maxPowerKw(BigDecimal.valueOf(119.00))
                .unitRate(BigDecimal.valueOf(22.00))
                .build();

        connectorRepository.saveAll(List.of(conn1, conn2));
        entityManager.flush();
        entityManager.clear();
    }

    @Test
    @WithMockUser(username = "admin@ecomargin.com", roles = {"ADMIN"})
    @DisplayName("Verify Database == Admin API == Customer API consistency across station, charger, connector & pricing")
    void testEndToEndDataConsistency() throws Exception {
        // 1. Verify Admin Detailed Station API matches DB
        mockMvc.perform(get("/api/v1/admin/stations/detailed")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.id == " + testStation.getId() + ")].name", contains("E2E Audit Charging Hub")))
                .andExpect(jsonPath("$[?(@.id == " + testStation.getId() + ")].chargers[0].ocppId", contains("E2E-CHG-99")))
                .andExpect(jsonPath("$[?(@.id == " + testStation.getId() + ")].chargers[0].connectors[0].unitRate", contains(22.0)))
                .andExpect(jsonPath("$[?(@.id == " + testStation.getId() + ")].chargers[0].connectors[0].maxPowerKw", contains(119.0)));

        // 2. Verify Customer Nearby Station API matches DB
        mockMvc.perform(get("/api/v1/stations/nearby")
                        .param("latitude", "26.9150")
                        .param("longitude", "75.7920")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.id == " + testStation.getId() + ")].name", contains("E2E Audit Charging Hub")))
                .andExpect(jsonPath("$[?(@.id == " + testStation.getId() + ")].priceStr", contains("₹22 / kWh")))
                .andExpect(jsonPath("$[?(@.id == " + testStation.getId() + ")].chargers[0].connectors[0].unitRate", contains(22.0)))
                .andExpect(jsonPath("$[?(@.id == " + testStation.getId() + ")].chargers[0].connectors[0].maxPowerKw", contains(119.0)));

        // 3. Update Station Pricing via Admin API to ₹25.00/kWh
        List<Charger> initialChargers = chargerRepository.findByStation(testStation);
        org.junit.jupiter.api.Assertions.assertFalse(initialChargers.isEmpty());
        Charger c0 = initialChargers.get(0);
        List<Connector> initialConnectors = connectorRepository.findByCharger(c0);

        String updatePayload = """
                {
                  "name": "E2E Audit Charging Hub",
                  "address": "Tonk Road, Jaipur",
                  "city": "Jaipur",
                  "state": "Rajasthan",
                  "country": "India",
                  "latitude": 26.9150,
                  "longitude": 75.7920,
                  "status": "ACTIVE",
                  "chargers": [
                    {
                      "id": %d,
                      "ocppId": "E2E-CHG-99",
                      "brand": "EcoMargin",
                      "model": "Fast-119",
                      "status": "AVAILABLE",
                      "connectors": [
                        {
                          "id": %d,
                          "type": "CCS2",
                          "status": "AVAILABLE",
                          "maxPowerKw": 119.00,
                          "unitRate": 25.00
                        },
                        {
                          "id": %d,
                          "type": "CCS2",
                          "status": "AVAILABLE",
                          "maxPowerKw": 119.00,
                          "unitRate": 25.00
                        }
                      ]
                    }
                  ]
                }
                """.formatted(c0.getId(), initialConnectors.get(0).getId(), initialConnectors.get(1).getId());

        mockMvc.perform(put("/api/v1/admin/stations/" + testStation.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(updatePayload))
                .andExpect(status().isOk());

        // 4. Verify DB updated
        entityManager.flush();
        entityManager.clear();
        Station updatedStation = stationRepository.findById(testStation.getId()).orElseThrow();
        List<Charger> chargers = chargerRepository.findByStation(updatedStation);
        org.junit.jupiter.api.Assertions.assertFalse(chargers.isEmpty());
        List<Connector> connectors = connectorRepository.findByCharger(chargers.get(0));
        BigDecimal newRate = connectors.get(0).getUnitRate();
        org.junit.jupiter.api.Assertions.assertEquals(0, BigDecimal.valueOf(25.00).compareTo(newRate));

        // 5. Verify Customer API immediately reflects updated rate (₹25/kWh)
        mockMvc.perform(get("/api/v1/stations/nearby")
                        .param("latitude", "26.9150")
                        .param("longitude", "75.7920")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.id == " + testStation.getId() + ")].priceStr", contains("₹25 / kWh")))
                .andExpect(jsonPath("$[?(@.id == " + testStation.getId() + ")].chargers[0].connectors[0].unitRate", contains(25.0)));

        System.out.println("==================================================");
        System.out.println("E2E DATA CONSISTENCY TEST: PASSED");
        System.out.println("DATABASE == ADMIN API == CUSTOMER API (Rate = ₹25/kWh, Power = 119 kW)");
        System.out.println("==================================================");
    }
}
