package com.asc2526.da.unit5.shareurcarbackend.service;

import com.asc2526.da.unit5.shareurcarbackend.exception.TravelGroupNotFoundException;
import com.asc2526.da.unit5.shareurcarbackend.model.TravelGroup;
import com.asc2526.da.unit5.shareurcarbackend.repository.RouteRepository;
import com.asc2526.da.unit5.shareurcarbackend.repository.TravelGroupRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class TravelGroupService {

    private final TravelGroupRepository travelGroupRepository;
    private final RouteRepository routeRepository;

    public TravelGroupService(TravelGroupRepository travelGroupRepository, RouteRepository routeRepository) {
        this.travelGroupRepository = travelGroupRepository;
        this.routeRepository = routeRepository;
    }

    public List<TravelGroup> getAll() {
        return travelGroupRepository.findAll();
    }

    public TravelGroup getById(Integer id) {
        return travelGroupRepository.findById(id)
                .orElseThrow(() -> new TravelGroupNotFoundException(id));
    }

    public TravelGroup create(TravelGroup group) {
        if (!routeRepository.existsById(group.getIdRoute())) {
            throw new RuntimeException("Ruta no existe");
        }
        return travelGroupRepository.save(group);
    }

    public TravelGroup update(Integer id, TravelGroup newGroup) {
        TravelGroup group = getById(id);

        group.setStatus(newGroup.getStatus());
        group.setTravelDate(newGroup.getTravelDate());
        group.setTravelTime(newGroup.getTravelTime());

        return travelGroupRepository.save(group);
    }

    public void delete(Integer id) {
        travelGroupRepository.deleteById(id);
    }

    public Optional<TravelGroup> getByRoute(Integer routeId) {
        return travelGroupRepository.findByIdRoute(routeId);
    }
}