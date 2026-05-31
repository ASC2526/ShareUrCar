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

    private static double bal(User u)  { return u.getBalance()     != null ? u.getBalance()     : 0.0; }
    private static double held(User u) { return u.getHeldBalance() != null ? u.getHeldBalance() : 0.0; }


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

    // reseñas
    public List<Review> getUserReviews(Integer userId) {
        return reviewRepository.findByIdReviewed(userId);
    }

    // saldo
    @Transactional
    public User updateBalance(Integer userId, Double amount) {
        User user = userRepository.findUserByIdUser(userId)
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));

        if (Math.abs(amount) < 5)   throw new RuntimeException("La cantidad mínima es 5 €");
        if (Math.abs(amount) > 500) throw new RuntimeException("La cantidad máxima es 500 €");
        if (amount < 0 && Math.abs(amount) > (bal(user) - held(user))) {
            throw new RuntimeException("No tienes saldo suficiente");
        }

        Payment payment = new Payment();
        payment.setIdUser(userId);
        payment.setAmount(Math.abs(amount));
        payment.setPaymentStatus("COMPLETED");
        payment.setCreatedAt(LocalDateTime.now());
        payment.setPaymentType(amount > 0 ? "DEPOSIT" : "WITHDRAW");
        paymentRepository.save(payment);

        user.setBalance(bal(user) + amount);
        return userRepository.save(user);
    }

    // actualizar perfil
    @Transactional
    public User updateUser(Integer id, Map<String, Object> updates) {
        if (updates == null || updates.isEmpty()) {
            throw new IllegalArgumentException("No se enviaron datos para actualizar");
        }
        User user = userRepository.findUserByIdUser(id).orElseThrow(() -> new UserNotFoundException(id));

        applyStringField(updates, "firstname", val -> {
            if (val.isBlank()) throw new IllegalArgumentException("El nombre no puede estar vacío");
            user.setFirstname(val);
        });
        applyStringField(updates, "lastname", user::setLastname);
        applyStringField(updates, "email", val -> {
            if (val.isBlank()) throw new IllegalArgumentException("El email es obligatorio");
            if (!user.getEmail().equals(val) && userRepository.existsByEmail(val)) {
                throw new AlreadyExistsException("Email ya en uso");
            }
            user.setEmail(val);
        });
        applyStringField(updates, "phone", val -> {
            if (!val.isBlank() && !val.matches("\\d{9}")) {
                throw new IllegalArgumentException("El teléfono debe tener 9 dígitos");
            }
            user.setPhone(val);
        });
        applyStringField(updates, "aboutMe", user::setAboutMe);
        applyStringField(updates, "profile_photo", user::setProfile_photo);

        updateDriverData(id, updates);
        return userRepository.save(user);
    }

    private void applyStringField(Map<String, Object> updates, String key,
                                  java.util.function.Consumer<String> setter) {
        if (updates.containsKey(key)) {
            setter.accept((String) updates.get(key));
        }
    }

    // subir foto perfil
    @Transactional
    public User updatePhoto(Integer userId, String base64Photo) {
        if (base64Photo == null || base64Photo.isBlank()) {
            throw new IllegalArgumentException("La foto no puede estar vacía");
        }
        if (!base64Photo.startsWith("data:image") && base64Photo.length() < 100) {
            throw new IllegalArgumentException("Formato de imagen no válido");
        }
        User user = userRepository.findUserByIdUser(userId)
                .orElseThrow(() -> new UserNotFoundException(userId));
        user.setProfile_photo(base64Photo);
        return userRepository.save(user);
    }

    // datos vehículo
    private void updateDriverData(Integer id, Map<String, Object> updates) {
        Optional<Driver> driverOpt = driverRepository.findByIdDriver(id);
        if (driverOpt.isEmpty()) return;

        Driver driver = driverOpt.get();
        String newPlate  = (String) updates.get("carPlate");
        String newModel  = (String) updates.get("carModel");
        String newColor  = (String) updates.get("carColor");
        Integer newSeats = updates.get("maxSeats") instanceof Integer s ? s : null;

        if (newPlate != null && !newPlate.isBlank()) {
            newPlate = newPlate.toUpperCase().replace(" ", "");
            if (!newPlate.matches("\\d{4}[A-Z]{3}")) {
                throw new IllegalArgumentException("La matrícula debe tener formato 1234ABC");
            }
        }
        if (newModel != null && !newModel.isBlank() && newModel.length() < 2) {
            throw new IllegalArgumentException("El modelo es demasiado corto");
        }
        if (newColor != null && !newColor.isBlank() && newColor.length() < 3) {
            throw new IllegalArgumentException("Introduce un color válido");
        }
        if (newSeats != null && newSeats < 1) {
            throw new IllegalArgumentException("Las plazas deben ser mayores que 0");
        }

        // si cambia la matrícula hay que borrar y recrear
        if (newPlate != null && !newPlate.isBlank() && !driver.getCarPlate().equals(newPlate)) {
            if (driverRepository.existsByCarPlate(newPlate)) {
                throw new AlreadyExistsException("Ya existe un vehículo con esa matrícula");
            }
            driverRepository.delete(driver);
            driverRepository.flush();
            Driver fresh = new Driver();
            fresh.setCarPlate(newPlate);
            fresh.setIdDriver(id);
            fresh.setCarModel(newModel  != null ? newModel  : driver.getCarModel());
            fresh.setCarColor(newColor  != null ? newColor  : driver.getCarColor());
            fresh.setMaxSeats(newSeats  != null ? newSeats  : driver.getMaxSeats());
            driverRepository.save(fresh);
            return;
        }

        if (newModel != null && !newModel.isBlank()) driver.setCarModel(newModel);
        if (newColor != null && !newColor.isBlank()) driver.setCarColor(newColor);
        if (newSeats != null)                        driver.setMaxSeats(newSeats);
        driverRepository.save(driver);
    }
}