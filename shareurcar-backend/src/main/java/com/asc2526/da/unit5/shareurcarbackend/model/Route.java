package com.asc2526.da.unit5.shareurcarbackend.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

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

    @ManyToMany
    @JoinTable(
            name = "route_passengers",
            joinColumns = @JoinColumn(name = "id_route"),
            inverseJoinColumns = @JoinColumn(name = "id_user")
    )
    private List<User> passengers = new ArrayList<>();

    @NotBlank
    private String origin;

    @NotBlank
    private String destination;

    @Column(name = "origin_lat")
    private Double originLat;

    @Column(name = "origin_lng")
    private Double originLng;

    @Column(name = "destination_lat")
    private Double destinationLat;

    @Column(name = "destination_lng")
    private Double destinationLng;

    @NotNull
    private LocalTime departure_time;
    private LocalTime arrival_time;

    private String days_of_week;
    private String frequency;

    @Min(1)
    private Integer available_seats;

    @Column(name = "status")
    private String status = "PENDING";

    @Column(name = "driver_confirmed")
    private Boolean driverConfirmed = false;

    @Column(name = "allow_round_trip")
    private Boolean allowRoundTrip = false;

    // preferencias
    @Column(name = "pref_no_talk")
    private Boolean prefNoTalk;

    @Column(name = "pref_luggage")
    private Boolean prefLuggage;

    @Column(name = "pref_music")
    private Boolean prefMusic;

    @Column(name = "pref_smoke")
    private Boolean prefSmoke;

    @Column(name = "start_date")
    private LocalDate start_date;

    @Column(name = "end_date")
    private LocalDate end_date;

    @Column(name = "return_time")
    private LocalTime return_time;

    @Column(name = "travel_date")
    private LocalDate travel_date;

    @Column(name = "series_id")
    private String seriesId;



}