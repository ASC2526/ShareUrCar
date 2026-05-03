package com.asc2526.da.unit5.shareurcarbackend.exception;

public class UserNotFoundException extends RuntimeException {

    public UserNotFoundException(Long id) {
        super("User no encontrado con id: " + id);
    }
}