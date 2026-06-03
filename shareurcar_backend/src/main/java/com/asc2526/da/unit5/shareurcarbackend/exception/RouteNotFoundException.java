package com.asc2526.da.unit5.shareurcarbackend.exception;

public class RouteNotFoundException extends RuntimeException {

    public RouteNotFoundException(Integer id) {
        super("Route no encontrada con id: " + id);
    }
}