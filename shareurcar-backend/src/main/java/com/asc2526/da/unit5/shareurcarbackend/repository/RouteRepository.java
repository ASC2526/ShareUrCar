package com.asc2526.da.unit5.shareurcarbackend.repository;

import com.asc2526.da.unit5.shareurcarbackend.model.Route;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface RouteRepository extends JpaRepository<Route, Integer> {
    @Query("SELECT r " +
            "FROM Route r " +
            "WHERE r.origin = :origin " +
            "AND r.destination = :destination")
    List<Route> findByOriginAndDestination(
            @Param("origin") String origin,
            @Param("destination") String destination
    );
}