package com.ecomargin.controller;

import com.ecomargin.controller.dto.StationRequest;
import com.ecomargin.model.Station;
import com.ecomargin.repository.StationRepository;
import com.ecomargin.repository.ChargerRepository;
import com.ecomargin.repository.ConnectorRepository;
import com.ecomargin.repository.StationSpecification;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/stations")
@RequiredArgsConstructor
@Tag(name = "Stations API", description = "Endpoints for CPO Charging Station configurations, pagination, and map queries")
public class StationController {

    private final StationRepository stationRepository;
    private final ChargerRepository chargerRepository;
    private final ConnectorRepository connectorRepository;

    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    @Operation(summary = "Search stations with pagination and filtering", description = "Allows multi-criteria filters including vendor ID, name search, and operational status")
    @ApiResponse(responseCode = "200", description = "Successfully retrieved list of stations")
    @GetMapping
    public ResponseEntity<Page<Station>> getStations(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) Long vendorId,
            @RequestParam(required = false) String search,
            Pageable pageable
    ) {
        Specification<Station> spec = Specification.where(StationSpecification.hasStatus(status))
                .and(StationSpecification.hasVendorId(vendorId))
                .and(StationSpecification.hasNameLike(search));

        Page<Station> stations = stationRepository.findAll(spec, pageable);
        stations.getContent().forEach(this::filterCustomerVisibleHardware);
        return ResponseEntity.ok(stations);
    }

    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    @Operation(summary = "Get nearby stations")
    @ApiResponse(responseCode = "200", description = "Successfully retrieved list of nearby stations")
    @GetMapping("/nearby")
    public ResponseEntity<List<Station>> getNearbyStations(
            @RequestParam(required = false) Double latitude,
            @RequestParam(required = false) Double longitude,
            @RequestParam(required = false, defaultValue = "50.0") Double radiusKm
    ) {
        List<Station> stations = stationRepository.findAll().stream()
                .filter(s -> s.getDeletedAt() == null && !"INACTIVE".equalsIgnoreCase(s.getStatus()) && !"DELETED".equalsIgnoreCase(s.getStatus()))
                .peek(this::filterCustomerVisibleHardware)
                .collect(java.util.stream.Collectors.toList());

        stations.forEach(station -> {
            if (latitude != null && longitude != null && station.getLatitude() != null && station.getLongitude() != null) {
                double dist = calculateHaversineDistance(
                        latitude, longitude,
                        station.getLatitude().doubleValue(), station.getLongitude().doubleValue()
                );
                station.setDistanceKm(dist);
                station.setDistanceStr(String.format(java.util.Locale.US, "%.1f km Away", dist));
            } else {
                station.setDistanceKm(null);
                station.setDistanceStr(null);
            }
        });

        if (latitude != null && longitude != null) {
            double r = (radiusKm != null && radiusKm > 0) ? radiusKm : 50.0;
            stations = stations.stream()
                    .filter(s -> s.getDistanceKm() != null && s.getDistanceKm() <= r)
                    .sorted(java.util.Comparator.comparing(Station::getDistanceKm))
                    .collect(java.util.stream.Collectors.toList());
        }

        return ResponseEntity.ok(stations);
    }

    private double calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
        final int R = 6371; // Earth radius in km
        double latDistance = Math.toRadians(lat2 - lat1);
        double lonDistance = Math.toRadians(lon2 - lon1);
        double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }

    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    @Operation(summary = "Get a single station details by ID")
    @ApiResponse(responseCode = "200", description = "Station found")
    @ApiResponse(responseCode = "404", description = "Station not found")
    @GetMapping("/{id:\\d+}")
    public ResponseEntity<Station> getStationById(@PathVariable Long id) {
        return stationRepository.findById(id)
                .filter(s -> s.getDeletedAt() == null && !"INACTIVE".equalsIgnoreCase(s.getStatus()) && !"DELETED".equalsIgnoreCase(s.getStatus()))
                .map(station -> {
                    filterCustomerVisibleHardware(station);
                    return ResponseEntity.ok(station);
                })
                .orElse(ResponseEntity.notFound().build());
    }

    private void filterCustomerVisibleHardware(Station station) {
        if (station == null) return;
        List<com.ecomargin.model.Charger> chargers = station.getChargers();
        if (chargers == null) {
            chargers = chargerRepository.findByStation(station);
        }
        if (chargers == null) return;

        List<com.ecomargin.model.Charger> visibleChargers = chargers.stream()
                .filter(this::isChargerCustomerVisible)
                .peek(charger -> {
                    List<com.ecomargin.model.Connector> connectors = charger.getConnectors();
                    if (connectors == null) {
                        connectors = connectorRepository.findByCharger(charger);
                    }
                    if (connectors != null) {
                        List<com.ecomargin.model.Connector> visibleConnectors = connectors.stream()
                                .filter(this::isConnectorCustomerVisible)
                                .collect(java.util.stream.Collectors.toList());
                        charger.setConnectors(visibleConnectors);
                    }
                })
                .collect(java.util.stream.Collectors.toList());
        station.setChargers(visibleChargers);
    }

    private boolean isChargerCustomerVisible(com.ecomargin.model.Charger charger) {
        if (charger == null || charger.getDeletedAt() != null) return false;
        String st = charger.getStatus() != null ? charger.getStatus().toUpperCase() : "";
        return !java.util.Set.of("DELETED", "DISABLED", "INACTIVE").contains(st);
    }

    private boolean isConnectorCustomerVisible(com.ecomargin.model.Connector connector) {
        if (connector == null || connector.getDeletedAt() != null) return false;
        String st = connector.getStatus() != null ? connector.getStatus().toUpperCase() : "";
        return !java.util.Set.of("DELETED", "DISABLED", "INACTIVE").contains(st);
    }

    @Operation(summary = "Create a new CPO Station")
    @ApiResponse(responseCode = "200", description = "Station created successfully")
    @ApiResponse(responseCode = "400", description = "Invalid request payload parameters")
    @PostMapping
    public ResponseEntity<Station> createStation(@Valid @RequestBody StationRequest request) {
        // Map DTO to entity and save
        Station station = Station.builder()
                .name(request.getName())
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .address(request.getAddress())
                .city(request.getCity() != null ? request.getCity() : "Jaipur")
                .state(request.getState() != null ? request.getState() : "Rajasthan")
                .country(request.getCountry() != null ? request.getCountry() : "India")
                .status(request.getStatus().toUpperCase())
                .build();

        Station savedStation = stationRepository.save(station);
        return ResponseEntity.ok(savedStation);
    }
}
