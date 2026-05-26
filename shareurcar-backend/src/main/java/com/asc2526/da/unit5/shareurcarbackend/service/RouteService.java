package com.asc2526.da.unit5.shareurcarbackend.service;

import com.asc2526.da.unit5.shareurcarbackend.exception.*;
import com.asc2526.da.unit5.shareurcarbackend.model.*;
import com.asc2526.da.unit5.shareurcarbackend.repository.*;
import jakarta.transaction.Transactional;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Service
public class RouteService {

    private final RouteRepository routeRepository;
    private final DriverRepository driverRepository;
    private final UserRepository userRepository;
    private final TravelGroupRepository travelGroupRepository;
    private final GroupPassengerRepository groupPassengerRepository;

    public RouteService(RouteRepository routeRepository, DriverRepository driverRepository, UserRepository userRepository, TravelGroupRepository travelGroupRepository, GroupPassengerRepository groupPassengerRepository) {
        this.routeRepository = routeRepository;
        this.driverRepository = driverRepository;
        this.userRepository = userRepository;
        this.travelGroupRepository = travelGroupRepository;
        this.groupPassengerRepository = groupPassengerRepository;
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
        Route savedRoute = routeRepository.save(route);

        TravelGroup group = new TravelGroup();
        group.setIdRoute(savedRoute.getIdRoute());
        group.setIdDriver(savedRoute.getIdDriver());
        group.setStatus("ACTIVE");
        group.setTravelDate(java.time.LocalDate.now());
        group.setTravelTime(savedRoute.getDeparture_time());
        travelGroupRepository.save(group);
        return savedRoute;
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

    public List<Map<String,Object>> getMyRoutes(Integer userId) {

        List<Route> routes = routeRepository.findMyRoutes(userId);
        List<Map<String,Object>> result = new java.util.ArrayList<>();
        for(Route route : routes) {
            User driver = userRepository.findUserByIdUser(route.getIdDriver()).orElseThrow();
            Driver driverCar = driverRepository.findByIdDriver(route.getIdDriver()).orElseThrow();
            Map<String,Object> map = new java.util.HashMap<>();

            map.put("idRoute",route.getIdRoute());
            map.put("idDriver",route.getIdDriver());
            map.put("origin",route.getOrigin());
            map.put("destination",route.getDestination());
            map.put("originLat",route.getOriginLat());
            map.put("originLng",route.getOriginLng());
            map.put("destinationLat",route.getDestinationLat());
            map.put("destinationLng",route.getDestinationLng());
            map.put("departure_time",route.getDeparture_time());
            map.put("arrival_time",route.getArrival_time());
            map.put("days_of_week",route.getDays_of_week());
            map.put("frequency",route.getFrequency());
            map.put("available_seats",route.getAvailable_seats());
            map.put("status",route.getStatus());
            map.put("driverConfirmed",route.isDriverConfirmed());
            map.put("passengers",route.getPassengers());
            map.put("driverName", driver.getFirstname() + " " + driver.getLastname());
            map.put("maxSeats", driverCar.getMaxSeats());
            result.add(map);
        }
        return result;
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

        if (routeId == null || userId == null) throw new IllegalArgumentException("La ruta o el usuario no pueden ser nulos");
        Route route = routeRepository.findById(routeId).orElseThrow(() -> new RuntimeException("La ruta no existe"));
        User user = userRepository.findUserByIdUser(userId).orElseThrow(() -> new RuntimeException("El usuario no existe"));

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
        TravelGroup group = travelGroupRepository.findByIdRoute(routeId).orElseThrow();
        GroupPassenger passenger = new GroupPassenger();

        passenger.setIdGroup(group.getIdGroup());
        passenger.setIdUser(userId);
        passenger.setState("ACTIVE");
        passenger.setConfirmed(false);

        groupPassengerRepository.save(passenger);
        routeRepository.save(route);
    }

    @Transactional
    public void leaveRoute(Integer routeId, Integer userId) {
        Route route = routeRepository.findById(routeId)
                .orElseThrow(() -> new RuntimeException("La ruta no existe"));

        User user = userRepository.findUserByIdUser(userId)
                .orElseThrow(() -> new RuntimeException("El usuario no existe"));

        if (route.getIdDriver().equals(userId)) {
            throw new RuntimeException("Eres el conductor, no puedes abandonar la ruta como pasajero. Debes cancelarla entera.");
        }
        if (!route.getPassengers().contains(user)) {
            throw new RuntimeException("No estás unido a esta ruta");
        }

        route.getPassengers().remove(user);
        route.setAvailable_seats(route.getAvailable_seats() + 1);

        TravelGroup group = travelGroupRepository.findByIdRoute(routeId).orElseThrow();
        GroupPassenger gp = groupPassengerRepository.findByIdGroupAndIdUser(group.getIdGroup(), userId).orElseThrow();

        groupPassengerRepository.delete(gp);
        routeRepository.save(route);
    }

    public int getCompletedTripsCount(Integer userId) {
        if (userId == null) {
            throw new IllegalArgumentException("El ID de usuario no puede ser nulo");
        }
        if (!userRepository.existsUserByIdUser(userId)) {
            throw new UserNotFoundException(userId);
        }

        long count = routeRepository.countCompletedRoutesByDriverId(userId);
        return (int) count;
    }

    public void completeRoute(Integer routeId) {
        if (routeId == null) {
            throw new IllegalArgumentException("El ID de la ruta no puede ser nulo");
        }
        Route route = routeRepository.findById(routeId).orElseThrow(() -> new RouteNotFoundException(routeId));
        if ("COMPLETED".equals(route.getStatus())) {
            throw new IllegalStateException("El viaje ya está finalizado");
        }

        route.setStatus("COMPLETED");
        routeRepository.save(route);
    }

    @Scheduled(cron = "0 0 * * * *")
    public void autoCompleteOldRoutes() {
        LocalDateTime now = LocalDateTime.now();
        List<Route> rutasAntiguas = routeRepository.findPendingRoutesWhereArrivalTimePassed(now);

        for (Route r : rutasAntiguas) {
            r.setStatus("COMPLETED");
            routeRepository.save(r);
        }
    }

    @Transactional
    public void confirmParticipation(Integer routeId, Integer userId) {
        Route route = routeRepository.findById(routeId).orElseThrow(() -> new RouteNotFoundException(routeId));

        TravelGroup group = travelGroupRepository.findByIdRoute(routeId).orElseThrow(() -> new RuntimeException("No hay grupo asociado a esta ruta"));

        if (route.getIdDriver().equals(userId)) {
            route.setDriverConfirmed(true);
            routeRepository.save(route);
        } else {
            GroupPassenger gp = groupPassengerRepository.findByIdGroupAndIdUser(group.getIdGroup(), userId)
                    .orElseThrow(() -> new RuntimeException("No eres pasajero de este grupo"));
            gp.setConfirmed(true);
            groupPassengerRepository.save(gp);
        }

        if (checkAllConfirmed(route, group)) {
            route.setStatus("COMPLETED");
            routeRepository.save(route);
        }
    }

    private boolean checkAllConfirmed(Route route, TravelGroup group) {
        if (!route.isDriverConfirmed())
            return false;

        List<GroupPassenger> passengers = groupPassengerRepository.findByIdGroup(group.getIdGroup());

        for (GroupPassenger p : passengers) {
            if (!p.isConfirmed())
                return false;
        }
        return true;
    }
}