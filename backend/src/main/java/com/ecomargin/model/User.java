package com.ecomargin.model;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import java.time.LocalDateTime;
import java.util.Collection;
import java.util.HashSet;
import java.util.Set;
import java.util.stream.Collectors;

@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User implements UserDetails {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String email;

    @com.fasterxml.jackson.annotation.JsonIgnore
    @Column(nullable = true) // Nullable because of Google Login / OTP
    private String password;

    @Column(name = "jwt_version", nullable = false)
    @Builder.Default
    private Integer jwtVersion = 0;

    private String firstName;
    private String lastName;

    @Column(unique = true)
    private String phoneNumber;

    private String googleId;

    private java.time.LocalDate dateOfBirth;
    private String gender;
    private String address;
    private String city;
    private String state;
    private String pinCode;
    private String emergencyContactName;
    private String emergencyContactNumber;
    private String profileImageUrl;

    @Basic(fetch = FetchType.LAZY)
    @Column(name = "profile_image", columnDefinition = "bytea")
    @com.fasterxml.jackson.annotation.JsonIgnore
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    private byte[] profileImage;

    @Builder.Default
    @Column(name = "is_verified", nullable = false)
    private boolean isVerified = true;

    @Builder.Default
    @Column(name = "is_account_non_locked", nullable = false)
    private boolean isAccountNonLocked = true;

    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(
        name = "user_roles",
        joinColumns = @JoinColumn(name = "user_id"),
        inverseJoinColumns = @JoinColumn(name = "role_id")
    )
    private Set<Role> roles = new HashSet<>();

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        Set<GrantedAuthority> authorities = new HashSet<>();
        if (roles != null) {
            for (Role role : roles) {
                if (role.getName() != null) {
                    authorities.add(new SimpleGrantedAuthority(role.getName().name()));
                }
                if (role.getPermissions() != null) {
                    for (Permission permission : role.getPermissions()) {
                        if (permission.getName() != null) {
                            authorities.add(new SimpleGrantedAuthority(permission.getName()));
                        }
                    }
                }
            }
        }
        return authorities;
    }

    @Override
    public String getUsername() {
        return email;
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return isAccountNonLocked;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return deletedAt == null;
    }
}
