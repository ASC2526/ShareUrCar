package com.asc2526.da.unit5.shareurcarbackend.repository;

import com.asc2526.da.unit5.shareurcarbackend.model.TravelGroup;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface TravelGroupRepository extends JpaRepository<TravelGroup, Integer> {

    @Query("""
        SELECT tg
        FROM TravelGroup tg
        WHERE tg.idRoute = :routeId
    """)
    List<TravelGroup> findByRouteId(@Param("routeId") Integer routeId);

    Optional<TravelGroup> findByIdRoute(Integer idRoute);

    Optional<TravelGroup> findBySeriesId(String seriesId);
}