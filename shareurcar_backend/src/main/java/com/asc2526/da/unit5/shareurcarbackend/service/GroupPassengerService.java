package com.asc2526.da.unit5.shareurcarbackend.service;

import com.asc2526.da.unit5.shareurcarbackend.model.GroupPassenger;
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

    public GroupPassengerService(GroupPassengerRepository groupPassengerRepository,
                                 TravelGroupRepository travelGroupRepository,
                                 RouteRepository routeRepository) {
        this.groupPassengerRepository = groupPassengerRepository;
        this.travelGroupRepository = travelGroupRepository;
        this.routeRepository = routeRepository;
    }

    public List<GroupPassenger> getAll() {
        return groupPassengerRepository.findAll();
    }

    public GroupPassenger joinGroup(GroupPassenger gp) {
        if (gp.getIdGroup() == null || gp.getIdUser() == null) {
            throw new IllegalArgumentException("Datos incompletos");
        }
        if (!travelGroupRepository.existsById(gp.getIdGroup())) {
            throw new RuntimeException("Grupo no existe");
        }
        if (groupPassengerRepository.findByIdGroupAndIdUser(gp.getIdGroup(), gp.getIdUser()).isPresent()) {
            throw new RuntimeException("Usuario ya está en el grupo");
        }
        gp.setState("pendiente");
        return groupPassengerRepository.save(gp);
    }

    public GroupPassenger updateState(Integer id, String state) {
        if (id == null || state == null) throw new IllegalArgumentException("Datos incompletos");

        GroupPassenger gp = groupPassengerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("No encontrado: " + id));

        // si se rechaza a alguien que estaba aceptado, devolvemos su plaza
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
        return groupPassengerRepository.findByIdGroup(groupId);
    }

    public List<GroupPassenger> getByUser(Integer userId) {
        return groupPassengerRepository.findByIdUser(userId);
    }
}