package com.asc2526.da.unit5.shareurcarbackend.repository;

import com.asc2526.da.unit5.shareurcarbackend.model.GroupPassenger;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface GroupPassengerRepository extends JpaRepository<GroupPassenger, Integer> {
    @Query("""
        SELECT gp
        FROM GroupPassenger gp
        WHERE gp.idGroup = :groupId
    """)
    List<GroupPassenger> findByGroupId(@Param("groupId") Integer groupId);

    @Query("""
        SELECT gp
        FROM GroupPassenger gp
        WHERE gp.idUser = :userId
    """)
    List<GroupPassenger> findByUserId(@Param("userId") Integer userId);

    @Query("""
    SELECT COUNT(gp) > 0
    FROM GroupPassenger gp
    WHERE gp.idGroup = :groupId
    AND gp.idUser = :userId
""")
    boolean existsByGroupAndUser(
            @Param("groupId") Integer groupId,
            @Param("userId") Integer userId
    );

    Optional<GroupPassenger> findByIdGroupAndIdUser(Integer idGroup, Integer idUser);

    List<GroupPassenger> findByIdGroup(Integer idGroup);

}