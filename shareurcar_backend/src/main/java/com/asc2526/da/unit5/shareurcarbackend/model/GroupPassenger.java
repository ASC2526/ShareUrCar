package com.asc2526.da.unit5.shareurcarbackend.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

@Entity
@Table(name = "group_passengers")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class GroupPassenger {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_group_passenger")
    private Integer idGroupPassenger;

    @NotNull
    @Column(name = "id_group")
    private Integer idGroup;

    @NotNull
    @Column(name = "id_user")
    private Integer idUser;

    @NotBlank
    private String state;

    @Column(name = "confirmed")
    private Boolean confirmed = false;

    public boolean isConfirmed() {
        return confirmed;
    }
}