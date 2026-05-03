package com.asc2526.da.unit5.shareurcarbackend.controller;

import com.asc2526.da.unit5.shareurcarbackend.model.TravelGroup;
import com.asc2526.da.unit5.shareurcarbackend.service.TravelGroupService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/travel-groups")
public class TravelGroupController {

    private final TravelGroupService service;

    public TravelGroupController(TravelGroupService service) {
        this.service = service;
    }

    // GET ALL
    @GetMapping
    public List<TravelGroup> getAll() {
        return service.getAll();
    }

    // GET BY ID
    @GetMapping("/{id}")
    public TravelGroup getById(@PathVariable Integer id) {
        return service.getById(id);
    }

    // POST
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public TravelGroup create(@Valid @RequestBody TravelGroup group) {
        return service.create(group);
    }

    // PUT
    @PutMapping("/{id}")
    public TravelGroup update(@PathVariable Integer id, @Valid @RequestBody TravelGroup group) {
        return service.update(id, group);
    }

    // DELETE
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Integer id) {
        service.delete(id);
    }

    // GET BY ROUTE
    @GetMapping("/route/{routeId}")
    public List<TravelGroup> getByRoute(@PathVariable Integer routeId) {
        return service.getByRoute(routeId);
    }
}