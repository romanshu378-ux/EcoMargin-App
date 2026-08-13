package com.ecomargin.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(
    name = "rfid_cards",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_rfid_cards_user_id", columnNames = {"user_id"}),
        @UniqueConstraint(name = "uk_rfid_cards_card_number", columnNames = {"card_number"}),
        @UniqueConstraint(name = "uk_rfid_cards_card_uid", columnNames = {"card_uid"})
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RfidCard {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    @JsonIgnore
    private User user;

    @Column(name = "card_number", nullable = false)
    private String cardNumber;

    @Column(name = "card_uid", nullable = false)
    private String cardUid;

    @Column(nullable = false)
    @Builder.Default
    private String status = "ACTIVE"; // ACTIVE, INACTIVE, BLOCKED

    @Column(name = "linked_vehicle")
    private String linkedVehicle;

    @Column(name = "issued_date")
    private LocalDate issuedDate;

    @Column(name = "last_used")
    private LocalDateTime lastUsed;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (issuedDate == null) {
            issuedDate = LocalDate.now();
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
