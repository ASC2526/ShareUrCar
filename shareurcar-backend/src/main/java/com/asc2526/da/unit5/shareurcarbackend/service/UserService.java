package com.asc2526.da.unit5.shareurcarbackend.service;

import com.asc2526.da.unit5.shareurcarbackend.exception.AlreadyExistsException;
import com.asc2526.da.unit5.shareurcarbackend.exception.UserNotFoundException;
import com.asc2526.da.unit5.shareurcarbackend.model.Review;
import com.asc2526.da.unit5.shareurcarbackend.model.User;
import com.asc2526.da.unit5.shareurcarbackend.repository.ReviewRepository;
import com.asc2526.da.unit5.shareurcarbackend.repository.UserRepository;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

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

    @Transactional
    public User updateUser(Integer id, Map<String, Object> updates) {
        if (updates == null || updates.isEmpty()) {
            throw new IllegalArgumentException("No se enviaron datos para actualizar");
        }

        User user = userRepository.findUserByIdUser(id)
                .orElseThrow(() -> new UserNotFoundException(id));

        if (updates.containsKey("firstname")) {
            String fn = (String) updates.get("firstname");
            if (fn == null || fn.isEmpty())
                throw new IllegalArgumentException("El nombre no puede estar vacío");
            user.setFirstname(fn);
        }

        if (updates.containsKey("lastname")) user.setLastname((String) updates.get("lastname"));

        if (updates.containsKey("email")) {
            String newEmail = (String) updates.get("email");
            if (newEmail == null || newEmail.isEmpty())
                throw new IllegalArgumentException("El email es obligatorio");
            if (!user.getEmail().equals(newEmail) && userRepository.existsByEmail(newEmail)) {
                throw new AlreadyExistsException("Email ya en uso");
            }
            user.setEmail(newEmail);
        }

        if (updates.containsKey("phone"))
            user.setPhone((String) updates.get("phone"));
        if (updates.containsKey("aboutMe"))
            user.setAboutMe((String) updates.get("aboutMe"));
        if (updates.containsKey("profile_photo"))
            user.setProfile_photo((String) updates.get("profile_photo"));

        return userRepository.save(user);
    }

    public List<Review> getUserReviews(Integer userId) {
        return reviewRepository.findByIdReviewed(userId);
    }
}