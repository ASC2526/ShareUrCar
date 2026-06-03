package com.asc2526.da.unit5.shareurcarbackend.exception;

public class TravelGroupNotFoundException extends RuntimeException {

    public TravelGroupNotFoundException(Integer id) {
        super("Grupo no encontrado con id: " + id);
    }
}