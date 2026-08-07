package com.ecomargin.model;

import jakarta.persistence.*;
import lombok.*;
import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "meter_values")
@IdClass(MeterValue.MeterValueId.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MeterValue {

    @Id
    private Long id;

    @Id
    @Column(nullable = false)
    private LocalDateTime timestamp;

    @Column(name = "session_id", nullable = false)
    private Long sessionId; // Kept as Long to minimize entity fetch overhead for high-volume telemetry

    @Column(nullable = false, precision = 10, scale = 3)
    private BigDecimal value;

    @Column(length = 20)
    private String unit = "Wh";

    @Column(length = 100)
    private String measurand = "Energy.Active.Import.Register";

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @EqualsAndHashCode
    public static class MeterValueId implements Serializable {
        private Long id;
        private LocalDateTime timestamp;
    }
}
