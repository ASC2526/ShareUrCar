package com.asc2526.da.unit5.shareurcarbackend.service;

import com.asc2526.da.unit5.shareurcarbackend.exception.*;
import com.asc2526.da.unit5.shareurcarbackend.model.Route;
import com.asc2526.da.unit5.shareurcarbackend.model.User;
import com.asc2526.da.unit5.shareurcarbackend.repository.DriverRepository;
import com.asc2526.da.unit5.shareurcarbackend.repository.RouteRepository;
import com.asc2526.da.unit5.shareurcarbackend.repository.UserRepository;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class RouteService {

    private final RouteRepository routeRepository;
    private final DriverRepository driverRepository;
    private final UserRepository userRepository;

    public RouteService(RouteRepository routeRepository, DriverRepository driverRepository, UserRepository userRepository) {
        this.routeRepository = routeRepository;
        this.driverRepository = driverRepository;
        this.userRepository = userRepository;
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
            throw new UserIsNotDriverException("Este usuario no está registrado como conductor (falta el coche)");
        }
        if (route.getAvailable_seats() <= 0) {
            throw new IllegalArgumentException("La cantidad de sitios es inválida");
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

    public List<Route> getMyRoutes(Integer userId) {
        return routeRepository.findMyRoutes(userId);
    }

    public void deleteRoute(Integer id) {
        routeRepository.deleteById(id);
    }

    public List<Route> searchRoutes(Double originLat, Double originLng, Double destLat, Double destLng) {
        Double searchRadiusKm = 2.5;
        return routeRepository.findNearbyRoutes(originLat, originLng, destLat, destLng, searchRadiusKm);
    }

    @Transactional
    public void joinRoute(Integer routeId, Integer userId) {

        if (routeId == null || userId == null)
            throw new IllegalArgumentException("La ruta o el usuario no pueden ser nulos");

        Route route = routeRepository.findById(routeId)
                .orElseThrow(() -> new RuntimeException("La ruta no existe"));

        User user = userRepository.findUserByIdUser(userId)
                .orElseThrow(() -> new RuntimeException("El usuario no existe"));

        if (route.getAvailable_seats() <= 0) {
            throw new NoAvailableSeatsException("Lo siento, ya no quedan plazas libres");
        }

        if (route.getIdDriver().equals(userId)) {
            throw new YourOwnRouteException("No puedes unirte a tu propia ruta como pasajero");
        }

        if (route.getPassengers().contains(user)) {
            throw new AlreadyExistsException("Ya estás unido a esta ruta");
        }

        route.getPassengers().add(user);
        route.setAvailable_seats(route.getAvailable_seats() - 1);

        routeRepository.save(route);
    }
}