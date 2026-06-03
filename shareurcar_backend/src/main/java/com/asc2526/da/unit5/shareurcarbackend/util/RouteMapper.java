package com.asc2526.da.unit5.shareurcarbackend.util;

import com.asc2526.da.unit5.shareurcarbackend.model.Route;

import java.util.HashMap;
import java.util.Map;

public class RouteMapper {

    private RouteMapper() {}

    public static Map<String, Object> toMap(Route r, String driverName, Integer maxSeats) {
        Map<String, Object> m = new HashMap<>();

        // Ids
        m.put("idRoute", r.getIdRoute());
        m.put("id_route", r.getIdRoute());
        m.put("idDriver", r.getIdDriver());

        // Trayecto
        m.put("origin", r.getOrigin());
        m.put("destination", r.getDestination());
        m.put("originLat", r.getOriginLat());
        m.put("originLng", r.getOriginLng());
        m.put("destinationLat", r.getDestinationLat());
        m.put("destinationLng", r.getDestinationLng());

        // Tiempos (en string para que jackson los serialice bien)
        m.put("departure_time", r.getDeparture_time() != null ? r.getDeparture_time().toString() : null);
        m.put("arrival_time", r.getArrival_time() != null ? r.getArrival_time().toString() : null);
        m.put("return_time", r.getReturn_time() != null ? r.getReturn_time().toString() : null);
        m.put("travel_date", r.getTravel_date() != null ? r.getTravel_date().toString() : null);
        m.put("start_date", r.getStart_date() != null ? r.getStart_date().toString() : null);
        m.put("end_date", r.getEnd_date() != null ? r.getEnd_date().toString() : null);

        // Detalles
        m.put("frequency", r.getFrequency());
        m.put("days_of_week", r.getDays_of_week());
        m.put("available_seats", r.getAvailable_seats());
        m.put("status", r.getStatus());
        m.put("driverConfirmed", r.getDriverConfirmed());
        m.put("allowRoundTrip", r.getAllowRoundTrip());
        m.put("seriesId", r.getSeriesId());

        // Preferencias
        m.put("pref_no_talk", r.getPrefNoTalk());
        m.put("pref_luggage", r.getPrefLuggage());
        m.put("pref_music", r.getPrefMusic());
        m.put("pref_smoke", r.getPrefSmoke());

        // datos extra que vienen de otras entidades
        m.put("driverName", driverName);
        m.put("maxSeats", maxSeats != null ? maxSeats : 4);
        m.put("passengers", r.getPassengers());

        return m;
    }
}