package com.asc2526.da.unit5.shareurcarbackend.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

@Entity
@Table(name = "drivers")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Driver {

    @Id
    @NotBlank
    @Column(name = "car_plate")
    private String carPlate;

    @NotNull
    @Column(name = "id_driver")
    private Integer idDriver;

    @NotBlank
    @Column(name = "car_model")
    private String carModel;

    @Min(1)
    @Column(name = "max_seats")
    private Integer maxSeats;

    @Column(name = "car_color")
    private String carColor;
}