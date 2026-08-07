package com.ecomargin.controller;

import com.ecomargin.controller.dto.StationRequest;
import com.ecomargin.model.Station;
import com.ecomargin.repository.StationRepository;
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

@RestController
@RequestMapping("/api/v1/stations")
@RequiredArgsConstructor
@Tag(name = "Stations API", description = "Endpoints for CPO Charging Station configurations, pagination, and map queries")
public class StationController {

    private final StationRepository stationRepository;

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
        return ResponseEntity.ok(stations);
    }

    @Operation(summary = "Get a single station details by ID")
    @ApiResponse(responseCode = "200", description = "Station found")
    @ApiResponse(responseCode = "404", description = "Station not found")
    @GetMapping("/{id}")
    public ResponseEntity<Station> getStationById(@PathVariable Long id) {
        return stationRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
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
                .status(request.getStatus().toUpperCase())
                .build();

        Station savedStation = stationRepository.save(station);
        return ResponseEntity.ok(savedStation);
    }
}
