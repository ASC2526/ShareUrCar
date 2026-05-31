package com.asc2526.da.unit5.shareurcarbackend.controller;

import com.asc2526.da.unit5.shareurcarbackend.model.Payment;
import com.asc2526.da.unit5.shareurcarbackend.service.PaymentService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/payments")
public class PaymentController {

    private final PaymentService service;

    public PaymentController(PaymentService service) {
        this.service = service;
    }

    @GetMapping("/group/{groupId}")
    public List<Payment> getByGroup(@PathVariable Integer groupId) {
        return service.getByGroup(groupId);
    }

    @GetMapping("/user/{userId}")
    public List<Payment> getByUser(@PathVariable Integer userId) {
        return service.getByUser(userId);
    }
}