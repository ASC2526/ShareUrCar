package com.asc2526.da.unit5.shareurcarbackend.controller;

import com.asc2526.da.unit5.shareurcarbackend.dto.RouteCreateDTO;
import com.asc2526.da.unit5.shareurcarbackend.exception.RouteNotFoundException;
import com.asc2526.da.unit5.shareurcarbackend.model.Route;
import com.asc2526.da.unit5.shareurcarbackend.service.RouteService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/routes")
public class RouteController {
    private final RouteService routeService;

    public RouteController(RouteService routeService) {
        this.routeService = routeService;
    }

    @GetMapping
    public List<Route> getAllRoutes() {
        return routeService.getAllRoutes();
    }

    @GetMapping("/{id}")
    public Route getRouteById(@PathVariable Integer id) {
        return routeService.getRouteById(id);
    }

    @GetMapping("/my-routes/{userId}")
    public List<Map<String,Object>> getMyRoutes(@PathVariable Integer userId) {
        return routeService.getMyRoutes(userId);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public List<Route> createRoute(@Valid @RequestBody RouteCreateDTO dto) {
        return routeService.createRoutes(dto);
    }
    @PutMapping("/{id}")
    public Route updateRoute(@PathVariable Integer id, @Valid @RequestBody Route route) {
        return routeService.updateRoute(id, route);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteRoute(@PathVariable Integer id) {
        routeService.deleteRoute(id);
    }

    @GetMapping("/search")
    public List<Route> searchRoutes(
            @RequestParam Double originLat,
            @RequestParam Double originLng,
            @RequestParam Double destLat,
            @RequestParam Double destLng
    ) {
        return routeService.searchRoutes(originLat, originLng, destLat, destLng);
    }

    @PostMapping("/{routeId}/join/{userId}")
    public ResponseEntity<?> joinRoute(@PathVariable Integer routeId, @PathVariable Integer userId ,
                                       @RequestParam(defaultValue = "false") boolean roundTrip) {
        try {
            routeService.joinRoute(routeId, userId, roundTrip);
            return ResponseEntity.ok().body("Te has unido a la ruta con éxito");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body("error: " + e.getMessage());
        }
    }

    @DeleteMapping("/{routeId}/leave/{userId}")
    public ResponseEntity<?> leaveRoute(@PathVariable Integer routeId, @PathVariable Integer userId) {
        try {
            routeService.leaveRoute(routeId, userId);
            return ResponseEntity.ok().body("Has abandonado la ruta correctamente");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body("error: " + e.getMessage());
        }
    }

    @GetMapping("/completed-count/{userId}")
    public ResponseEntity<?> getCompletedTripsCount(@PathVariable Integer userId) {
        try {
            int count = routeService.getCompletedTripsCount(userId);
            return ResponseEntity.ok(count);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PatchMapping("/{routeId}/complete")
    public ResponseEntity<?> completeRoute(@PathVariable Integer routeId) {
        try {
            routeService.completeRoute(routeId);
            return ResponseEntity.ok().body("Viaje marcado como completado");
        } catch (IllegalStateException e) {
            return ResponseEntity.badRequest().body("Error: " + e.getMessage());
        } catch (RouteNotFoundException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Error: " + e.getMessage());
        }
    }

    @PatchMapping("/{routeId}/confirm/{userId}")
    public ResponseEntity<?> confirmParticipation(@PathVariable Integer routeId, @PathVariable Integer userId) {
        try {
            routeService.confirmParticipation(routeId, userId);
            return ResponseEntity.ok("Confirmación registrada con éxito");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body("Error: " + e.getMessage());
        }
    }

    @GetMapping("/{routeId}/price")
    public ResponseEntity<?> calculatePrice(@PathVariable Integer routeId) {
        double price = routeService.calculatePrice(routeId);
        return ResponseEntity.ok(Map.of("price", price)
        );
    }
}