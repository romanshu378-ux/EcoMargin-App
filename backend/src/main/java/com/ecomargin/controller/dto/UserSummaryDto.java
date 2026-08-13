package com.ecomargin.controller.dto;

import com.ecomargin.model.User;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.Set;
import java.util.stream.Collectors;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserSummaryDto {
    private Long id;
    private String email;
    private String firstName;
    private String lastName;
    private String phoneNumber;
    private boolean isVerified;
    private boolean isAccountNonLocked;
    private Set<String> roles;
    private LocalDateTime createdAt;

    public static UserSummaryDto fromEntity(User user) {
        if (user == null) return null;
        return UserSummaryDto.builder()
                .id(user.getId())
                .email(user.getEmail())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .phoneNumber(user.getPhoneNumber())
                .isVerified(user.isVerified())
                .isAccountNonLocked(user.isAccountNonLocked())
                .roles(user.getRoles() != null 
                        ? user.getRoles().stream().map(r -> r.getName().name()).collect(Collectors.toSet())
                        : Set.of())
                .createdAt(user.getCreatedAt())
                .build();
    }
}
