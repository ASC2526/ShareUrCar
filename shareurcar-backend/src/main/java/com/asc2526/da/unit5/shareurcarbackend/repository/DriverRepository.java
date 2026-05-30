package com.asc2526.da.unit5.shareurcarbackend.repository;

import com.asc2526.da.unit5.shareurcarbackend.model.Driver;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface DriverRepository extends JpaRepository<Driver, Integer> {
    boolean existsByIdDriver(Integer idDriver);

    Optional<Driver> findByIdDriver(Integer idDriver);
    Optional<Driver> findByCarPlate(String carPlate);

    boolean existsByCarPlate(String carPlate);
}