package com.asc2526.da.unit5.shareurcarbackend.repository;

import com.asc2526.da.unit5.shareurcarbackend.model.Route;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface RouteRepository extends JpaRepository<Route, Integer> {
    @SuppressWarnings("SqlDialectInspection")
    @Query(value = """
        SELECT * FROM routes r
    WHERE r.status = 'PENDING'
    AND
    (6371 * acos(cos(radians(:oLat)) * cos(radians(r.origin_lat))
    * cos(radians(r.origin_lng) - radians(:oLng))
    + sin(radians(:oLat)) * sin(radians(r.origin_lat)))) <= :radius
    AND
    (6371 * acos(cos(radians(:dLat)) * cos(radians(r.destination_lat))
    * cos(radians(r.destination_lng) - radians(:dLng))
    + sin(radians(:dLat)) * sin(radians(r.destination_lat)))) <= :radius
    ORDER BY (6371 * acos(cos(radians(:oLat)) * cos(radians(r.origin_lat))
    * cos(radians(r.origin_lng) - radians(:oLng))
    + sin(radians(:oLat)) * sin(radians(r.origin_lat)))) ASC
    """, nativeQuery = true)
    List<Route> findNearbyRoutes(
            @Param("oLat") Double oLat,
            @Param("oLng") Double oLng,
            @Param("dLat") Double dLat,
            @Param("dLng") Double dLng,
            @Param("radius") Double radius
    );

    @SuppressWarnings("SqlDialectInspection")
    @Query(value = """
        SELECT r.* FROM routes r
        WHERE r.id_driver = :userId
        UNION
        SELECT r.* FROM routes r
        JOIN route_passengers rp ON r.id_route = rp.id_route
        WHERE rp.id_user = :userId
        """, nativeQuery = true)
    List<Route> findMyRoutes(@Param("userId") Integer userId);

    @Query("""
        SELECT COUNT(r)
        FROM Route r
        WHERE r.idDriver = :userId
        AND r.status = 'COMPLETED'
        """)
    long countCompletedRoutesByDriverId(@Param("userId") Integer userId);

    @Query("SELECT r FROM Route r " +
            "WHERE r.status = 'PENDING' " +
            "AND r.arrival_time < :now")
    List<Route> findPendingRoutesWhereArrivalTimePassed(@Param("now") LocalDateTime now);
    List<Route> findBySeriesId(String seriesId);

}
