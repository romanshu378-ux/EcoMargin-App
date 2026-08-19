package com.ecomargin.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "stations")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Station {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "vendor_id")
    private Vendor vendor;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false, precision = 9, scale = 6)
    private BigDecimal latitude;

    @Column(nullable = false, precision = 9, scale = 6)
    private BigDecimal longitude;

    @Column(columnDefinition = "TEXT")
    private String address;

    @Column
    private String city;

    @Column
    private String state;

    @Column
    private String country;

    @Column(nullable = false)
    private String status = "ACTIVE"; // ACTIVE, INACTIVE, UNDER_MAINTENANCE

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    @OneToMany(mappedBy = "station", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Charger> chargers;

    @Transient
    private Double distanceKm;

    @Transient
    private String distanceStr;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    @com.fasterxml.jackson.annotation.JsonProperty("priceStr")
    @Transient
    public String getPriceStr() {
        if (chargers != null) {
            BigDecimal minRate = null;
            for (Charger c : chargers) {
                if (c.getConnectors() != null) {
                    for (Connector conn : c.getConnectors()) {
                        BigDecimal r = conn.getUnitRate();
                        if (r != null && r.compareTo(BigDecimal.ZERO) > 0) {
                            if (minRate == null || r.compareTo(minRate) < 0) {
                                minRate = r;
                            }
                        }
                    }
                }
            }
            if (minRate != null) {
                if (minRate.stripTrailingZeros().scale() <= 0) {
                    return "₹" + minRate.longValue() + " / kWh";
                }
                return "₹" + minRate.setScale(2, java.math.RoundingMode.HALF_UP).toString() + " / kWh";
            }
        }
        return "₹18.00 / kWh";
    }

    @com.fasterxml.jackson.annotation.JsonProperty("priceSubtext")
    @Transient
    public String getPriceSubtext() {
        return "Starting from";
    }

    @com.fasterxml.jackson.annotation.JsonProperty("chargerType")
    @Transient
    public String getChargerType() {
        if (chargers != null) {
            java.util.Set<String> types = new java.util.LinkedHashSet<>();
            for (Charger c : chargers) {
                if (c.getConnectors() != null) {
                    for (Connector conn : c.getConnectors()) {
                        if (conn.getType() != null && !conn.getType().isBlank()) {
                            types.add(conn.getType().toUpperCase());
                        }
                    }
                }
            }
            if (!types.isEmpty()) {
                return String.join(", ", types);
            }
        }
        return "CCS2";
    }

    @com.fasterxml.jackson.annotation.JsonProperty("chargerCategory")
    @Transient
    public String getChargerCategory() {
        String cType = getChargerType();
        if (cType.contains("CCS2") || cType.contains("CHADEMO") || cType.contains("GB_T")) {
            return "Fast Charger";
        }
        return "Standard Charger";
    }

    @com.fasterxml.jackson.annotation.JsonProperty("imageUrl")
    @Transient
    public String getImageUrl() {
        return "https://images.unsplash.com/photo-1563720223185-11003d516935?w=500&q=80";
    }

    @com.fasterxml.jackson.annotation.JsonProperty("isVerified")
    @Transient
    public boolean isVerified() {
        return true;
    }
}
