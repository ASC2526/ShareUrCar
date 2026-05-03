package com.asc2526.da.unit5.shareurcarbackend.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.time.LocalTime;

@Entity
@Table(name = "routes")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Route {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_route")
    private Integer idRoute;

    @NotNull
    @Column(name = "id_driver")
    private Integer idDriver;

    @NotBlank
    private String origin;

    @NotBlank
    private String destination;

    @NotNull
    private LocalTime departure_time;
    private LocalTime arrival_time;

    private String days_of_week;
    private String frequency;

    @Min(1)
    private Integer available_seats;
}