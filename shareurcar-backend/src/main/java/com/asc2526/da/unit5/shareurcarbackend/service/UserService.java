package com.asc2526.da.unit5.shareurcarbackend.service;

import com.asc2526.da.unit5.shareurcarbackend.exception.AlreadyExistsException;
import com.asc2526.da.unit5.shareurcarbackend.exception.UserNotFoundException;
import com.asc2526.da.unit5.shareurcarbackend.model.Review;
import com.asc2526.da.unit5.shareurcarbackend.model.User;
import com.asc2526.da.unit5.shareurcarbackend.repository.ReviewRepository;
import com.asc2526.da.unit5.shareurcarbackend.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final ReviewRepository reviewRepository;

    public UserService(UserRepository userRepository, ReviewRepository reviewRepository) {
        this.userRepository = userRepository;
        this.reviewRepository = reviewRepository;
    }

    public List<User> getAllUsers() {
        return userRepository.findAll();
    }

    public User getUserById(Integer id) {
        if (id == null) throw new IllegalArgumentException("Id no puede ser null");

        return userRepository.findUserByIdUser(id)
                .orElseThrow(() -> new UserNotFoundException(id));
    }

    public User createUser(User user) {

        if (user == null) throw new IllegalArgumentException("User no puede ser null");

        if (userRepository.existsByEmail(user.getEmail())) {
            throw new AlreadyExistsException("Email ya registrado");
        }

        return userRepository.save(user);
    }

    public void deleteUser(Integer id) {
        userRepository.deleteUserByIdUser(id);
    }

    public User updateUser(Integer id, User userDetails) {

        User user = getUserById(id);

        if (!user.getEmail().equals(userDetails.getEmail()) &&
                userRepository.existsByEmail(userDetails.getEmail())) {
            throw new AlreadyExistsException("Email ya en uso");
        }

        user.setFirstname(userDetails.getFirstname());
        user.setLastname(userDetails.getLastname());
        user.setEmail(userDetails.getEmail());
        user.setPassword(userDetails.getPassword());

        return userRepository.save(user);
    }

    public List<Review> getUserReviews(Integer userId) {
        return reviewRepository.findByIdReviewed(userId);
    }
}