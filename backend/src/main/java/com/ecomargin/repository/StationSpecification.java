package com.ecomargin.repository;

import com.ecomargin.model.Station;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.util.StringUtils;

public class StationSpecification {

    public static Specification<Station> hasStatus(String status) {
        return (root, query, cb) -> {
            if (!StringUtils.hasText(status)) return null;
            return cb.equal(root.get("status"), status.toUpperCase());
        };
    }

    public static Specification<Station> hasVendorId(Long vendorId) {
        return (root, query, cb) -> {
            if (vendorId == null) return null;
            return cb.equal(root.get("vendor").get("id"), vendorId);
        };
    }

    public static Specification<Station> hasNameLike(String search) {
        return (root, query, cb) -> {
            if (!StringUtils.hasText(search)) return null;
            return cb.like(cb.lower(root.get("name")), "%" + search.toLowerCase() + "%");
        };
    }
}
