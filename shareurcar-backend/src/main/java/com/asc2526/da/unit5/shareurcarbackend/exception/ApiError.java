package com.asc2526.da.unit5.shareurcarbackend.exception;

import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class ApiError {

    private int status;
    private String message;
    private LocalDateTime timestamp;
}