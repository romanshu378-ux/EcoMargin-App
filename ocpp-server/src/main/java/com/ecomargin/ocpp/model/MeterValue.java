package com.ecomargin.ocpp.model;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "meter_values")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MeterValue {

    @Id
    private Long id;

    @Column(name = "session_id", nullable = false)
    private Long sessionId;

    @Builder.Default
    @Column(nullable = false)
    private LocalDateTime timestamp = LocalDateTime.now();

    @Column(name = "\"value\"", nullable = false, precision = 10, scale = 3)
    private BigDecimal value;

    @Builder.Default
    @Column(length = 20)
    private String unit = "Wh";

    @Builder.Default
    @Column(length = 100)
    private String measurand = "Energy.Active.Import.Register";

    @PrePersist
    protected void onCreate() {
        if (id == null) {
            id = System.currentTimeMillis() * 1000L + (long)(Math.random() * 1000);
        }
        if (timestamp == null) {
            timestamp = LocalDateTime.now();
        }
    }
}
