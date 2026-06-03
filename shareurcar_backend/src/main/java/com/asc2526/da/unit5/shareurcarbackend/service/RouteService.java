package com.asc2526.da.unit5.shareurcarbackend.service;

import com.asc2526.da.unit5.shareurcarbackend.dto.RouteCreateDTO;
import com.asc2526.da.unit5.shareurcarbackend.exception.*;
import com.asc2526.da.unit5.shareurcarbackend.model.*;
import com.asc2526.da.unit5.shareurcarbackend.repository.*;
import com.asc2526.da.unit5.shareurcarbackend.util.RouteMapper;
import org.springframework.transaction.annotation.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

@Service
@RequiredArgsConstructor
public class RouteService {

    private final RouteRepository routeRepository;
    private final DriverRepository driverRepository;
    private final UserRepository userRepository;
    private final TravelGroupRepository travelGroupRepository;
    private final GroupPassengerRepository groupPassengerRepository;
    private final PaymentRepository paymentRepository;
    private final NotificationService notificationService;

    // helpers
    private static double round2(double x) {
        return Math.round(x * 100.0) / 100.0;
    }

    private static double bal(User u) {
        return u.getBalance() != null ? u.getBalance() : 0.0;
    }

    private static double held(User u) {
        return u.getHeldBalance() != null ? u.getHeldBalance() : 0.0;
    }

    public List<Route> getAllRoutes() {
        return routeRepository.findAll();
    }

    public Route getRouteById(Integer id) {
        return routeRepository.findById(id).orElseThrow(() -> new RouteNotFoundException(id));
    }

    public Route updateRoute(Integer id, Route newRoute) {
        Route route = getRouteById(id);
        if (newRoute.getAvailable_seats() <= 0) {
            throw new IllegalArgumentException("Seats inválidos");
        }
        route.setOrigin(newRoute.getOrigin());
        route.setDestination(newRoute.getDestination());
        route.setDeparture_time(newRoute.getDeparture_time());
        route.setArrival_time(newRoute.getArrival_time());
        route.setAvailable_seats(newRoute.getAvailable_seats());
        return routeRepository.save(route);
    }

    // crear rutas
    @Transactional
    public List<Route> createRoutes(RouteCreateDTO dto) {
        if (dto.getIdDriver() == null) {
            throw new IllegalArgumentException("Driver requerido");
        }
        if (!driverRepository.existsByIdDriver(dto.getIdDriver())) {
            throw new UserIsNotDriverException(
                    "Este usuario no está registrado como conductor (falta el coche)");
        }
        if (dto.getAvailable_seats() == null || dto.getAvailable_seats() <= 0) {
            throw new IllegalArgumentException("La cantidad de sitios es inválida");
        }

        Route base = buildRouteFromDto(dto);
        String seriesId = UUID.randomUUID().toString();
        List<Route> saved = new ArrayList<>();

        if ("semanal".equalsIgnoreCase(dto.getFrequency())) {
            if (routeRepository.existsByIdDriverAndDeparture_timeAndTravel_date(
                    dto.getIdDriver(),
                    dto.getDeparture_time(),
                    dto.getTravel_date())) {
                throw new AlreadyExistsException(
                        "Ya tienes una ruta a esa hora en esa fecha");
            }
            List<DayOfWeek> validDays = parseDaysOfWeek(dto.getDays_of_week());
            LocalDate current = dto.getStart_date();
            LocalDate end = dto.getEnd_date();
            while (!current.isAfter(end)) {
                if (validDays.contains(current.getDayOfWeek())) {
                    if (routeRepository.existsByIdDriverAndDeparture_timeAndTravel_date(
                            dto.getIdDriver(),
                            dto.getDeparture_time(),
                            current)) {
                        current = current.plusDays(1);
                        continue;
                    }
                    Route instance = cloneRoute(base);
                    instance.setTravel_date(current);
                    instance.setSeriesId(seriesId);
                    instance.setDriverConfirmed(false);
                    saved.add(routeRepository.save(instance));
                }
                current = current.plusDays(1);
            }
        } else {
            base.setSeriesId(seriesId);
            saved.add(routeRepository.save(base));
        }

        saved.forEach(this::createGroupForRoute);
        return saved;
    }

