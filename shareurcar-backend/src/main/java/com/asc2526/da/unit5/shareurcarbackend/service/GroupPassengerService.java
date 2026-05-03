package com.asc2526.da.unit5.shareurcarbackend.service;

import com.asc2526.da.unit5.shareurcarbackend.model.GroupPassenger;
import com.asc2526.da.unit5.shareurcarbackend.repository.GroupPassengerRepository;
import com.asc2526.da.unit5.shareurcarbackend.repository.TravelGroupRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class GroupPassengerService {

    private final GroupPassengerRepository groupPassengerRepository;
    private final TravelGroupRepository travelGroupRepository;

    public GroupPassengerService(GroupPassengerRepository repository, TravelGroupRepository travelGroupRepository) {
        this.groupPassengerRepository = repository;
        this.travelGroupRepository = travelGroupRepository;
    }

    public List<GroupPassenger> getAll() {
        return groupPassengerRepository.findAll();
    }

    public GroupPassenger getById(Integer id) {
        return groupPassengerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("No encontrado: " + id));
    }

    public GroupPassenger joinGroup(GroupPassenger gp) {

        if (groupPassengerRepository.existsByGroupAndUser(gp.getIdGroup(), gp.getIdUser())) {
            throw new RuntimeException("Usuario ya está en el grupo");
        }

        if (!travelGroupRepository.existsById(gp.getIdGroup())) {
            throw new RuntimeException("Grupo no existe");
        }

        if (gp.getIdGroup() == null || gp.getIdUser() == null) {
            throw new IllegalArgumentException("Datos incompletos");
        }

        gp.setState("pendiente");

        return groupPassengerRepository.save(gp);
    }

    public GroupPassenger updateState(Integer id, String state) {
        if (id == null || state == null)
        {
            throw new IllegalArgumentException("Datos incompletos");
        }
        GroupPassenger gp = getById(id);
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