package com.asc2526.da.unit5.shareurcarbackend.auth;

import com.asc2526.da.unit5.shareurcarbackend.model.User;
import com.asc2526.da.unit5.shareurcarbackend.repository.UserRepository;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    private final UserRepository userRepository;

    public AuthService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    // LOGIN
    public User login(LoginRequest request) {

        if (request.getEmail() == null || request.getPassword() == null) {
            throw new RuntimeException("Email y contraseña obligatorios");
        }

        String email = request.getEmail().trim();
        String password = request.getPassword().trim();

        return userRepository.findByEmail(email)
                .filter(user -> user.getPassword().equals(password))
                .orElseThrow(() -> new RuntimeException("Credenciales incorrectas"));
    }

    // REGISTER
    public User register(User user) {

        if (user.getEmail() == null || user.getPassword() == null) {
            throw new RuntimeException("Datos incompletos");
        }

        String email = user.getEmail().trim();
        String password = user.getPassword().trim();

        if (userRepository.findByEmail(email).isPresent()) {
            throw new RuntimeException("El usuario ya existe");
        }

        user.setEmail(email);
        user.setPassword(password);

        return userRepository.save(user);
    }
}