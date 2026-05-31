package com.asc2526.da.unit5.shareurcarbackend.service;

import com.asc2526.da.unit5.shareurcarbackend.exception.AlreadyExistsException;
import com.asc2526.da.unit5.shareurcarbackend.exception.UserNotFoundException;
import com.asc2526.da.unit5.shareurcarbackend.model.Driver;
import com.asc2526.da.unit5.shareurcarbackend.model.Payment;
import com.asc2526.da.unit5.shareurcarbackend.model.Review;
import com.asc2526.da.unit5.shareurcarbackend.model.User;
import com.asc2526.da.unit5.shareurcarbackend.repository.DriverRepository;
import com.asc2526.da.unit5.shareurcarbackend.repository.PaymentRepository;
import com.asc2526.da.unit5.shareurcarbackend.repository.ReviewRepository;
import com.asc2526.da.unit5.shareurcarbackend.repository.UserRepository;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final ReviewRepository reviewRepository;
    private final DriverRepository driverRepository;
    private final PaymentRepository paymentRepository;

    public UserService(UserRepository userRepository, ReviewRepository reviewRepository, DriverRepository driverRepository, PaymentRepository paymentRepository) {
        this.userRepository = userRepository;
        this.reviewRepository = reviewRepository;
        this.driverRepository = driverRepository;
        this.paymentRepository = paymentRepository;
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
        if (Math.abs(amount) < 5) {
            throw new RuntimeException("La cantidad mínima es 5 €");
        }

        if (Math.abs(amount) > 500) {
            throw new RuntimeException("La cantidad máxima es 500 €");
        }

        Payment payment = new Payment();
        payment.setIdUser(userId);
        payment.setAmount(Math.abs(amount));
        payment.setPaymentStatus("COMPLETED");
        payment.setCreatedAt(LocalDateTime.now());

        if(amount > 0) {
            payment.setPaymentType("DEPOSIT");
        } else {
            payment.setPaymentType("WITHDRAW");
        }

        paymentRepository.save(payment);
        user.setBalance(balance + amount);
        return userRepository.save(user);
    }

    @Transactional
    public User updateUser(Integer id, Map<String, Object> updates) {
        if (updates == null || updates.isEmpty()) {
            throw new IllegalArgumentException("No se enviaron datos para actualizar");
        }
        User user = userRepository.findUserByIdUser(id).orElseThrow(() -> new UserNotFoundException(id));
        updateFirstname(user, updates);
        updateLastname(user, updates);
        updateEmail(user, updates);
        updatePhone(user, updates);
        updateAboutMe(user, updates);
        updateProfilePhoto(user, updates);
        updateDriverData(id, updates);
        return userRepository.save(user);
    }

    private void updateDriverData(Integer id, Map<String, Object> updates) {
        String newCarPlate = (String) updates.get("carPlate");
        String newCarModel = (String) updates.get("carModel");
        String newCarColor = (String) updates.get("carColor");
        Integer newMaxSeats = null;
        if (updates.get("maxSeats") != null) {
            newMaxSeats = (Integer) updates.get("maxSeats");
        }
        Optional<Driver> existingDriverOpt = driverRepository.findByIdDriver(id);
        if (existingDriverOpt.isEmpty()) {
            return;
        }
        Driver existingDriver = existingDriverOpt.get();
        if (newCarPlate != null && !newCarPlate.isBlank()) {
            newCarPlate = newCarPlate.toUpperCase().replace(" ", "");
            if (!newCarPlate.matches("\\d{4}[A-Z]{3}")) {
                throw new IllegalArgumentException("La matrícula debe tener formato 1234ABC");
            }
        }
        if (newCarModel != null && !newCarModel.isBlank() && newCarModel.length() < 2) {
            throw new IllegalArgumentException("El modelo es demasiado corto");
        }
        if (newCarColor != null && !newCarColor.isBlank() && newCarColor.length() < 3) {
            throw new IllegalArgumentException("Introduce un color válido");
        }
        if (newMaxSeats != null && newMaxSeats < 1) {
            throw new IllegalArgumentException("Las plazas deben ser mayores que 0");
        }

        if (newCarPlate != null && !newCarPlate.isBlank() && !existingDriver.getCarPlate().equals(newCarPlate)) {

            if (driverRepository.existsByCarPlate(newCarPlate)) {
                throw new AlreadyExistsException("Ya existe un vehículo con esa matrícula");
            }
            driverRepository.delete(existingDriver);
            driverRepository.flush();
            Driver newDriver = new Driver();
            newDriver.setCarPlate(newCarPlate);
            newDriver.setIdDriver(id);
            newDriver.setCarModel(newCarModel != null ? newCarModel : existingDriver.getCarModel());
            newDriver.setCarColor(newCarColor != null ? newCarColor : existingDriver.getCarColor());
            newDriver.setMaxSeats(newMaxSeats != null ? newMaxSeats : existingDriver.getMaxSeats());
            driverRepository.save(newDriver);
            return;
        }
        if (newCarModel != null && !newCarModel.isBlank()) {
            existingDriver.setCarModel(newCarModel);
        }
        if (newCarColor != null && !newCarColor.isBlank()) {
            existingDriver.setCarColor(newCarColor);
        }
        if (newMaxSeats != null) {
            existingDriver.setMaxSeats(newMaxSeats);
        }
        driverRepository.save(existingDriver);
    }

    private void updateFirstname(User user, Map<String, Object> updates) {
        if (!updates.containsKey("firstname")) {
            return;
        }
        String fn = (String) updates.get("firstname");
        if (fn == null || fn.isBlank()) {
            throw new IllegalArgumentException("El nombre no puede estar vacío");
        }
        user.setFirstname(fn);
    }

    private void updateLastname(User user, Map<String, Object> updates) {
        if (updates.containsKey("lastname")) {
            user.setLastname((String) updates.get("lastname"));
        }
    }

    private void updateEmail(User user, Map<String, Object> updates) {
        if (!updates.containsKey("email")) {
            return;
        }
        String newEmail = (String) updates.get("email");
        if (newEmail == null || newEmail.isBlank()) {
            throw new IllegalArgumentException("El email es obligatorio");
        }

        if (!user.getEmail().equals(newEmail) && userRepository.existsByEmail(newEmail)) {
            throw new AlreadyExistsException("Email ya en uso");
        }
        user.setEmail(newEmail);
    }

    private void updatePhone(User user, Map<String, Object> updates) {
        if (!updates.containsKey("phone")) {
            return;
        }
        String phone = (String) updates.get("phone");
        if (phone != null && !phone.isBlank() && !phone.matches("\\d{9}")) {
            throw new IllegalArgumentException("El teléfono debe tener 9 dígitos");
        }
        user.setPhone(phone);
    }

    private void updateAboutMe(User user, Map<String, Object> updates) {
        if (updates.containsKey("aboutMe")) {
            user.setAboutMe((String) updates.get("aboutMe"));
        }
    }

    private void updateProfilePhoto(User user, Map<String, Object> updates) {
        if (updates.containsKey("profile_photo")) {
            user.setProfile_photo((String) updates.get("profile_photo"));
        }
    }
}