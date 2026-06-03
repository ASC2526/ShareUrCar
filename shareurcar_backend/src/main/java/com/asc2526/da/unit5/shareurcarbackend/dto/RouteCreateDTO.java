package com.asc2526.da.unit5.shareurcarbackend.dto;

import lombok.Data;
import java.time.LocalDate;
import java.time.LocalTime;

@Data
public class RouteCreateDTO {
    private Integer idDriver;
    private String origin;
    private Double originLat;
    private Double originLng;
    private String destination;
    private Double destinationLat;
    private Double destinationLng;
    private LocalTime departure_time;
    private String frequency;
    private String days_of_week;
    private LocalDate travel_date;
    private LocalDate start_date;
    private LocalDate end_date;
    private Integer available_seats;
    private Boolean allowRoundTrip;
    private LocalTime return_time;
    private Boolean pref_no_talk;
    private Boolean pref_luggage;
    private Boolean pref_music;
    private Boolean pref_smoke;
}