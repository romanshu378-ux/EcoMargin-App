package com.ecomargin.controller.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.math.BigDecimal;
import java.util.List;

@Data
public class StationRequest {

    @NotBlank(message = "Station name is required")
    private String name;

    @NotNull(message = "Latitude is required")
    @DecimalMin(value = "-90.0", message = "Latitude must be between -90 and 90")
    @DecimalMax(value = "90.0", message = "Latitude must be between -90 and 90")
    private BigDecimal latitude;

    @NotNull(message = "Longitude is required")
    @DecimalMin(value = "-180.0", message = "Longitude must be between -180 and 180")
    @DecimalMax(value = "180.0", message = "Longitude must be between -180 and 180")
    private BigDecimal longitude;

    private String address;

    private String city;

    private String state;

    private String country;

    @NotBlank(message = "Station status is required")
    private String status;

    private List<ChargerConfigRequest> chargers;

    @Data
    public static class ChargerConfigRequest {
        private Long id;
        private String ocppId;
        private String brand;
        private String model;
        private String status;
        private List<ConnectorConfigRequest> connectors;
    }

    @Data
    public static class ConnectorConfigRequest {
        private Long id;
        private Integer connectorIndex;
        private String type;
        private BigDecimal maxPowerKw;
        private BigDecimal unitRate;
        private String status;
    }
}
