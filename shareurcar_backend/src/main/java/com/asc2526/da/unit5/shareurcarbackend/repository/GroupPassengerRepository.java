package com.asc2526.da.unit5.shareurcarbackend.repository;

import com.asc2526.da.unit5.shareurcarbackend.model.GroupPassenger;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface GroupPassengerRepository extends JpaRepository<GroupPassenger, Integer> {
    List<GroupPassenger> findByIdGroup(Integer idGroup);

    List<GroupPassenger> findByIdUser(Integer idUser);

    Optional<GroupPassenger> findByIdGroupAndIdUser(Integer idGroup, Integer idUser);
}