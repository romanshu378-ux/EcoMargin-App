package com.ecomargin.controller.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class ChargerRequest {

    @NotNull(message = "Station ID is required")
    private Long stationId;

    @NotBlank(message = "OCPP ID is required")
    private String ocppId;

    private String model;
    private String brand;

    @NotBlank(message = "Status is required")
    private String status;
}
