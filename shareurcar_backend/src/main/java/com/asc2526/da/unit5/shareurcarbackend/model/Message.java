package com.asc2526.da.unit5.shareurcarbackend.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "messages")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Message {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_message")
    private Integer idMessage;

    @NotNull
    @Column(name = "id_group")
    private Integer idGroup;

    @NotNull
    @Column(name = "id_user")
    private Integer idUser;

    @NotBlank
    private String text;

    @Column(name = "sent_at")
    private LocalDateTime sentAt;
}