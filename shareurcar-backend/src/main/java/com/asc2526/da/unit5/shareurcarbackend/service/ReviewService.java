package com.asc2526.da.unit5.shareurcarbackend.service;

import com.asc2526.da.unit5.shareurcarbackend.model.Review;
import com.asc2526.da.unit5.shareurcarbackend.model.User;
import com.asc2526.da.unit5.shareurcarbackend.repository.ReviewRepository;
import com.asc2526.da.unit5.shareurcarbackend.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class ReviewService {

    private final ReviewRepository reviewRepository;
    private final UserRepository userRepository;

    public ReviewService(ReviewRepository reviewRepository, UserRepository userRepository) {
        this.reviewRepository = reviewRepository;
        this.userRepository = userRepository;
    }

    public Review createReview(Integer idReviewed, Map<String, Object> reviewData) {
        Integer idReviewer = (Integer) reviewData.get("idReviewer");
        Integer stars = (Integer) reviewData.get("stars");
        String comment = (String) reviewData.get("comment");

        User reviewer = userRepository.findUserByIdUser(idReviewer)
                .orElseThrow(() -> new RuntimeException("El usuario que escribe la reseña no existe"));

        Review review = new Review();
        review.setReviewer(reviewer);
        review.setIdReviewed(idReviewed);
        review.setStars(stars);
        review.setComment(comment);

        Review savedReview = reviewRepository.save(review);

        User reviewedUser = userRepository.findUserByIdUser(idReviewed)
                .orElseThrow(() -> new RuntimeException("El usuario valorado no existe"));

        List<Review> userReviews = reviewRepository.findByIdReviewed(idReviewed);

        double totalStars = 0;
        for (Review r : userReviews) {
            totalStars += r.getStars();
        }
        double average = totalStars / userReviews.size();

        reviewedUser.setRating(average);
        userRepository.save(reviewedUser);

        return savedReview;
    }
}