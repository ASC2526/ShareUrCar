package com.asc2526.da.unit5.shareurcarbackend.service;

import com.asc2526.da.unit5.shareurcarbackend.exception.AlreadyExistsException;
import com.asc2526.da.unit5.shareurcarbackend.model.Driver;
import com.asc2526.da.unit5.shareurcarbackend.repository.DriverRepository;
import com.asc2526.da.unit5.shareurcarbackend.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class DriverService {

    private final DriverRepository driverRepository;
    private final UserRepository userRepository;

    public DriverService(DriverRepository driverRepository, UserRepository userRepository) {
        this.driverRepository = driverRepository;
        this.userRepository = userRepository;
    }

    public List<Driver> getAll() {
        return driverRepository.findAll();
    }

    public Driver registerDriver(Driver driver) {
        if (driver.getIdDriver() == null) {
            throw new IllegalArgumentException("El ID del conductor no puede ser nulo");
        }
        if (!userRepository.existsById(Long.valueOf(driver.getIdDriver()))) {
            throw new RuntimeException("El usuario no existe");
        }

        if (driverRepository.existsByCarPlate(driver.getCarPlate())) {
            throw new AlreadyExistsException("Ese coche ya está registrado");
        }
        String carPlate = driver.getCarPlate();

        if (carPlate == null || carPlate.isBlank()) {
            throw new IllegalArgumentException("La matrícula es obligatoria");
        }

        carPlate = carPlate.toUpperCase().replace(" ", "");

        if (!carPlate.matches("\\d{4}[A-Z]{3}")) {
            throw new IllegalArgumentException(
                    "La matrícula debe tener formato 1234ABC");
        }

        driver.setCarPlate(carPlate);

        if (driver.getCarModel() == null
                || driver.getCarModel().isBlank()
                || driver.getCarModel().length() < 2) {
            throw new IllegalArgumentException(
                    "Introduce un modelo válido");
        }

        if (driver.getCarColor() == null
                || driver.getCarColor().isBlank()
                || driver.getCarColor().length() < 3) {
            throw new IllegalArgumentException(
                    "Introduce un color válido");
        }
        return driverRepository.save(driver);
    }

    public Optional<Driver> getDriverByUserId(Integer userId) {
        return driverRepository.findByIdDriver(userId);
    }
}