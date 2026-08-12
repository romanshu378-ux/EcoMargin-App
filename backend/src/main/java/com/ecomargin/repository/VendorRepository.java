package com.ecomargin.repository;

import com.ecomargin.model.Vendor;
import com.ecomargin.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface VendorRepository extends JpaRepository<Vendor, Long> {
    Optional<Vendor> findByBusinessName(String businessName);
    Optional<Vendor> findByUser(User user);
}
