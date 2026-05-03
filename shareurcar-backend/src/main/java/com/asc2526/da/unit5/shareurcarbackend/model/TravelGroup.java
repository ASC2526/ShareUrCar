package com.asc2526.da.unit5.shareurcarbackend.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalTime;

@Entity
@Table(name = "travel_groups")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class TravelGroup {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_group")
    private Integer idGroup;

    @NotNull
    @Column(name = "id_route")
    private Integer idRoute;

    @NotNull
    @Column(name = "id_driver")
    private Integer idDriver;

    @NotBlank
    private String status;

    @NotNull
    @Column(name = "travel_date")
    private LocalDate travelDate;

    @NotNull
    @Column(name = "travel_time")
    private LocalTime travelTime;
}