package com.asc2526.da.unit5.shareurcarbackend.controller;

import com.asc2526.da.unit5.shareurcarbackend.model.Review;
import com.asc2526.da.unit5.shareurcarbackend.model.User;
import com.asc2526.da.unit5.shareurcarbackend.service.DriverService;
import com.asc2526.da.unit5.shareurcarbackend.service.UserService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/users")
public class UserController {

    private final UserService userService;
    private final DriverService driverService;

    public UserController(UserService userService, DriverService driverService) {
        this.userService = userService;
        this.driverService = driverService;
    }

    @GetMapping
    public List<User> getAllUsers() {
        return userService.getAllUsers();
    }

    @GetMapping("/{id}")
    public User getUserById(@PathVariable Integer id) {
        return userService.getUserById(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public User createUser(@Valid @RequestBody User user) {
        return userService.createUser(user);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteUser(@PathVariable Integer id) {
        userService.deleteUser(id);
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateProfile(@PathVariable Integer id, @RequestBody Map<String, Object> updates) {
        User updatedUser = userService.updateUser(id, updates);

        if (updates.containsKey("carModel") || updates.containsKey("carColor") || updates.containsKey("carPlate")) {
            driverService.updateDriver(id, updates);
        }

        return ResponseEntity.ok(updatedUser);
    }

    @GetMapping("/{id}/reviews")
    public List<Review> getUserReviews(@PathVariable Integer id) {
        return userService.getUserReviews(id);
    }

    @PatchMapping("/{userId}/balance")
    public User updateBalance(@PathVariable Integer userId, @RequestParam Double amount) {
        return userService.updateBalance(userId, amount);
    }
}