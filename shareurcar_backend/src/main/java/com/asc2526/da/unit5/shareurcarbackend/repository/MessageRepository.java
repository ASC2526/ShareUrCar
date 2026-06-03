package com.asc2526.da.unit5.shareurcarbackend.repository;

import com.asc2526.da.unit5.shareurcarbackend.model.Message;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface MessageRepository extends JpaRepository<Message, Integer> {
    @Query("""
        SELECT m
        FROM Message m
        WHERE m.idGroup = :groupId
        ORDER BY m.sentAt ASC
    """)
    List<Message> findByGroup(@Param("groupId") Integer groupId);
}