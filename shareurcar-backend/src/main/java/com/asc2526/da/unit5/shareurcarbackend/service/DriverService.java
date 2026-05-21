package com.asc2526.da.unit5.shareurcarbackend.service;

import com.asc2526.da.unit5.shareurcarbackend.exception.AlreadyExistsException;
import com.asc2526.da.unit5.shareurcarbackend.model.Driver;
import com.asc2526.da.unit5.shareurcarbackend.repository.DriverRepository;
import com.asc2526.da.unit5.shareurcarbackend.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.util.List;

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
}