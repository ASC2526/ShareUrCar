package com.asc2526.da.unit5.shareurcarbackend.service;

import com.asc2526.da.unit5.shareurcarbackend.exception.AlreadyExistsException;
import com.asc2526.da.unit5.shareurcarbackend.exception.UserNotFoundException;
import com.asc2526.da.unit5.shareurcarbackend.model.Driver;
import com.asc2526.da.unit5.shareurcarbackend.model.Review;
import com.asc2526.da.unit5.shareurcarbackend.model.User;
import com.asc2526.da.unit5.shareurcarbackend.repository.DriverRepository;
import com.asc2526.da.unit5.shareurcarbackend.repository.ReviewRepository;
import com.asc2526.da.unit5.shareurcarbackend.repository.UserRepository;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final ReviewRepository reviewRepository;
    private final DriverRepository driverRepository;

    public UserService(UserRepository userRepository, ReviewRepository reviewRepository, DriverRepository driverRepository) {
        this.userRepository = userRepository;
        this.reviewRepository = reviewRepository;
        this.driverRepository = driverRepository;
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
        User user = userRepository.findUserByIdUser(id).orElseThrow(() -> new UserNotFoundException(id));
        if (updates.containsKey("firstname")) {
            String fn = (String) updates.get("firstname");
            if (fn == null || fn.isEmpty())
                throw new IllegalArgumentException("El nombre no puede estar vacío");
            user.setFirstname(fn);
        }
        if (updates.containsKey("lastname")) {
            user.setLastname((String) updates.get("lastname"));
        }

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

        if (updates.containsKey("driver") && updates.get("driver") != null) {
            Map<String, Object> driverData = (Map<String, Object>) updates.get("driver");

            String newCarPlate = (String) driverData.get("carPlate");
            String newCarModel = (String) driverData.get("carModel");
            String newCarColor = (String) driverData.get("carColor");
            Integer newMaxSeats = driverData.get("maxSeats") != null ? (Integer) driverData.get("maxSeats") : null;

            Optional<Driver> existingDriverOpt = driverRepository.findByIdDriver(id);

            if (existingDriverOpt.isPresent()) {
                Driver existingDriver = existingDriverOpt.get();

                if (existingDriver.getCarPlate().equals(newCarPlate)) {
                    if (newCarModel != null) existingDriver.setCarModel(newCarModel);
                    if (newCarColor != null) existingDriver.setCarColor(newCarColor);
                    if (newMaxSeats != null) existingDriver.setMaxSeats(newMaxSeats);

                    driverRepository.save(existingDriver);
                }
                else {
                    driverRepository.delete(existingDriver);
                    driverRepository.flush();

                    Driver newDriver = new Driver();
                    newDriver.setCarPlate(newCarPlate);
                    newDriver.setIdDriver(id);
                    newDriver.setCarModel(newCarModel);
                    newDriver.setCarColor(newCarColor);
                    if (newMaxSeats != null) newDriver.setMaxSeats(newMaxSeats);

                    driverRepository.save(newDriver);
                }
            } else {
                Driver newDriver = new Driver();
                newDriver.setCarPlate(newCarPlate);
                newDriver.setIdDriver(id);
                newDriver.setCarModel(newCarModel);
                newDriver.setCarColor(newCarColor);
                if (newMaxSeats != null) newDriver.setMaxSeats(newMaxSeats);

                driverRepository.save(newDriver);
            }
        }
        return userRepository.save(user);
    }

    public List<Review> getUserReviews(Integer userId) {
        return reviewRepository.findByIdReviewed(userId);
    }

    @Transactional
    public User updateBalance(Integer userId, Double amount) {

        User user = userRepository.findUserByIdUser(userId).orElseThrow(() -> new RuntimeException("Usuario no encontrado"));

        double balance = user.getBalance() != null ? user.getBalance() : 0.0;
        double held = user.getHeldBalance() != null ? user.getHeldBalance() : 0.0;
        double available = balance - held;

        if(amount < 0) {
            double retirada = Math.abs(amount);
            if(retirada > available) {
                throw new RuntimeException("No tienes saldo suficiente");
            }
        }
        user.setBalance(balance + amount);
        return userRepository.save(user);
    }
}