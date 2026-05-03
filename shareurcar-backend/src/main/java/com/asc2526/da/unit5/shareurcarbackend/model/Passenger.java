package com.asc2526.da.unit5.shareurcarbackend.model;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "passengers")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Passenger {

    @Id
    @Column(name = "id_passenger")
    private Integer idPassenger;

    private String preferences;
}