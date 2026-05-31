package com.asc2526.da.unit5.shareurcarbackend.service;

import com.asc2526.da.unit5.shareurcarbackend.dto.RouteCreateDTO;
import com.asc2526.da.unit5.shareurcarbackend.exception.*;
import com.asc2526.da.unit5.shareurcarbackend.model.*;
import com.asc2526.da.unit5.shareurcarbackend.repository.*;
import jakarta.transaction.Transactional;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class RouteService {

    private final RouteRepository routeRepository;
    private final DriverRepository driverRepository;
    private final UserRepository userRepository;
    private final TravelGroupRepository travelGroupRepository;
    private final GroupPassengerRepository groupPassengerRepository;
    private final PaymentRepository paymentRepository;
    private final NotificationService notificationService;

    public RouteService(RouteRepository routeRepository, DriverRepository driverRepository, UserRepository userRepository, TravelGroupRepository travelGroupRepository, GroupPassengerRepository groupPassengerRepository, PaymentRepository paymentRepository, NotificationService notificationService) {
        this.routeRepository = routeRepository;
        this.driverRepository = driverRepository;
        this.userRepository = userRepository;
        this.travelGroupRepository = travelGroupRepository;
        this.groupPassengerRepository = groupPassengerRepository;
        this.paymentRepository = paymentRepository;
        this.notificationService = notificationService;
    }

    public List<Route> getAllRoutes() {
        return routeRepository.findAll();
    }

    public Route getRouteById(Integer id) {
        return routeRepository.findById(id)
                .orElseThrow(() -> new RouteNotFoundException(id));
    }

    private void createGroupForRoute(Route route) {
        TravelGroup group = new TravelGroup();
        group.setIdRoute(route.getIdRoute());
        group.setIdDriver(route.getIdDriver());
        group.setStatus("ACTIVE");
        group.setTravelDate(route.getTravel_date());
        group.setTravelTime(route.getDeparture_time());
        travelGroupRepository.save(group);
    }

    @Transactional
    public List<Route> createRoutes(RouteCreateDTO dto) {

        if (dto.getIdDriver() == null) {
            throw new IllegalArgumentException("Driver requerido");
        }

        if (!driverRepository.existsByIdDriver(dto.getIdDriver())) {
            throw new UserIsNotDriverException(
                    "Este usuario no está registrado como conductor (falta el coche)"
            );
        }

        if (dto.getAvailable_seats() == null || dto.getAvailable_seats() <= 0) {
            throw new IllegalArgumentException("La cantidad de sitios es inválida");
        }

        Route base = new Route();
        base.setIdDriver(dto.getIdDriver());
        base.setOrigin(dto.getOrigin());
        base.setDestination(dto.getDestination());
        base.setOriginLat(dto.getOriginLat());
        base.setOriginLng(dto.getOriginLng());
        base.setDestinationLat(dto.getDestinationLat());
        base.setDestinationLng(dto.getDestinationLng());
        base.setDeparture_time(dto.getDeparture_time());
        base.setReturn_time(dto.getReturn_time());
        base.setFrequency(dto.getFrequency());
        base.setDays_of_week(dto.getDays_of_week());
        base.setTravel_date(dto.getTravel_date());
        base.setStart_date(dto.getStart_date());
        base.setEnd_date(dto.getEnd_date());
        base.setAvailable_seats(dto.getAvailable_seats());
        base.setAllowRoundTrip(dto.getAllowRoundTrip() != null ? dto.getAllowRoundTrip() : false);
        base.setPrefNoTalk(dto.getPref_no_talk());
        base.setPrefLuggage(dto.getPref_luggage());
        base.setPrefMusic(dto.getPref_music());
        base.setPrefSmoke(dto.getPref_smoke());

        String seriesId = java.util.UUID.randomUUID().toString();
        List<Route> savedRoutes = new ArrayList<>();

        if ("semanal".equalsIgnoreCase(dto.getFrequency())) {
            List<DayOfWeek> validDays = parseDaysOfWeek(dto.getDays_of_week());
            LocalDate current = dto.getStart_date();
            LocalDate end = dto.getEnd_date();

            while (!current.isAfter(end)) {
                if (validDays.contains(current.getDayOfWeek())) {
                    Route routeInstance = cloneRouteDetails(base);
                    routeInstance.setTravel_date(current);
                    routeInstance.setSeriesId(seriesId);
                    routeInstance.setDriverConfirmed(false);
                    savedRoutes.add(routeRepository.save(routeInstance));
                }
                current = current.plusDays(1);
            }
        } else {
            base.setSeriesId(seriesId);
            savedRoutes.add(routeRepository.save(base));
        }

        for(Route route : savedRoutes) {
            createGroupForRoute(route);
        }

        return savedRoutes;
    }

    private Route cloneRouteDetails(Route source) {
        Route r = new Route();
        r.setIdDriver(source.getIdDriver());
        r.setOrigin(source.getOrigin());
        r.setDestination(source.getDestination());
        r.setOriginLat(source.getOriginLat());
        r.setOriginLng(source.getOriginLng());
        r.setDestinationLat(source.getDestinationLat());
        r.setDestinationLng(source.getDestinationLng());
        r.setDeparture_time(source.getDeparture_time());
        r.setArrival_time(source.getArrival_time());
        r.setFrequency(source.getFrequency());
        r.setDays_of_week(source.getDays_of_week());
        r.setStart_date(source.getStart_date());
        r.setEnd_date(source.getEnd_date());
        r.setAvailable_seats(source.getAvailable_seats());
        r.setAllowRoundTrip(source.getAllowRoundTrip());
        r.setReturn_time(source.getReturn_time());
        r.setPrefNoTalk(source.getPrefNoTalk());
        r.setPrefLuggage(source.getPrefLuggage());
        r.setPrefMusic(source.getPrefMusic());
        r.setPrefSmoke(source.getPrefSmoke());
        return r;
    }

    private List<DayOfWeek> parseDaysOfWeek(String daysStr) {
        List<DayOfWeek> days = new ArrayList<>();
        if (daysStr == null || daysStr.isEmpty()) return days;
        String[] split = daysStr.split(",");
        for (String d : split) {
            switch (d.trim().toUpperCase()) {
                case "L": days.add(DayOfWeek.MONDAY); break;
                case "M": days.add(DayOfWeek.TUESDAY); break;
                case "X": days.add(DayOfWeek.WEDNESDAY); break;
                case "J": days.add(DayOfWeek.THURSDAY); break;
                case "V": days.add(DayOfWeek.FRIDAY); break;
                case "S": days.add(DayOfWeek.SATURDAY); break;
                case "D": days.add(DayOfWeek.SUNDAY); break;
            }
        }
        return days;
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
            Driver driverCar = driverRepository.findByIdDriver(route.getIdDriver()).orElse(null);

            Map<String,Object> map = new java.util.HashMap<>();
            map.put("idRoute",route.getIdRoute());
            map.put("idDriver",route.getIdDriver());
            map.put("origin",route.getOrigin());
            map.put("destination",route.getDestination());
            map.put("originLat",route.getOriginLat());
            map.put("originLng",route.getOriginLng());
            map.put("destinationLat",route.getDestinationLat());
            map.put("destinationLng",route.getDestinationLng());
            map.put("departure_time", route.getDeparture_time() != null ? route.getDeparture_time().toString() : null);
            map.put("arrival_time", route.getArrival_time() != null ? route.getArrival_time().toString() : null);
            map.put("days_of_week",route.getDays_of_week());
            map.put("frequency",route.getFrequency());
            map.put("available_seats",route.getAvailable_seats());
            map.put("status",route.getStatus());
            map.put("driverConfirmed",route.getDriverConfirmed());
            map.put("passengers",route.getPassengers());
            map.put("driverName", driver.getFirstname() + " " + driver.getLastname());
            map.put("maxSeats", driverCar != null ? driverCar.getMaxSeats() : 4);
            map.put("allowRoundTrip", route.getAllowRoundTrip());
            map.put("travel_date", route.getTravel_date() != null ? route.getTravel_date().toString() : null);
            map.put("start_date", route.getStart_date() != null ? route.getStart_date().toString() : null);
            map.put("end_date", route.getEnd_date() != null ? route.getEnd_date().toString() : null);
            map.put("return_time", route.getReturn_time() != null ? route.getReturn_time().toString() : null);
            map.put("seriesId", route.getSeriesId());
            map.put("pref_no_talk", route.getPrefNoTalk());
            map.put("pref_luggage", route.getPrefLuggage());
            map.put("pref_music", route.getPrefMusic());
            map.put("pref_smoke", route.getPrefSmoke());
            result.add(map);
        }
        return result;
    }

    @Transactional
    public void deleteRoute(Integer id) {
        routeRepository.findById(id).orElseThrow();
        TravelGroup group = travelGroupRepository.findByIdRoute(id).orElse(null);
        if(group != null) {

            List<Payment> payments = paymentRepository.findByGroup(group.getIdGroup());

            for(Payment payment : payments) {
                if("COMPLETED".equals(payment.getPaymentStatus())) {
                    continue;
                }
                User passenger = userRepository.findUserByIdUser(payment.getIdUser()).orElseThrow();
                double held = passenger.getHeldBalance() != null ? passenger.getHeldBalance() : 0.0;
                double balance = passenger.getBalance() != null ? passenger.getBalance() : 0.0;

                passenger.setHeldBalance(Math.max(0, held - payment.getAmount()));
                passenger.setBalance(balance + payment.getAmount());
                userRepository.save(passenger);
                payment.setPaymentStatus("CANCELLED");
                paymentRepository.save(payment);
            }
        }
        routeRepository.deleteById(id);
    }

    public List<Route> searchRoutes(Double originLat, Double originLng, Double destLat, Double destLng) {
        Double searchRadiusKm = 2.5;
        return routeRepository.findNearbyRoutes(originLat, originLng, destLat, destLng, searchRadiusKm);
    }

    private double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
        final int R = 6371;
        double latDistance = Math.toRadians(lat2 - lat1);
        double lonDistance = Math.toRadians(lon2 - lon1);
        double a = Math.sin(latDistance / 2)
                * Math.sin(latDistance / 2)
                + Math.cos(Math.toRadians(lat1))
                * Math.cos(Math.toRadians(lat2))
                * Math.sin(lonDistance / 2)
                * Math.sin(lonDistance / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }

    private double calculateTripPrice(Route route, int passengers) {

        double km = calculateDistanceKm(route.getOriginLat(), route.getOriginLng(), route.getDestinationLat(), route.getDestinationLng());
        if(km < 3 ){
            km *= 1.8;
        }else if(km >= 3 && km < 5){
            km *= 1.40;
        }else if(km >= 5 && km < 10){
            km *= 1.25;
        }
        else{
            km *= 1.15;
        }
        double precioKm = 0.40;
        double precioFinal = km * precioKm;
        double porcentaje;

        switch(passengers) {
            case 1:
                porcentaje = 0.425;
                break;
            case 2:
                porcentaje = 0.550;
                break;
            case 3:
                porcentaje = 0.675;
                break;
            default:
                porcentaje = 0.80;
                break;
        }

        precioFinal = (precioFinal * porcentaje) / passengers;
        precioFinal *= 1.20;

        double precioMinimo;
        if(km <= 5) {
            precioMinimo = 1.20;
        } else if(km <= 9) {
            precioMinimo = 1.75;
        } else if(km <= 14) {
            precioMinimo = 2.00;
        } else {
            precioMinimo = 2.50;
        }
        if(precioFinal < precioMinimo) {
            precioFinal = precioMinimo;
        }
        return Math.round(precioFinal * 100.0) / 100.0;
    }

    @Transactional
    public void joinRoute(Integer routeId, Integer userId, boolean roundTrip) {

        if (routeId == null || userId == null) {
            throw new IllegalArgumentException("La ruta o el usuario no pueden ser nulos");
        }

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

        if (roundTrip && !Boolean.TRUE.equals(route.getAllowRoundTrip())) {
            throw new RuntimeException("Esta ruta no permite ida y vuelta");
        }

        double amount = calculateTripPrice(route, 1);
        if (roundTrip) {
            amount *= 1.9;
        }

        double balance = user.getBalance() != null ? user.getBalance() : 0.0;
        double held = user.getHeldBalance() != null ? user.getHeldBalance() : 0.0;
        double disponible = balance - held;

        if (disponible < amount) {
            throw new RuntimeException("Saldo insuficiente");
        }

        joinSingleRouteInternal(route, user, roundTrip);
    }


    private void joinSingleRouteInternal(Route route, User user, boolean roundTrip) {
        double amount = calculateTripPrice(route, 1);
        if (roundTrip) {
            amount *= 1.9;
        }

        TravelGroup group = travelGroupRepository.findByIdRoute(route.getIdRoute())
                .orElseGet(() -> {
                    TravelGroup newGroup = new TravelGroup();
                    newGroup.setIdRoute(route.getIdRoute());
                    newGroup.setIdDriver(route.getIdDriver());
                    newGroup.setStatus("ACTIVE");
                    newGroup.setTravelDate(route.getTravel_date());
                    newGroup.setTravelTime(route.getDeparture_time());
                    return travelGroupRepository.save(newGroup);
                });

        boolean yaEnGrupo = groupPassengerRepository
                .findByIdGroupAndIdUser(group.getIdGroup(), user.getIdUser()).isPresent();

        if (!yaEnGrupo) {
            GroupPassenger passenger = new GroupPassenger();
            passenger.setIdGroup(group.getIdGroup());
            passenger.setIdUser(user.getIdUser());
            passenger.setState("ACTIVE");
            passenger.setConfirmed(false);
            groupPassengerRepository.save(passenger);
        }

        Payment payment = new Payment();
        payment.setIdGroup(group.getIdGroup());
        payment.setIdUser(user.getIdUser());
        payment.setAmount(amount);
        payment.setPaymentStatus("PENDING");
        payment.setTripType(roundTrip ? "ROUND_TRIP" : "ONE_WAY");
        payment.setCreatedAt(LocalDateTime.now());
        payment.setPaymentType("TRIP_PAYMENT");
        paymentRepository.save(payment);

        double held = user.getHeldBalance() != null ? user.getHeldBalance() : 0.0;
        user.setHeldBalance(held + amount);
        userRepository.save(user);

        route.getPassengers().add(user);
        route.setAvailable_seats(route.getAvailable_seats() - 1);
        routeRepository.save(route);
    }

    @Transactional
    public Map<String, Object> joinRoutes(List<Integer> routeIds, Integer userId, boolean roundTrip) {
        if (routeIds == null || routeIds.isEmpty()) {
            throw new IllegalArgumentException("No se han seleccionado rutas");
        }

        User user = userRepository.findUserByIdUser(userId)
                .orElseThrow(() -> new RuntimeException("El usuario no existe"));

        List<Route> joinable = new ArrayList<>();
        double totalAmount = 0.0;

        for (Integer routeId : routeIds) {
            Route route = routeRepository.findById(routeId).orElse(null);
            if (route == null) continue;
            if ("COMPLETED".equals(route.getStatus())) continue;
            if (route.getIdDriver().equals(userId)) continue;
            if (route.getPassengers().contains(user)) continue;
            if (route.getAvailable_seats() <= 0) continue;
            if (roundTrip && !Boolean.TRUE.equals(route.getAllowRoundTrip())) continue;

            double amount = calculateTripPrice(route, 1);
            if (roundTrip) amount *= 1.9;
            totalAmount += amount;
            joinable.add(route);
        }

        if (joinable.isEmpty()) {
            throw new RuntimeException("No hay rutas disponibles para unirse (puede que ya estés unido o no queden plazas)");
        }

        double balance = user.getBalance() != null ? user.getBalance() : 0.0;
        double held = user.getHeldBalance() != null ? user.getHeldBalance() : 0.0;
        double disponible = balance - held;

        if (disponible < totalAmount) {
            throw new RuntimeException("Saldo insuficiente para unirte a todas las rutas seleccionadas");
        }

        int joinedCount = 0;
        for (Route route : joinable) {
            joinSingleRouteInternal(route, user, roundTrip);
            joinedCount++;
        }

        Map<String, Object> result = new HashMap<>();
        result.put("joined", joinedCount);
        result.put("requested", routeIds.size());
        result.put("totalAmount", Math.round(totalAmount * 100.0) / 100.0);
        return result;
    }


    @Transactional
    public Map<String, Object> joinSeries(Integer routeId, Integer userId, boolean roundTrip) {
        Route route = routeRepository.findById(routeId)
                .orElseThrow(() -> new RouteNotFoundException(routeId));

        String seriesId = route.getSeriesId();
        List<Route> seriesRoutes;
        if (seriesId == null) {
            seriesRoutes = List.of(route);
        } else {
            seriesRoutes = routeRepository.findBySeriesId(seriesId);
        }

        List<Integer> ids = new ArrayList<>();
        for (Route r : seriesRoutes) {
            ids.add(r.getIdRoute());
        }
        return joinRoutes(ids, userId, roundTrip);
    }

    public Map<String, Object> getSeriesInfo(Integer routeId) {
        Route route = routeRepository.findById(routeId)
                .orElseThrow(() -> new RouteNotFoundException(routeId));

        String seriesId = route.getSeriesId();
        List<Route> routes = (seriesId == null) ? List.of(route) : routeRepository.findBySeriesId(seriesId);

        long total = routes.stream()
                .filter(r -> !"COMPLETED".equals(r.getStatus()))
                .count();

        Map<String, Object> m = new HashMap<>();
        m.put("seriesId", seriesId);
        m.put("totalRoutes", total);
        m.put("isSeries", seriesId != null && total > 1);
        return m;
    }

    @Transactional
    public void leaveRoute(Integer routeId, Integer userId) {
        Route route = routeRepository.findById(routeId).orElseThrow(() -> new RuntimeException("La ruta no existe"));
        if("COMPLETED".equals(route.getStatus())) {
            throw new RuntimeException("No puedes abandonar una ruta finalizada");
        }
        User user = userRepository.findUserByIdUser(userId).orElseThrow(() -> new RuntimeException("El usuario no existe"));

        if(route.getIdDriver().equals(userId)) {
            throw new RuntimeException("Eres el conductor, no puedes abandonar la ruta como pasajero. Debes cancelarla entera.");
        }

        if(!route.getPassengers().contains(user)) {
            throw new RuntimeException("No estás unido a esta ruta");
        }
        TravelGroup group = travelGroupRepository.findByIdRoute(routeId).orElseThrow();
        GroupPassenger gp = groupPassengerRepository.findByIdGroupAndIdUser(group.getIdGroup(), userId).orElseThrow();
        List<Payment> payments = paymentRepository.findByGroup(group.getIdGroup());

        for(Payment payment : payments) {
            if(payment.getIdUser().equals(userId)) {
                double held = user.getHeldBalance() != null ? user.getHeldBalance() : 0.0;

                user.setHeldBalance(Math.max(0, held - payment.getAmount()));
                userRepository.save(user);
                payment.setPaymentType("REFUND");
                payment.setPaymentStatus("REFUNDED");
                paymentRepository.save(payment);
            }
        }
        route.getPassengers().remove(user);
        route.setAvailable_seats(route.getAvailable_seats() + 1);
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

        Route route = routeRepository.findById(routeId)
                .orElseThrow(() -> new RouteNotFoundException(routeId));
        if ("COMPLETED".equals(route.getStatus())) {
            throw new RuntimeException("Esta ruta ya está finalizada");
        }
        TravelGroup group = travelGroupRepository.findByIdRoute(routeId)
                .orElseThrow(() -> new RuntimeException("No hay grupo asociado a esta ruta"));

        if (route.getIdDriver().equals(userId)) {
            route.setDriverConfirmed(true);
            routeRepository.save(route);
        } else {
            GroupPassenger gp = groupPassengerRepository
                    .findByIdGroupAndIdUser(group.getIdGroup(), userId)
                    .orElseThrow(() -> new RuntimeException("No eres pasajero de este grupo"));
            gp.setConfirmed(true);
            groupPassengerRepository.save(gp);
        }

        if (checkAllConfirmed(route, group)) {
            settleRoutePayments(route, group);
            route.setStatus("COMPLETED");
            route.setDriverConfirmed(false);
            routeRepository.save(route);
            notificationService.notificarViajeConfirmado(routeId);
        }
    }

    private void settleRoutePayments(Route route, TravelGroup group) {

        List<Payment> payments = paymentRepository.findByGroup(group.getIdGroup());
        int totalPassengers = route.getPassengers().size();
        double totalDriverAmount = 0.0;
        double finalPrice = calculateTripPrice(route, totalPassengers);

        for (Payment payment : payments) {
            if (!"TRIP_PAYMENT".equals(payment.getPaymentType()) || "COMPLETED".equals(payment.getPaymentStatus())) {
                continue;
            }
            User passenger = userRepository.findUserByIdUser(payment.getIdUser()).orElseThrow();
            double paid = Math.round(payment.getAmount() * 100.0) / 100.0;

            double realPrice = Math.round(finalPrice * 100.0) / 100.0;

            if ("ROUND_TRIP".equals(payment.getTripType())) {
                realPrice *= 1.9;
            }

            double difference = Math.round((paid - realPrice) * 100.0) / 100.0;
            double held = passenger.getHeldBalance() != null ? passenger.getHeldBalance() : 0.0;
            double balance = passenger.getBalance() != null ? passenger.getBalance() : 0.0;
            passenger.setHeldBalance(Math.max(0, held - paid));

            double finalBalance = balance - realPrice;

            if (difference > 0) {
                finalBalance += difference;
            }

            passenger.setBalance(finalBalance);
            payment.setAmount(realPrice);
            payment.setPaymentStatus("COMPLETED");
            paymentRepository.save(payment);
            userRepository.save(passenger);

            if (difference > 0) {
                Payment adjustment = new Payment();
                adjustment.setIdUser(passenger.getIdUser());
                adjustment.setIdGroup(group.getIdGroup());
                adjustment.setAmount(difference);
                adjustment.setPaymentStatus("COMPLETED");
                adjustment.setPaymentType("PRICE_ADJUSTMENT");
                adjustment.setCreatedAt(LocalDateTime.now());
                paymentRepository.save(adjustment);
            }
            totalDriverAmount += realPrice;
        }

        User driver = userRepository.findUserByIdUser(route.getIdDriver()).orElseThrow();
        double driverBalance = driver.getBalance() != null ? driver.getBalance() : 0.0;
        driver.setBalance(driverBalance + totalDriverAmount);
        userRepository.save(driver);

        Payment income = new Payment();
        income.setIdUser(driver.getIdUser());
        income.setIdGroup(group.getIdGroup());
        income.setAmount(totalDriverAmount);
        income.setPaymentStatus("COMPLETED");
        income.setPaymentType("TRIP_INCOME");
        income.setCreatedAt(LocalDateTime.now());
        paymentRepository.save(income);
    }

    private boolean checkAllConfirmed(Route route, TravelGroup group) {

        if(!Boolean.TRUE.equals(route.getDriverConfirmed())) {
            return false;
        }
        List<GroupPassenger> passengers = groupPassengerRepository.findByIdGroup(group.getIdGroup());
        for(GroupPassenger p : passengers) {

            if(!p.isConfirmed()) {
                return false;
            }
        }
        return true;
    }

    public double calculatePrice(Integer routeId) {
        Route route = routeRepository.findById(routeId).orElseThrow(() -> new RuntimeException("Ruta no encontrada"));
        return calculateTripPrice(route, 1);
    }

    public List<Map<String, Object>> getSeriesRoutes(Integer routeId) {
        Route route = routeRepository.findById(routeId)
                .orElseThrow(() -> new RouteNotFoundException(routeId));
        String seriesId = route.getSeriesId();
        List<Route> routes = (seriesId == null)
                ? List.of(route)
                : routeRepository.findBySeriesId(seriesId);

        List<Map<String, Object>> result = new ArrayList<>();
        for (Route r : routes) {
            if ("COMPLETED".equals(r.getStatus())) continue;
            Map<String, Object> m = new HashMap<>();
            m.put("idRoute", r.getIdRoute());
            m.put("travel_date", r.getTravel_date() != null ? r.getTravel_date().toString() : null);
            m.put("departure_time", r.getDeparture_time() != null ? r.getDeparture_time().toString() : null);
            m.put("available_seats", r.getAvailable_seats());
            m.put("status", r.getStatus());
            result.add(m);
        }
        result.sort((a, b) -> {
            String dA = (String) a.get("travel_date");
            String dB = (String) b.get("travel_date");
            if (dA == null) return 1;
            if (dB == null) return -1;
            return dA.compareTo(dB);
        });
        return result;
    }
}