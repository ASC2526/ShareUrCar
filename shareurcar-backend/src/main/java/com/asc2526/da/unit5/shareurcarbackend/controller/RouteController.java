package com.asc2526.da.unit5.shareurcarbackend.controller;

import com.asc2526.da.unit5.shareurcarbackend.model.Route;
import com.asc2526.da.unit5.shareurcarbackend.service.RouteService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/routes")
public class RouteController {
    private final RouteService routeService;

    public RouteController(RouteService routeService) {
        this.routeService = routeService;
    }

    // GET ALL
    @GetMapping
    public List<Route> getAllRoutes() {
        return routeService.getAllRoutes();
    }

    // GET BY ID
    @GetMapping("/{id}")
    public Route getRouteById(@PathVariable Integer id) {
        return routeService.getRouteById(id);
    }

    // POST
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Route createRoute(@Valid @RequestBody Route route) {
        return routeService.createRoute(route);
    }

    // PUT
    @PutMapping("/{id}")
    public Route updateRoute(@PathVariable Integer id, @Valid @RequestBody Route route) {
        return routeService.updateRoute(id, route);
    }

    // DELETE
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteRoute(@PathVariable Integer id) {
        routeService.deleteRoute(id);
    }

    // SEARCH
    @GetMapping("/search")
    public List<Route> searchRoutes(
            @RequestParam Double originLat,
            @RequestParam Double originLng,
            @RequestParam Double destLat,
            @RequestParam Double destLng
    ) {
        return routeService.searchRoutes(originLat, originLng, destLat, destLng);
    }
}