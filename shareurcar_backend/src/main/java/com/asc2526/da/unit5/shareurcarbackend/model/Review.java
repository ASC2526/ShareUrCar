package com.asc2526.da.unit5.shareurcarbackend.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "reviews")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Review {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_review")
    private Integer idReview;

    @ManyToOne
    @JoinColumn(name = "id_reviewer")
    private User reviewer;

    @Column(name = "id_reviewed")
    private Integer idReviewed;

    private Integer stars;

    private String comment;

    @Column(name = "created_at", insertable = false, updatable = false)
    private LocalDateTime createdAt;
}