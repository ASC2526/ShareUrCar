package com.asc2526.da.unit5.shareurcarbackend.auth;

import com.asc2526.da.unit5.shareurcarbackend.model.User;
import com.asc2526.da.unit5.shareurcarbackend.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public User login(LoginRequest request) {
        if (request.getEmail() == null || request.getPassword() == null) {
            throw new RuntimeException("Email y contraseña obligatorios");
        }

        return userRepository.findByEmail(request.getEmail().trim())
                .filter(user -> passwordEncoder.matches(request.getPassword().trim(), user.getPassword()))
                .orElseThrow(() -> new RuntimeException("Credenciales incorrectas"));
    }

    public User register(User user) {
        if (user.getEmail() == null || user.getPassword() == null) {
            throw new RuntimeException("Datos incompletos");
        }

        if (userRepository.findByEmail(user.getEmail().trim()).isPresent()) {
            throw new RuntimeException("El usuario ya existe");
        }

        user.setEmail(user.getEmail().trim());
        user.setPassword(passwordEncoder.encode(user.getPassword().trim()));

        return userRepository.save(user);
    }
}