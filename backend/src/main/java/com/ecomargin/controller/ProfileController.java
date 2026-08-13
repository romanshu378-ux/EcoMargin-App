package com.ecomargin.controller;

import com.ecomargin.model.User;
import com.ecomargin.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@Slf4j
@RestController
@RequestMapping("/api/v1/profile")
@RequiredArgsConstructor
public class ProfileController {

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
    public ResponseEntity<?> getProfile() {
        User user = getAuthenticatedUser();
        return ResponseEntity.ok(mapUserToProfileMap(user));
    }

    @PutMapping
    public ResponseEntity<?> updateProfile(@RequestBody Map<String, Object> body) {
        User user = getAuthenticatedUser();

        // Combined Name Splitting
        if (body.containsKey("fullName")) {
            String fullName = (String) body.get("fullName");
            if (fullName != null) {
                String[] parts = fullName.trim().split(" ", 2);
                user.setFirstName(parts[0]);
                user.setLastName(parts.length > 1 ? parts[1] : "");
            }
        } else {
            if (body.containsKey("firstName")) user.setFirstName((String) body.get("firstName"));
            if (body.containsKey("lastName")) user.setLastName((String) body.get("lastName"));
        }

        // Phone/Mobile Number
        if (body.containsKey("phoneNumber")) {
            String newPhone = (String) body.get("phoneNumber");
            if (newPhone != null && !newPhone.isBlank() && !newPhone.equals(user.getPhoneNumber())) {
                Optional<User> existingUser = userRepository.findByPhoneNumber(newPhone.trim());
                if (existingUser.isPresent() && !existingUser.get().getId().equals(user.getId())) {
                    return ResponseEntity.status(HttpStatus.CONFLICT)
                            .body(Map.of("message", "Phone number is already registered to another account."));
                }
                user.setPhoneNumber(newPhone.trim());
            }
        }

        // Date of Birth
        if (body.containsKey("dateOfBirth") && body.get("dateOfBirth") != null) {
            try {
                user.setDateOfBirth(LocalDate.parse(body.get("dateOfBirth").toString()));
            } catch (Exception e) {
                return ResponseEntity.badRequest().body(Map.of("message", "Invalid Date of Birth format. Please use YYYY-MM-DD."));
            }
        }

        // Other fields
        if (body.containsKey("gender")) user.setGender((String) body.get("gender"));
        if (body.containsKey("address")) user.setAddress((String) body.get("address"));
        if (body.containsKey("city")) user.setCity((String) body.get("city"));
        if (body.containsKey("state")) user.setState((String) body.get("state"));
        if (body.containsKey("pinCode")) user.setPinCode((String) body.get("pinCode"));
        if (body.containsKey("emergencyContactName")) user.setEmergencyContactName((String) body.get("emergencyContactName"));
        if (body.containsKey("emergencyContactNumber")) user.setEmergencyContactNumber((String) body.get("emergencyContactNumber"));

        User saved = userRepository.save(user);
        return ResponseEntity.ok(mapUserToProfileMap(saved));
    }

    @PostMapping("/photo")
    public ResponseEntity<?> uploadPhoto(@RequestParam("file") MultipartFile file) {
        User user = getAuthenticatedUser();
        try {
            byte[] bytes = file.getBytes();
            user.setProfileImage(bytes);
            user.setProfileImageUrl("/api/v1/profile/photo/" + user.getId());
            userRepository.save(user);
            return ResponseEntity.ok(Map.of(
                    "message", "Profile updated successfully.",
                    "profileImageUrl", "/api/v1/profile/photo/" + user.getId()
            ));
        } catch (IOException e) {
            log.error("Failed to read uploaded photo bytes", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("message", "Failed to upload photo: " + e.getMessage()));
        }
    }

    @DeleteMapping("/photo")
    public ResponseEntity<?> removePhoto() {
        User user = getAuthenticatedUser();
        user.setProfileImage(null);
        user.setProfileImageUrl(null);
        userRepository.save(user);
        return ResponseEntity.ok(Map.of("message", "Profile photo removed successfully."));
    }

    @GetMapping("/photo/{userId}")
    public ResponseEntity<byte[]> getPhoto(@PathVariable Long userId) {
        Optional<byte[]> imageOpt = userRepository.findProfileImageByUserId(userId);
        if (imageOpt.isEmpty() || imageOpt.get() == null || imageOpt.get().length == 0) {
            return ResponseEntity.notFound().build();
        }
        
        byte[] imageBytes = imageOpt.get();
        return ResponseEntity.ok()
                .contentType(MediaType.IMAGE_JPEG)
                .body(imageBytes);
    }

    private Map<String, Object> mapUserToProfileMap(User user) {
        Map<String, Object> map = new HashMap<>();
        map.put("id", user.getId());
        map.put("email", user.getEmail());
        map.put("firstName", user.getFirstName() != null ? user.getFirstName() : "");
        map.put("lastName", user.getLastName() != null ? user.getLastName() : "");
        map.put("fullName", (user.getFirstName() != null ? user.getFirstName() : "") + 
                (user.getLastName() != null && !user.getLastName().isEmpty() ? " " + user.getLastName() : ""));
        map.put("phoneNumber", user.getPhoneNumber() != null ? user.getPhoneNumber() : "");
        map.put("dateOfBirth", user.getDateOfBirth() != null ? user.getDateOfBirth().toString() : null);
        map.put("gender", user.getGender());
        map.put("address", user.getAddress());
        map.put("city", user.getCity());
        map.put("state", user.getState());
        map.put("pinCode", user.getPinCode());
        map.put("emergencyContactName", user.getEmergencyContactName());
        map.put("emergencyContactNumber", user.getEmergencyContactNumber());
        map.put("profileImageUrl", user.getProfileImageUrl());
        map.put("createdAt", user.getCreatedAt());
        map.put("updatedAt", user.getUpdatedAt());
        return map;
    }
}
