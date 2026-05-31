package com.asc2526.da.unit5.shareurcarbackend.exception;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

import java.time.LocalDateTime;
import java.util.Objects;

@ControllerAdvice
public class GlobalExceptionHandler {

    private ResponseEntity<ApiError> error(int code, String msg, HttpStatus status) {
        return new ResponseEntity<>(new ApiError(code, msg, LocalDateTime.now()), status);
    }

    @ExceptionHandler(RouteNotFoundException.class)
    public ResponseEntity<ApiError> handleRouteNotFound(RouteNotFoundException ex) {
        return error(404, ex.getMessage(), HttpStatus.NOT_FOUND);
    }

    @ExceptionHandler(UserNotFoundException.class)
    public ResponseEntity<ApiError> handleUserNotFound(UserNotFoundException ex) {
        return error(404, ex.getMessage(), HttpStatus.NOT_FOUND);
    }

    @ExceptionHandler(UserIsNotDriverException.class)
    public ResponseEntity<ApiError> handleUserIsNotDriver(UserIsNotDriverException ex) {
        return error(404, ex.getMessage(), HttpStatus.NOT_FOUND);
    }

    @ExceptionHandler(TravelGroupNotFoundException.class)
    public ResponseEntity<ApiError> handleGroupNotFound(TravelGroupNotFoundException ex) {
        return error(404, ex.getMessage(), HttpStatus.NOT_FOUND);
    }

    @ExceptionHandler(PaymentNotFoundException.class)
    public ResponseEntity<ApiError> handlePaymentNotFound(PaymentNotFoundException ex) {
        return error(404, ex.getMessage(), HttpStatus.NOT_FOUND);
    }

    @ExceptionHandler(NoAvailableSeatsException.class)
    public ResponseEntity<ApiError> handleNoSeats(NoAvailableSeatsException ex) {
        return error(409, ex.getMessage(), HttpStatus.CONFLICT);
    }

    @ExceptionHandler(YourOwnRouteException.class)
    public ResponseEntity<ApiError> handleOwnRoute(YourOwnRouteException ex) {
        return error(409, ex.getMessage(), HttpStatus.CONFLICT);
    }

    @ExceptionHandler(AlreadyExistsException.class)
    public ResponseEntity<ApiError> handleAlreadyExists(AlreadyExistsException ex) {
        return error(400, ex.getMessage(), HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiError> handleIllegal(IllegalArgumentException ex) {
        return error(400, ex.getMessage(), HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ApiError> handleDataIntegrity(DataIntegrityViolationException ex) {
        return error(409, "Conflicto en la base de datos (posible duplicado o clave foránea en uso)",
                HttpStatus.CONFLICT);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiError> handleValidation(MethodArgumentNotValidException ex) {
        String msg = Objects.requireNonNull(ex.getBindingResult().getFieldError()).getDefaultMessage();
        return error(400, msg, HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiError> handleGeneral(Exception ex) {
        return error(500, ex.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
    }
}