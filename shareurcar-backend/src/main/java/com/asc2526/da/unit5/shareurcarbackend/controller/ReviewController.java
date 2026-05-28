package com.asc2526.da.unit5.shareurcarbackend.controller;

import com.asc2526.da.unit5.shareurcarbackend.service.ReviewService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/users")
public class ReviewController {

    private final ReviewService reviewService;

    public ReviewController(ReviewService reviewService) {
        this.reviewService = reviewService;
    }

    @PostMapping("/{idTarget}/reviews")
    public ResponseEntity<?> addReview(@PathVariable Integer idTarget, @RequestBody Map<String, Object> reviewData) {
        reviewService.createReview(idTarget, reviewData);
        return ResponseEntity.ok().build();
    }
}