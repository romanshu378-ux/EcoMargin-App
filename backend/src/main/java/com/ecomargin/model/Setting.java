package com.ecomargin.model;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import java.time.LocalDateTime;
import java.util.Map;

@Entity
@Table(name = "settings")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Setting {

    /**
     * Maps to the "setting_key" column in the production PostgreSQL settings table.
     * The production schema uses setting_key as the primary key (created by Hibernate ddl-auto
     * before V1 migration was applied). All new installs via V7 migration also use setting_key.
     * Do NOT use @Column(name = "\"key\"") — that causes null constraint violations in PostgreSQL.
     */
    @Id
    @Column(name = "setting_key", nullable = false, length = 100)
    private String key;

    /**
     * Maps to the "setting_value" column in the settings table.
     */
    @Column(name = "setting_value", nullable = false, columnDefinition = "TEXT")
    private String value;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "metadata")
    private Map<String, Object> metadata;

    @Builder.Default
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    @PrePersist
    @PreUpdate
    protected void onUpdate() {
        if (updatedAt == null) {
            updatedAt = LocalDateTime.now();
        }
    }
}
