package com.asc2526.da.unit5.shareurcarbackend.repository;

import com.asc2526.da.unit5.shareurcarbackend.model.Payment;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface PaymentRepository extends JpaRepository<Payment, Integer> {

    @Query("""
        SELECT p
        FROM Payment p
        WHERE p.idGroup = :groupId
    """)
    List<Payment> findByGroup(@Param("groupId") Integer groupId);

    @Query("""
    SELECT p
    FROM Payment p
    WHERE p.idUser = :userId
    ORDER BY p.createdAt DESC
    """)
    List<Payment> findByUser(@Param("userId") Integer userId);

    boolean existsByIdGroupAndIdUser(Integer idGroup, Integer idUser);
}