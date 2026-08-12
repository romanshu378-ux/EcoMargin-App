package com.ecomargin.controller;

import com.ecomargin.model.User;
import com.ecomargin.model.Vehicle;
import com.ecomargin.repository.UserRepository;
import com.ecomargin.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@RestController
@RequestMapping("/api/v1/vehicles")
@RequiredArgsConstructor
public class VehicleController {

    private final VehicleRepository vehicleRepository;
    private final UserRepository userRepository;

    private User getAuthenticatedUser() {
        Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        if (principal instanceof User) {
            return (User) principal;
        }
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return userRepository.findByEmailIgnoreCase(email)
                .orElseThrow(() -> new RuntimeException("User not authenticated"));
    }

    @GetMapping
    public ResponseEntity<?> getVehicles() {
        User user = getAuthenticatedUser();
        List<Vehicle> list = vehicleRepository.findByUser(user);
        return ResponseEntity.ok(list.stream().map(this::mapVehicleToMap).collect(Collectors.toList()));
    }

    @PostMapping
    public ResponseEntity<?> addVehicle(@RequestBody Map<String, Object> body) {
        User user = getAuthenticatedUser();

        String regNo = (String) body.get("registrationNumber");
        String brand = (String) body.get("brand");
        String model = (String) body.get("model");

        if (regNo == null || regNo.trim().isEmpty() ||
            brand == null || brand.trim().isEmpty() ||
            model == null || model.trim().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Registration number, brand, and model are required."));
        }

        BigDecimal batteryCap = BigDecimal.ZERO;
        if (body.containsKey("batteryCapacityKwh") && body.get("batteryCapacityKwh") != null) {
            try {
                batteryCap = new BigDecimal(body.get("batteryCapacityKwh").toString());
            } catch (Exception e) {
                // ignore
            }
        }

        boolean isDefault = body.containsKey("isDefault") && Boolean.parseBoolean(body.get("isDefault").toString());

        Vehicle vehicle = Vehicle.builder()
                .user(user)
                .registrationNumber(regNo.trim())
                .brand(brand.trim())
                .model(model.trim())
                .variant((String) body.get("variant"))
                .type((String) body.get("type"))
                .batteryCapacityKwh(batteryCap)
                .connectorType((String) body.get("connectorType"))
                .nickname((String) body.get("nickname"))
                .isDefault(isDefault)
                .build();

        List<Vehicle> existing = vehicleRepository.findByUser(user);
        if (existing.isEmpty() || vehicle.isDefault()) {
            vehicle.setDefault(true);
            for (Vehicle v : existing) {
                if (v.isDefault()) {
                    v.setDefault(false);
                    vehicleRepository.save(v);
                }
            }
        }

        Vehicle saved = vehicleRepository.save(vehicle);
        return ResponseEntity.status(HttpStatus.CREATED).body(mapVehicleToMap(saved));
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateVehicle(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        User user = getAuthenticatedUser();
        Vehicle vehicle = vehicleRepository.findByIdAndUser(id, user)
                .orElseThrow(() -> new RuntimeException("Vehicle not found or access denied"));

        if (body.containsKey("registrationNumber")) vehicle.setRegistrationNumber((String) body.get("registrationNumber"));
        if (body.containsKey("brand")) vehicle.setBrand((String) body.get("brand"));
        if (body.containsKey("model")) vehicle.setModel((String) body.get("model"));
        if (body.containsKey("variant")) vehicle.setVariant((String) body.get("variant"));
        if (body.containsKey("type")) vehicle.setType((String) body.get("type"));
        if (body.containsKey("connectorType")) vehicle.setConnectorType((String) body.get("connectorType"));
        if (body.containsKey("nickname")) vehicle.setNickname((String) body.get("nickname"));

        if (body.containsKey("batteryCapacityKwh") && body.get("batteryCapacityKwh") != null) {
            try {
                vehicle.setBatteryCapacityKwh(new BigDecimal(body.get("batteryCapacityKwh").toString()));
            } catch (Exception e) {
                // ignore
            }
        }

        if (body.containsKey("isDefault")) {
            boolean isDefault = Boolean.parseBoolean(body.get("isDefault").toString());
            if (isDefault && !vehicle.isDefault()) {
                vehicle.setDefault(true);
                List<Vehicle> existing = vehicleRepository.findByUser(user);
                for (Vehicle v : existing) {
                    if (v.isDefault() && !v.getId().equals(vehicle.getId())) {
                        v.setDefault(false);
                        vehicleRepository.save(v);
                    }
                }
            }
        }

        Vehicle saved = vehicleRepository.save(vehicle);
        return ResponseEntity.ok(mapVehicleToMap(saved));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteVehicle(@PathVariable Long id) {
        User user = getAuthenticatedUser();
        Vehicle vehicle = vehicleRepository.findByIdAndUser(id, user)
                .orElseThrow(() -> new RuntimeException("Vehicle not found or access denied"));

        boolean wasDefault = vehicle.isDefault();
        vehicleRepository.delete(vehicle);

        if (wasDefault) {
            List<Vehicle> remaining = vehicleRepository.findByUser(user);
            if (!remaining.isEmpty()) {
                Vehicle nextDefault = remaining.get(0);
                nextDefault.setDefault(true);
                vehicleRepository.save(nextDefault);
            }
        }

        return ResponseEntity.ok(Map.of("message", "Vehicle deleted successfully."));
    }

    @PostMapping("/{id}/default")
    public ResponseEntity<?> setDefaultVehicle(@PathVariable Long id) {
        User user = getAuthenticatedUser();
        Vehicle vehicle = vehicleRepository.findByIdAndUser(id, user)
                .orElseThrow(() -> new RuntimeException("Vehicle not found or access denied"));

        if (!vehicle.isDefault()) {
            vehicle.setDefault(true);
            List<Vehicle> existing = vehicleRepository.findByUser(user);
            for (Vehicle v : existing) {
                if (v.isDefault() && !v.getId().equals(vehicle.getId())) {
                    v.setDefault(false);
                    vehicleRepository.save(v);
                }
            }
            vehicleRepository.save(vehicle);
        }

        return ResponseEntity.ok(Map.of("message", "Primary vehicle set successfully."));
    }

    private Map<String, Object> mapVehicleToMap(Vehicle vehicle) {
        Map<String, Object> map = new HashMap<>();
        map.put("id", vehicle.getId());
        map.put("registrationNumber", vehicle.getRegistrationNumber());
        map.put("brand", vehicle.getBrand());
        map.put("model", vehicle.getModel());
        map.put("variant", vehicle.getVariant());
        map.put("type", vehicle.getType());
        map.put("batteryCapacityKwh", vehicle.getBatteryCapacityKwh() != null ? vehicle.getBatteryCapacityKwh().doubleValue() : 0.0);
        map.put("connectorType", vehicle.getConnectorType());
        map.put("nickname", vehicle.getNickname());
        map.put("isDefault", vehicle.isDefault());
        map.put("createdAt", vehicle.getCreatedAt());
        map.put("updatedAt", vehicle.getUpdatedAt());
        return map;
    }
}
