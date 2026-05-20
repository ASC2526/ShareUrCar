package com.asc2526.da.unit5.shareurcarbackend.service;

import com.asc2526.da.unit5.shareurcarbackend.exception.RouteNotFoundException;
import com.asc2526.da.unit5.shareurcarbackend.model.Route;
import com.asc2526.da.unit5.shareurcarbackend.repository.DriverRepository;
import com.asc2526.da.unit5.shareurcarbackend.repository.RouteRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class RouteService {

    private final RouteRepository routeRepository;
    private final DriverRepository driverRepository;

    public RouteService(RouteRepository routeRepository, DriverRepository driverRepository) {
        this.routeRepository = routeRepository;
        this.driverRepository = driverRepository;
    }

    public List<Route> getAllRoutes() {
        return routeRepository.findAll();
    }

    public Route getRouteById(Integer id) {
        return routeRepository.findById(id)
                .orElseThrow(() -> new RouteNotFoundException(id));
    }

    public Route createRoute(Route route) {
        if (route.getIdDriver() == null) {
            throw new IllegalArgumentException("Driver requerido");
        }
        if (!driverRepository.existsByIdDriver(route.getIdDriver())) {
            throw new RuntimeException("Este usuario no está registrado como conductor (falta el coche)");
        }
        if (route.getAvailable_seats() <= 0) {
            throw new IllegalArgumentException("Seats inválidos");
        }
        return routeRepository.save(route);
    }

    public Route updateRoute(Integer id, Route newRoute) {
        Route route = getRouteById(id);

        route.setOrigin(newRoute.getOrigin());
        route.setDestination(newRoute.getDestination());
        route.setDeparture_time(newRoute.getDeparture_time());
        route.setArrival_time(newRoute.getArrival_time());
        route.setAvailable_seats(newRoute.getAvailable_seats());

        if (route.getIdDriver() == null) {
            throw new IllegalArgumentException("Driver requerido");
        }

        if (route.getAvailable_seats() <= 0) {
            throw new IllegalArgumentException("Seats inválidos");
        }
        return routeRepository.save(route);
    }

    public void deleteRoute(Integer id) {
        routeRepository.deleteById(id);
    }

    public List<Route> searchRoutes(Double originLat, Double originLng, Double destLat, Double destLng) {
        Double searchRadiusKm = 1.5;
        return routeRepository.findNearbyRoutes(originLat, originLng, destLat, destLng, searchRadiusKm);
    }
}