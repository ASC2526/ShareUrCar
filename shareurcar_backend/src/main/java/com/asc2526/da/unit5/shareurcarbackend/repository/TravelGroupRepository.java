package com.asc2526.da.unit5.shareurcarbackend.repository;

import com.asc2526.da.unit5.shareurcarbackend.model.TravelGroup;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface TravelGroupRepository extends JpaRepository<TravelGroup, Integer> {

    Optional<TravelGroup> findByIdRoute(Integer idRoute);

    @Query("SELECT g " +
            "FROM TravelGroup g " +
            "JOIN Route r ON g.idRoute = r.idRoute " +
            "WHERE r.seriesId = :seriesId")
    Optional<TravelGroup> findBySeriesId(@Param("seriesId") String seriesId);
    List<TravelGroup> findByIdDriver(Integer idDriver);
}