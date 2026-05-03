package com.asc2526.da.unit5.shareurcarbackend.exception;

public class PaymentNotFoundException extends RuntimeException {

    public PaymentNotFoundException(Integer id) {
        super("Pago no encontrado con id: " + id);
    }
}