package com.asc2526.da.unit5.shareurcarbackend.service;

import com.asc2526.da.unit5.shareurcarbackend.exception.AlreadyExistsException;
import com.asc2526.da.unit5.shareurcarbackend.model.Driver;
import com.asc2526.da.unit5.shareurcarbackend.repository.DriverRepository;
import com.asc2526.da.unit5.shareurcarbackend.repository.UserRepository;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
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

        if (driverRepository.existsById(driver.getCarPlate())) {
            throw new AlreadyExistsException("Ese coche ya está registrado");
        }

        return driverRepository.save(driver);
    }

    @Transactional
    public void updateDriver(Integer userId, Map<String, Object> updates) {
        Driver driver = driverRepository.findByIdDriver(userId)
                .orElse(new Driver());

        if (driver.getIdDriver() == null) {
            driver.setIdDriver(userId);
        }

        if (updates.containsKey("carModel")) {
            String val = (String) updates.get("carModel");
            if (val != null && !val.isEmpty()) driver.setCarModel(val);
        }

        if (updates.containsKey("carColor")) {
            driver.setCarColor((String) updates.get("carColor"));
        }

        if (updates.containsKey("carPlate")) {
            String val = (String) updates.get("carPlate");
            if (val != null && !val.isEmpty()) driver.setCarPlate(val);
        }

        if (updates.containsKey("maxSeats")) {
            Object seats = updates.get("maxSeats");
            if (seats instanceof Integer) {
                driver.setMaxSeats((Integer) seats);
            } else if (seats instanceof String) {
                driver.setMaxSeats(Integer.parseInt((String) seats));
            }
        }
        driverRepository.save(driver);
    }

    public Optional<Driver> getDriverByUserId(Integer userId) {
        return driverRepository.findByIdDriver(userId);
    }
}