package com.asc2526.da.unit5.shareurcarbackend.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.*;

import java.time.LocalDate;

@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_user")
    private Integer idUser;

    @NotBlank(message = "El nombre no puede estar vacío")
    @Size(max = 100)
    private String firstname;

    @NotBlank
    @Size(max = 100)
    private String lastname;

    @Email
    @NotBlank(message = "El email no puede estar vacío")
    @Column(unique = true)
    private String email;

    @NotBlank(message = "La contraseña no puede estar vacía")
    @Size(min = 4)
    private String password;
    private String center;
    private String profile_photo;

    @Min(0)
    @Max(5)
    private Double rating;

    private String phone;

    @Column(name = "about_me")
    private String aboutMe;

    @Column(name = "created_at", insertable = false, updatable = false)
    private LocalDate createdAt;
}