package com.asc2526.da.unit5.shareurcarbackend.repository;

import com.asc2526.da.unit5.shareurcarbackend.model.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

public interface NotificationRepository extends JpaRepository<Notification, Integer> {

    List<Notification> findByIdUserOrderByCreatedAtDesc(Integer idUser);

    long countByIdUserAndIsReadFalse(Integer idUser);

    @Modifying
    @Transactional
    @Query("UPDATE Notification n " +
            "SET n.isRead = true " +
            "WHERE n.idUser = :userId")
    void markAllAsRead(@Param("userId") Integer userId);
}