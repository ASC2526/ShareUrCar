package com.asc2526.da.unit5.shareurcarbackend.controller;

import com.asc2526.da.unit5.shareurcarbackend.model.GroupPassenger;
import com.asc2526.da.unit5.shareurcarbackend.service.GroupPassengerService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/group-passengers")
public class GroupPassengerController {

    private final GroupPassengerService service;

    public GroupPassengerController(GroupPassengerService service) {
        this.service = service;
    }

    @GetMapping
    public List<GroupPassenger> getAll() {
        return service.getAll();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public GroupPassenger joinGroup(@Valid @RequestBody GroupPassenger gp) {
        return service.joinGroup(gp);
    }


    @PutMapping("/{id}")
    public GroupPassenger updateState(@PathVariable Integer id, @RequestParam String state) {
        return service.updateState(id, state);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Integer id) {
        service.delete(id);
    }

    @GetMapping("/group/{groupId}")
    public List<GroupPassenger> getByGroup(@PathVariable Integer groupId) {
        return service.getByGroup(groupId);
    }

    @GetMapping("/user/{userId}")
    public List<GroupPassenger> getByUser(@PathVariable Integer userId) {
        return service.getByUser(userId);
    }
}