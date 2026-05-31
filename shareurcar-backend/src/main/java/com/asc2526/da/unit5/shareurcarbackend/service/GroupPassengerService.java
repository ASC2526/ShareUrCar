package com.asc2526.da.unit5.shareurcarbackend.service;

import com.asc2526.da.unit5.shareurcarbackend.model.GroupPassenger;
import com.asc2526.da.unit5.shareurcarbackend.model.Payment;
import com.asc2526.da.unit5.shareurcarbackend.model.Route;
import com.asc2526.da.unit5.shareurcarbackend.model.TravelGroup;
import com.asc2526.da.unit5.shareurcarbackend.repository.GroupPassengerRepository;
import com.asc2526.da.unit5.shareurcarbackend.repository.RouteRepository;
import com.asc2526.da.unit5.shareurcarbackend.repository.TravelGroupRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class GroupPassengerService {

    private final GroupPassengerRepository groupPassengerRepository;
    private final TravelGroupRepository travelGroupRepository;
    private final RouteRepository routeRepository;
    private final PaymentService paymentService;

    public GroupPassengerService(GroupPassengerRepository repository, TravelGroupRepository travelGroupRepository, RouteRepository routeRepository, PaymentService paymentService) {
        this.groupPassengerRepository = repository;
        this.travelGroupRepository = travelGroupRepository;
        this.routeRepository = routeRepository;
        this.paymentService = paymentService;
    }

    public List<GroupPassenger> getAll() {
        return groupPassengerRepository.findAll();
    }

    public GroupPassenger getById(Integer id) {
        return groupPassengerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("No encontrado: " + id));
    }

    public GroupPassenger joinGroup(GroupPassenger gp) {
        if (gp.getIdGroup() == null || gp.getIdUser() == null) {
            throw new IllegalArgumentException("Datos incompletos");
        }

        if (!travelGroupRepository.existsById(gp.getIdGroup())) {
            throw new RuntimeException("Grupo no existe");
        }

        if (groupPassengerRepository.existsByGroupAndUser(gp.getIdGroup(), gp.getIdUser())) {
            throw new RuntimeException("Usuario ya está en el grupo");
        }

        gp.setState("pendiente");

        return groupPassengerRepository.save(gp);
    }

    public GroupPassenger updateState(Integer id, String state) {
        if (id == null || state == null) {
            throw new IllegalArgumentException("Datos incompletos");
        }
        GroupPassenger gp = getById(id);

        if (state.equalsIgnoreCase("aceptado") && !gp.getState().equalsIgnoreCase("aceptado")) {

            TravelGroup group = travelGroupRepository.findById(gp.getIdGroup())
                    .orElseThrow(() -> new RuntimeException("Grupo no encontrado"));

            Route route = routeRepository.findById(group.getIdRoute())
                    .orElseThrow(() -> new RuntimeException("Ruta no encontrada"));

            // Validamos asientos
            if (route.getAvailable_seats() <= 0) {
                throw new RuntimeException("No quedan plazas disponibles en este viaje");
            }

            // Restamos el asiento
            route.setAvailable_seats(route.getAvailable_seats() - 1);
            routeRepository.save(route);

            // Automatizamos el pago (generamos un recibo pendiente)
            Payment payment = new Payment();
            payment.setIdGroup(gp.getIdGroup());
            payment.setIdUser(gp.getIdUser());
            payment.setAmount(5.00);
            paymentService.create(payment);
        }

        if (!state.equalsIgnoreCase("aceptado") && gp.getState().equalsIgnoreCase("aceptado")) {
            TravelGroup group = travelGroupRepository.findById(gp.getIdGroup()).orElseThrow();
            Route route = routeRepository.findById(group.getIdRoute()).orElseThrow();
            route.setAvailable_seats(route.getAvailable_seats() + 1);
            routeRepository.save(route);
        }

        gp.setState(state);
        return groupPassengerRepository.save(gp);
    }

    public void delete(Integer id) {
        groupPassengerRepository.deleteById(id);
    }

    public List<GroupPassenger> getByGroup(Integer groupId) {
        return groupPassengerRepository.findByGroupId(groupId);
    }

    public List<GroupPassenger> getByUser(Integer userId) {
        return groupPassengerRepository.findByUserId(userId);
    }
}