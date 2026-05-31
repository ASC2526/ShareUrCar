package com.asc2526.da.unit5.shareurcarbackend.controller;

import com.asc2526.da.unit5.shareurcarbackend.service.NotificationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/notifications")
public class NotificationController {

    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @GetMapping("/user/{userId}")
    public List<Map<String, Object>> getByUser(@PathVariable Integer userId) {
        return notificationService.getByUser(userId);
    }

    @GetMapping("/user/{userId}/unread-count")
    public ResponseEntity<Long> countUnread(@PathVariable Integer userId) {
        return ResponseEntity.ok(notificationService.countUnread(userId));
    }

    @PatchMapping("/user/{userId}/mark-read")
    public ResponseEntity<Void> markAllAsRead(@PathVariable Integer userId) {
        notificationService.markAllAsRead(userId);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/incident/{routeId}/reporter/{reporterId}")
    public ResponseEntity<?> reportIncident(
            @PathVariable Integer routeId,
            @PathVariable Integer reporterId,
            @RequestBody(required = false) Map<String, String> body) {
        try {
            notificationService.reportarIncidencia(routeId, reporterId,
                    body != null ? body.getOrDefault("message", "") : "");
            return ResponseEntity.ok(Map.of("message", "Incidencia reportada correctamente"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}