    private Route buildRouteFromDto(RouteCreateDTO dto) {
        Route r = new Route();
        r.setIdDriver(dto.getIdDriver());
        r.setOrigin(dto.getOrigin());
        r.setDestination(dto.getDestination());
        r.setOriginLat(dto.getOriginLat());
        r.setOriginLng(dto.getOriginLng());
        r.setDestinationLat(dto.getDestinationLat());
        r.setDestinationLng(dto.getDestinationLng());
        r.setDeparture_time(dto.getDeparture_time());
        r.setReturn_time(dto.getReturn_time());
        r.setFrequency(dto.getFrequency());
        r.setDays_of_week(dto.getDays_of_week());
        r.setTravel_date(dto.getTravel_date());
        r.setStart_date(dto.getStart_date());
        r.setEnd_date(dto.getEnd_date());
        r.setAvailable_seats(dto.getAvailable_seats());
        r.setAllowRoundTrip(Boolean.TRUE.equals(dto.getAllowRoundTrip()));
        r.setPrefNoTalk(dto.getPref_no_talk());
        r.setPrefLuggage(dto.getPref_luggage());
        r.setPrefMusic(dto.getPref_music());
        r.setPrefSmoke(dto.getPref_smoke());
        return r;
    }

    private Route cloneRoute(Route src) {
        Route r = new Route();
        r.setIdDriver(src.getIdDriver());
        r.setOrigin(src.getOrigin());
        r.setDestination(src.getDestination());
        r.setOriginLat(src.getOriginLat());
        r.setOriginLng(src.getOriginLng());
        r.setDestinationLat(src.getDestinationLat());
        r.setDestinationLng(src.getDestinationLng());
        r.setDeparture_time(src.getDeparture_time());
        r.setArrival_time(src.getArrival_time());
        r.setReturn_time(src.getReturn_time());
        r.setFrequency(src.getFrequency());
        r.setDays_of_week(src.getDays_of_week());
        r.setStart_date(src.getStart_date());
        r.setEnd_date(src.getEnd_date());
        r.setAvailable_seats(src.getAvailable_seats());
        r.setAllowRoundTrip(src.getAllowRoundTrip());
        r.setPrefNoTalk(src.getPrefNoTalk());
        r.setPrefLuggage(src.getPrefLuggage());
        r.setPrefMusic(src.getPrefMusic());
        r.setPrefSmoke(src.getPrefSmoke());
        return r;
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

    // mis rutas
    public List<Map<String, Object>> getMyRoutes(Integer userId) {
        return routeRepository.findMyRoutes(userId).stream().map(route -> {
            User driver = userRepository.findUserByIdUser(route.getIdDriver()).orElseThrow();
            Integer maxSeats = driverRepository.findByIdDriver(route.getIdDriver())
                    .map(Driver::getMaxSeats).orElse(4);
            String driverName = driver.getFirstname() + " " + driver.getLastname();
            return RouteMapper.toMap(route, driverName, maxSeats);
        }).toList();
    }

    // buscar rutas cercanas
    public List<Map<String, Object>> searchRoutes(Double oLat, Double oLng, Double dLat, Double dLng) {
        return routeRepository.findNearbyRoutes(oLat, oLng, dLat, dLng, 2.5)
                .stream().map(route -> {
                    User driver = userRepository.findUserByIdUser(route.getIdDriver()).orElse(null);
                    Integer maxSeats = driverRepository.findByIdDriver(route.getIdDriver())
                            .map(Driver::getMaxSeats).orElse(4);
                    String driverName = driver != null
                            ? driver.getFirstname() + " " + driver.getLastname() : "Conductor";
                    Map<String, Object> m = RouteMapper.toMap(route, driverName, maxSeats);
                    m.put("priceOneWay", calculateTripPrice(route, 1));
                    return m;
                }).toList();
    }

    // unirse a ruta
    @Transactional
    public void joinRoute(Integer routeId, Integer userId, boolean roundTrip) {
        if (routeId == null || userId == null) {
            throw new IllegalArgumentException("La ruta o el usuario no pueden ser nulos");
        }
        Route route = routeRepository.findById(routeId)
                .orElseThrow(() -> new RuntimeException("La ruta no existe"));
        User user = userRepository.findUserByIdUser(userId)
                .orElseThrow(() -> new RuntimeException("El usuario no existe"));

        if (route.getAvailable_seats() <= 0) throw new NoAvailableSeatsException("Ya no quedan plazas");
        if (route.getIdDriver().equals(userId)) throw new YourOwnRouteException("No puedes unirte a tu propia ruta");
        boolean yaUnido = route.getPassengers().stream()
                .anyMatch(p -> p.getIdUser().equals(userId));
        if (yaUnido) throw new AlreadyExistsException("Ya estás unido a esta ruta");
        if (roundTrip && !Boolean.TRUE.equals(route.getAllowRoundTrip())) {
            throw new RuntimeException("Esta ruta no permite ida y vuelta");
        }

        double amount = priceFor(route, roundTrip);
        if (bal(user) - held(user) < amount) throw new RuntimeException("Saldo insuficiente");

        joinSingleRouteInternal(route, user, roundTrip);
    }

    // unirse a varias rutas
    @Transactional
    public Map<String, Object> joinRoutes(List<Integer> routeIds, Integer userId, boolean roundTrip) {
        if (routeIds == null || routeIds.isEmpty()) throw new IllegalArgumentException("No se han seleccionado rutas");

        User user = userRepository.findUserByIdUser(userId).orElseThrow(() -> new RuntimeException("El usuario no existe"));

        List<Route> joinable = new ArrayList<>();
        double totalAmount = 0.0;

        for (Integer routeId : routeIds) {
            Route route = routeRepository.findById(routeId).orElse(null);
            if (route == null || "COMPLETED".equals(route.getStatus())) continue;
            if (route.getIdDriver().equals(userId)) continue;
            boolean yaUnido = route.getPassengers().stream()
                    .anyMatch(p -> p.getIdUser().equals(userId));
            if (yaUnido) continue;
            if (route.getAvailable_seats() <= 0) continue;
            if (roundTrip && !Boolean.TRUE.equals(route.getAllowRoundTrip())) continue;

            totalAmount += priceFor(route, roundTrip);
            joinable.add(route);
        }

        if (joinable.isEmpty()) throw new RuntimeException("No hay rutas disponibles para unirse");
        if (bal(user) - held(user) < totalAmount) {
            throw new RuntimeException("Saldo insuficiente para unirte a todas las rutas seleccionadas");
        }

        joinable.forEach(r -> joinSingleRouteInternal(r, user, roundTrip));

        return Map.of(
                "joined", joinable.size(),
                "requested", routeIds.size(),
                "totalAmount", round2(totalAmount)
        );
    }

    // unirse a toda la serie
    @Transactional
    public Map<String, Object> joinSeries(Integer routeId, Integer userId, boolean roundTrip) {
        Route route = routeRepository.findById(routeId).orElseThrow(() -> new RouteNotFoundException(routeId));
        String seriesId = route.getSeriesId();
        List<Route> series = seriesId == null ? List.of(route) : routeRepository.findBySeriesId(seriesId);
        List<Integer> ids = series.stream().map(Route::getIdRoute).toList();
        return joinRoutes(ids, userId, roundTrip);
    }

    // abandonar ruta
    @Transactional
    public void leaveRoute(Integer routeId, Integer userId) {
        Route route = routeRepository.findById(routeId)
                .orElseThrow(() -> new RuntimeException("La ruta no existe"));
        if ("COMPLETED".equals(route.getStatus())) throw new RuntimeException("No puedes abandonar una ruta finalizada");

        User user = userRepository.findUserByIdUser(userId)
                .orElseThrow(() -> new RuntimeException("El usuario no existe"));
        if (route.getIdDriver().equals(userId)) throw new RuntimeException("Eres el conductor, debes cancelar la ruta entera");
        boolean estaEnRuta = route.getPassengers().stream()
                .anyMatch(p -> p.getIdUser().equals(userId));
        if (!estaEnRuta) throw new RuntimeException("No estás unido a esta ruta");

        TravelGroup group = travelGroupRepository.findByIdRoute(routeId).orElseThrow();
        GroupPassenger gp = groupPassengerRepository.findByIdGroupAndIdUser(group.getIdGroup(), userId).orElseThrow();

        List<Payment> payments = paymentRepository.findByGroup(group.getIdGroup())
                .stream()
                .filter(p -> p.getIdUser().equals(userId))
                .filter(p -> "TRIP_PAYMENT".equals(p.getPaymentType()))
                .filter(p -> !"CANCELLED".equals(p.getPaymentStatus()))
                .toList();

                payments.forEach(p -> {
                    user.setHeldBalance(round2(Math.max(0, held(user) - p.getAmount())));
                    userRepository.save(user);
                    p.setPaymentStatus("CANCELLED");
                    paymentRepository.save(p);

                    Payment refund = new Payment();
                    refund.setIdUser(userId);
                    refund.setIdGroup(p.getIdGroup());
                    refund.setAmount(p.getAmount());
                    refund.setPaymentStatus("COMPLETED");
                    refund.setPaymentType("REFUND");
                    refund.setCreatedAt(LocalDateTime.now());
                    paymentRepository.save(refund);
            });

        route.getPassengers().removeIf(p -> p.getIdUser().equals(userId));
        route.setAvailable_seats(route.getAvailable_seats() + 1);
        groupPassengerRepository.delete(gp);
        routeRepository.save(route);
    } //

    // eliminar ruta para cuando el conductor cancela
    @Transactional
    public void deleteRoute(Integer id) {
        routeRepository.findById(id).orElseThrow();
        refundPendingPayments(id);
        routeRepository.deleteById(id);
    }

    // devuelve los saldos retenidos y los marca como cancelados
    @Transactional
    public void refundPendingPayments(Integer routeId) {
        TravelGroup group = travelGroupRepository.findByIdRoute(routeId).orElse(null);
        if (group == null) return;

        paymentRepository.findByGroup(group.getIdGroup()).forEach(payment -> {
            if ("COMPLETED".equals(payment.getPaymentStatus())) return;
            userRepository.findUserByIdUser(payment.getIdUser()).ifPresent(passenger -> {
                passenger.setHeldBalance(round2(Math.max(0, held(passenger) - payment.getAmount())));
                passenger.setBalance(round2(bal(passenger) + payment.getAmount()));
                userRepository.save(passenger);
            });
            payment.setPaymentStatus("CANCELLED");
            paymentRepository.save(payment);
        });
    }

    // confirmar participación
    @Transactional
    public void confirmParticipation(Integer routeId, Integer userId) {
        Route route = routeRepository.findById(routeId).orElseThrow(() -> new RouteNotFoundException(routeId));
        if ("COMPLETED".equals(route.getStatus())) throw new RuntimeException("Esta ruta ya está finalizada");

        TravelGroup group = travelGroupRepository.findByIdRoute(routeId)
                .orElseThrow(() -> new RuntimeException("No hay grupo asociado a esta ruta"));

        if (route.getIdDriver().equals(userId)) {
            List<GroupPassenger> pasajeros = groupPassengerRepository.findByIdGroup(group.getIdGroup());
            if (pasajeros.isEmpty()) {
                throw new RuntimeException("No puedes confirmar el viaje si todavía no hay pasajeros.");
            }
            route.setDriverConfirmed(true);
        }

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

    private boolean checkAllConfirmed(Route route, TravelGroup group) {
        if (!Boolean.TRUE.equals(route.getDriverConfirmed())) return false;
        return groupPassengerRepository.findByIdGroup(group.getIdGroup())
                .stream().allMatch(GroupPassenger::isConfirmed);
    }

    private void settleRoutePayments(Route route, TravelGroup group) {
        List<Payment> payments = paymentRepository.findByGroup(group.getIdGroup());
        int totalPassengers = route.getPassengers().size();
        double finalPrice = calculateTripPrice(route, totalPassengers);
        double totalDriverAmount = 0.0;

        for (Payment payment : payments) {
            if (!"TRIP_PAYMENT".equals(payment.getPaymentType())) continue;
            if ("COMPLETED".equals(payment.getPaymentStatus())) continue;

            User passenger = userRepository.findUserByIdUser(payment.getIdUser()).orElseThrow();
            double paid = round2(payment.getAmount());
            double realPrice = round2("ROUND_TRIP".equals(payment.getTripType()) ? finalPrice * 1.9 : finalPrice);
            double difference = round2(paid - realPrice);

            passenger.setHeldBalance(
                    round2(
                            Math.max(0, held(passenger) - paid)
                    )
            );

            passenger.setBalance(round2(bal(passenger) - realPrice + (difference > 0 ? difference : 0)));
            payment.setAmount(realPrice);
            payment.setPaymentStatus("COMPLETED");
            paymentRepository.save(payment);
            userRepository.save(passenger);

            if (difference > 0) {
                Payment adj = new Payment();
                adj.setIdUser(passenger.getIdUser());
                adj.setIdGroup(group.getIdGroup());
                adj.setAmount(difference);
                adj.setPaymentStatus("COMPLETED");
                adj.setPaymentType("PRICE_ADJUSTMENT");
                adj.setCreatedAt(LocalDateTime.now());
                paymentRepository.save(adj);
            }
            totalDriverAmount += realPrice;
        }

        User driver = userRepository.findUserByIdUser(route.getIdDriver()).orElseThrow();
        driver.setBalance(round2(bal(driver) + totalDriverAmount));
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

    // completar ruta manual
    public void completeRoute(Integer routeId) {
        if (routeId == null) throw new IllegalArgumentException("El ID de la ruta no puede ser nulo");
        Route route = routeRepository.findById(routeId).orElseThrow(() -> new RouteNotFoundException(routeId));
        if ("COMPLETED".equals(route.getStatus())) throw new IllegalStateException("El viaje ya está finalizado");
        route.setStatus("COMPLETED");
        routeRepository.save(route);
    }

    @Scheduled(cron = "0 0 * * * *")
    public void autoCompleteOldRoutes() {
        routeRepository.findPendingRoutesWhereArrivalTimePassed(LocalDateTime.now())
                .forEach(r -> { r.setStatus("COMPLETED"); routeRepository.save(r); });
    }

    // viajes completados
    public int getCompletedTripsCount(Integer userId) {
        if (userId == null) throw new IllegalArgumentException("El ID de usuario no puede ser nulo");
        if (!userRepository.existsUserByIdUser(userId)) throw new UserNotFoundException(userId);
        return (int) routeRepository.countCompletedRoutesByDriverId(userId);
    }

    // info de la serie
    public Map<String, Object> getSeriesInfo(Integer routeId) {
        Route route = routeRepository.findById(routeId).orElseThrow(() -> new RouteNotFoundException(routeId));
        String seriesId = route.getSeriesId();
        List<Route> routes = seriesId == null ? List.of(route) : routeRepository.findBySeriesId(seriesId);
        long total = routes.stream().filter(r -> !"COMPLETED".equals(r.getStatus())).count();
        return Map.of("seriesId", seriesId != null ? seriesId : "", "totalRoutes", total, "isSeries", seriesId != null && total > 1);
    }

    public List<Map<String, Object>> getSeriesRoutes(Integer routeId) {
        Route route = routeRepository.findById(routeId).orElseThrow(() -> new RouteNotFoundException(routeId));
        String seriesId = route.getSeriesId();
        List<Route> routes = seriesId == null ? List.of(route) : routeRepository.findBySeriesId(seriesId);

        return routes.stream()
                .filter(r -> !"COMPLETED".equals(r.getStatus()))
                .sorted(Comparator.comparing(r -> r.getTravel_date() != null ? r.getTravel_date().toString() : ""))
                .map(r -> Map.<String, Object>of(
                        "idRoute",         r.getIdRoute(),
                        "travel_date",     r.getTravel_date() != null ? r.getTravel_date().toString() : "",
                        "departure_time",  r.getDeparture_time() != null ? r.getDeparture_time().toString() : "",
                        "available_seats", r.getAvailable_seats(),
                        "status",          r.getStatus()
                )).toList();
    }

    // precio
    public double calculatePrice(Integer routeId) {
        return calculateTripPrice(routeRepository.findById(routeId)
                .orElseThrow(() -> new RuntimeException("Ruta no encontrada")), 1);
    }

    private double priceFor(Route route, boolean roundTrip) {
        double p = calculateTripPrice(route, 1);
        return round2(roundTrip ? p * 1.9 : p);
    }

    private double calculateTripPrice(Route route, int passengers) {
        double km = haversine(route.getOriginLat(), route.getOriginLng(),
                route.getDestinationLat(), route.getDestinationLng());

        // Factor corrector por distancia corta
        if      (km < 3)  km *= 1.80;
        else if (km < 5)  km *= 1.40;
        else if (km < 10) km *= 1.25;
        else              km *= 1.15;

        double[] pcts = {0.425, 0.550, 0.675, 0.80};
        double pct = pcts[Math.min(passengers - 1, 3)];
        double price = (km * 0.40 * pct / passengers) * 1.20;

        double min = km <= 5 ? 1.20 : km <= 9 ? 1.75 : km <= 14 ? 2.00 : 2.50;
        return round2(Math.max(price, min));
    }

    private double haversine(double lat1, double lon1, double lat2, double lon2) {
        final int R = 6371;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }

    private static final Map<String, DayOfWeek> DAY_MAP = Map.of(
            "L", DayOfWeek.MONDAY,   "M", DayOfWeek.TUESDAY,
            "X", DayOfWeek.WEDNESDAY, "J", DayOfWeek.THURSDAY,
            "V", DayOfWeek.FRIDAY,   "S", DayOfWeek.SATURDAY,
            "D", DayOfWeek.SUNDAY
    );

    private List<DayOfWeek> parseDaysOfWeek(String daysStr) {
        if (daysStr == null || daysStr.isBlank()) return List.of();
        return Arrays.stream(daysStr.split(","))
                .map(d -> DAY_MAP.get(d.trim().toUpperCase()))
                .filter(Objects::nonNull)
                .toList();
    }


    // crear grupo + pago para un pasajero nuevo
    private void joinSingleRouteInternal(Route route, User user, boolean roundTrip) {
        double amount = round2(priceFor(route, roundTrip));

        TravelGroup group = travelGroupRepository.findByIdRoute(route.getIdRoute())
                .orElseGet(() -> {
                    TravelGroup g = new TravelGroup();
                    g.setIdRoute(route.getIdRoute());
                    g.setIdDriver(route.getIdDriver());
                    g.setStatus("ACTIVE");
                    g.setTravelDate(route.getTravel_date());
                    g.setTravelTime(route.getDeparture_time());
                    return travelGroupRepository.save(g);
                });

        if (groupPassengerRepository.findByIdGroupAndIdUser(group.getIdGroup(), user.getIdUser()).isEmpty()) {
            GroupPassenger gp = new GroupPassenger();
            gp.setIdGroup(group.getIdGroup());
            gp.setIdUser(user.getIdUser());
            gp.setState("ACTIVE");
            gp.setConfirmed(false);
            groupPassengerRepository.save(gp);
        }

        Payment payment = new Payment();
        payment.setIdGroup(group.getIdGroup());
        payment.setIdUser(user.getIdUser());
        payment.setAmount(round2(amount));
        payment.setPaymentStatus("PENDING");
        payment.setTripType(roundTrip ? "ROUND_TRIP" : "ONE_WAY");
        payment.setCreatedAt(LocalDateTime.now());
        payment.setPaymentType("TRIP_PAYMENT");
        paymentRepository.save(payment);

        user.setHeldBalance(round2(held(user) + amount));
        userRepository.save(user);

        route.getPassengers().add(user);
        route.setAvailable_seats(route.getAvailable_seats() - 1);
        routeRepository.save(route);
    }
}