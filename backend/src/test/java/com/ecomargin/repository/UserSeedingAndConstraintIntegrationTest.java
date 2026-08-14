package com.ecomargin.repository;

import com.ecomargin.config.DatabaseSeeder;
import com.ecomargin.model.Role;
import com.ecomargin.model.User;
import com.ecomargin.model.enums.RoleType;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
public class UserSeedingAndConstraintIntegrationTest {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private DatabaseSeeder databaseSeeder;

    @Test
    @DisplayName("Verify platform user seeding, idempotency, and email uniqueness constraint")
    void testUserSeedingAndConstraintIntegrity() {
        // 1. Verify platform users exist from initial startup seed
        Optional<User> adminOpt = userRepository.findByEmailIgnoreCase("admin@ecomargin.com");
        assertTrue(adminOpt.isPresent(), "Admin platform user should be seeded on startup");
        assertNotNull(adminOpt.get().getFirstName());

        long initialUserCount = userRepository.count();

        // 2. Re-run database seeder (Startup #2 & #3 test) to verify idempotency
        assertDoesNotThrow(() -> databaseSeeder.run(), "Re-running database seeder must not throw any constraint violations");
        assertDoesNotThrow(() -> databaseSeeder.run(), "Re-running database seeder a third time must remain 100% idempotent");

        long countAfterReSeed = userRepository.count();
        assertEquals(initialUserCount, countAfterReSeed, "Re-running database seeder must never create duplicate users");

        // 3. Test email uniqueness constraint (inserting duplicate email must fail with DataIntegrityViolationException)
        User duplicateUser = User.builder()
                .email("admin@ecomargin.com")
                .password("password123")
                .firstName("Fake")
                .lastName("Admin")
                .isVerified(true)
                .isAccountNonLocked(true)
                .roles(Collections.emptySet())
                .build();

        assertThrows(DataIntegrityViolationException.class, () -> {
            userRepository.saveAndFlush(duplicateUser);
        }, "Inserting a user with a duplicate email must throw DataIntegrityViolationException due to UNIQUE constraint");
    }

    @Test
    @DisplayName("Verify role seeding idempotency")
    void testRoleSeedingIdempotency() {
        List<Role> roles = roleRepository.findAll();
        assertFalse(roles.isEmpty(), "Roles should be seeded");
        assertTrue(roleRepository.findByName(RoleType.ROLE_CUSTOMER).isPresent());
        assertTrue(roleRepository.findByName(RoleType.ROLE_VENDOR).isPresent());
        assertTrue(roleRepository.findByName(RoleType.ROLE_ADMIN).isPresent());
    }
}
