package com.ecomargin.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(
    name = "privacy_settings",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_privacy_settings_user_id", columnNames = {"user_id"})
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PrivacySettings {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    @JsonIgnore
    private User user;

    @Column(name = "location_permission", nullable = false)
    @Builder.Default
    private boolean locationPermission = true;

    @Column(name = "location_sharing", nullable = false)
    @Builder.Default
    private boolean locationSharing = true;

    @Column(name = "nearby_charger_personalization", nullable = false)
    @Builder.Default
    private boolean nearbyChargerPersonalization = true;

    @Column(name = "push_notifications", nullable = false)
    @Builder.Default
    private boolean pushNotifications = true;

    @Column(name = "charging_activity_visibility", nullable = false)
    @Builder.Default
    private boolean chargingActivityVisibility = true;

    @Column(name = "usage_analytics", nullable = false)
    @Builder.Default
    private boolean usageAnalytics = true;

    @Column(name = "personalized_recommendations", nullable = false)
    @Builder.Default
    private boolean personalizedRecommendations = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
