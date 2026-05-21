package com.asc2526.da.unit5.shareurcarbackend.exception;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Objects;

@ControllerAdvice
public class GlobalExceptionHandler {

    // ROUTE
    @ExceptionHandler(RouteNotFoundException.class)
    public ResponseEntity<ApiError> handleRouteNotFound(RouteNotFoundException ex) {
        return new ResponseEntity<>(
                new ApiError(404, ex.getMessage(), LocalDateTime.now()),
                HttpStatus.NOT_FOUND
        );
    }

    @ExceptionHandler(NoAvailableSeatsException.class)
    public ResponseEntity<ApiError> handleNoAvailableSeats(NoAvailableSeatsException ex) {
        return new ResponseEntity<>(
                new ApiError(409, ex.getMessage(), LocalDateTime.now()),
                HttpStatus.CONFLICT
        );
    }

    @ExceptionHandler(YourOwnRouteException.class)
    public ResponseEntity<ApiError> handleYourOwnRoute(YourOwnRouteException ex) {
        return new ResponseEntity<>(
                new ApiError(409, ex.getMessage(), LocalDateTime.now()),
                HttpStatus.CONFLICT
        );
    }

    // USER
    @ExceptionHandler(UserNotFoundException.class)
    public ResponseEntity<ApiError> handleUserNotFound(UserNotFoundException ex) {
        return new ResponseEntity<>(
                new ApiError(404, ex.getMessage(), LocalDateTime.now()),
                HttpStatus.NOT_FOUND
        );
    }

    @ExceptionHandler(UserIsNotDriverException.class)
    public ResponseEntity<ApiError> handleUserIsNotDriver(UserIsNotDriverException ex) {
        return new ResponseEntity<>(
                new ApiError(404, ex.getMessage(), LocalDateTime.now()),
                HttpStatus.NOT_FOUND
        );
    }

    // GROUP
    @ExceptionHandler(TravelGroupNotFoundException.class)
    public ResponseEntity<ApiError> handleGroupNotFound(TravelGroupNotFoundException ex) {
        return new ResponseEntity<>(
                new ApiError(404, ex.getMessage(), LocalDateTime.now()),
                HttpStatus.NOT_FOUND
        );
    }

    // PAYMENT
    @ExceptionHandler(PaymentNotFoundException.class)
    public ResponseEntity<ApiError> handlePaymentNotFound(PaymentNotFoundException ex) {
        return new ResponseEntity<>(
                new ApiError(404, ex.getMessage(), LocalDateTime.now()),
                HttpStatus.NOT_FOUND
        );
    }

    // 400

    @ExceptionHandler(AlreadyExistsException.class)
    public ResponseEntity<ApiError> handleAlreadyExists(AlreadyExistsException ex) {
        return new ResponseEntity<>(
                new ApiError(400, ex.getMessage(), LocalDateTime.now()),
                HttpStatus.BAD_REQUEST
        );
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiError> handleIllegal(IllegalArgumentException ex) {
        return new ResponseEntity<>(
                new ApiError(400, ex.getMessage(), LocalDateTime.now()),
                HttpStatus.BAD_REQUEST
        );
    }

    // GENERAL
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiError> handleGeneral(Exception ex) {
        return new ResponseEntity<>(
                new ApiError(500, ex.getMessage(), LocalDateTime.now()),
                HttpStatus.INTERNAL_SERVER_ERROR
        );
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ApiError> handleDataIntegrity(DataIntegrityViolationException ex) {
        return new ResponseEntity<>(
                new ApiError(409, "Conflicto en la base de datos (posible duplicado o clave foránea en uso)", LocalDateTime.now()),
                HttpStatus.CONFLICT
        );
    }

    // VALID

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiError> handleValidation(MethodArgumentNotValidException ex) {

        String error = Objects.requireNonNull(ex.getBindingResult().getFieldError()).getDefaultMessage();

        return new ResponseEntity<>(
                new ApiError(400, error, LocalDateTime.now()),
                HttpStatus.BAD_REQUEST
        );
    }
}