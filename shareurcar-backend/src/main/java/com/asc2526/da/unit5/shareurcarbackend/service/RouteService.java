package com.asc2526.da.unit5.shareurcarbackend.service;

import com.asc2526.da.unit5.shareurcarbackend.exception.RouteNotFoundException;
import com.asc2526.da.unit5.shareurcarbackend.model.Route;
import com.asc2526.da.unit5.shareurcarbackend.repository.RouteRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class RouteService {

    private final RouteRepository routeRepository;

    public RouteService(RouteRepository routeRepository) {
        this.routeRepository = routeRepository;
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

    public List<Route> searchRoutes(String origin, String destination) {
        return routeRepository.findByOriginAndDestination(origin, destination);
    }
}