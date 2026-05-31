package com.asc2526.da.unit5.shareurcarbackend.controller;

import com.asc2526.da.unit5.shareurcarbackend.model.TravelGroup;
import com.asc2526.da.unit5.shareurcarbackend.service.TravelGroupService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/travel-groups")
public class TravelGroupController {

    private final TravelGroupService service;

    public TravelGroupController(TravelGroupService service) {
        this.service = service;
    }

    @GetMapping
    public List<TravelGroup> getAll() {
        return service.getAll();
    }

    @GetMapping("/{id}")
    public TravelGroup getById(@PathVariable Integer id) {
        return service.getById(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public TravelGroup create(@Valid @RequestBody TravelGroup group) {
        return service.create(group);
    }

    @PutMapping("/{id}")
    public TravelGroup update(@PathVariable Integer id, @Valid @RequestBody TravelGroup group) {
        return service.update(id, group);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Integer id) {
        service.delete(id);
    }

    @GetMapping("/route/{routeId}")
    public Optional<TravelGroup> getByRoute(@PathVariable Integer routeId) {
        return service.getByRoute(routeId);
    }
}