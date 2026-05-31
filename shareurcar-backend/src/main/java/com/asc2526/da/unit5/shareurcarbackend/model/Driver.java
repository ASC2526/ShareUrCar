package com.asc2526.da.unit5.shareurcarbackend.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Entity
@Table(name = "drivers")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Driver {

    @Id
    @Column(name = "id_driver")
    private Integer idDriver;

    @Column(name = "car_plate", unique = true)
    private String carPlate;

    @NotBlank
    @Column(name = "car_model")
    private String carModel;

    @Min(1)
    @Column(name = "max_seats")
    private Integer maxSeats;

    @Column(name = "car_color")
    private String carColor;
}