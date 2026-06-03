package com.asc2526.da.unit5.shareurcarbackend.service;

import com.asc2526.da.unit5.shareurcarbackend.model.*;
import com.asc2526.da.unit5.shareurcarbackend.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

@Service
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final RouteRepository routeRepository;
    private final TravelGroupRepository travelGroupRepository;
    private final GroupPassengerRepository groupPassengerRepository;

    public NotificationService(NotificationRepository notificationRepository,
                               UserRepository userRepository,
                               RouteRepository routeRepository,
                               TravelGroupRepository travelGroupRepository,
                               GroupPassengerRepository groupPassengerRepository
                               ) {
        this.notificationRepository = notificationRepository;
        this.userRepository = userRepository;
        this.routeRepository = routeRepository;
        this.travelGroupRepository = travelGroupRepository;
        this.groupPassengerRepository = groupPassengerRepository;
    }

    // crear notificación
    public void crear(Integer idUser, String title, String body) {
        Notification n = new Notification();
        n.setIdUser(idUser);
        n.setTitle(title);
        n.setBody(body);
        notificationRepository.save(n);
    }

    // leer notificaciones
    public List<Map<String, Object>> getByUser(Integer userId) {
        return notificationRepository.findByIdUserOrderByCreatedAtDesc(userId)
                .stream().map(n -> {
                    Map<String, Object> m = new HashMap<>();
                    m.put("idNotification", n.getIdNotification());
                    m.put("title",          n.getTitle());
                    m.put("body",           n.getBody());
                    m.put("isRead",         n.getIsRead());
                    m.put("createdAt",      n.getCreatedAt());
                    return m;
                }).toList();
    }

    public long countUnread(Integer userId) {
        return notificationRepository.countByIdUserAndIsReadFalse(userId);
    }

    public void markAllAsRead(Integer userId) {
        notificationRepository.markAllAsRead(userId);
    }

    // notificar viaje confirmado
    public void notificarViajeConfirmado(Integer routeId) {
        Route route = routeRepository.findById(routeId).orElse(null);
        if (route == null) return;

        TravelGroup group = travelGroupRepository.findByIdRoute(routeId).orElse(null);
        if (group == null) return;

        String title = "✅ Viaje confirmado";
        String body = "El viaje " + route.getOrigin() + " → " + route.getDestination()
                + " ha sido confirmado por todos. El pago ha sido procesado.";

        crear(route.getIdDriver(), title, body);

        groupPassengerRepository.findByIdGroup(group.getIdGroup()).forEach(gp -> {
            if (!gp.getIdUser().equals(route.getIdDriver())) {
                crear(gp.getIdUser(), title, body);
            }
        });
    }

    // reportar incidencia
    @Transactional
    public void reportarIncidencia(Integer routeId, Integer reporterId, String mensaje) {
        Route route = routeRepository.findById(routeId)
                .orElseThrow(() -> new RuntimeException("Ruta no encontrada"));

        if ("COMPLETED".equals(route.getStatus())) {
            throw new RuntimeException("La ruta ya está finalizada");
        }
        if ("CANCELLED".equals(route.getStatus())) {
            throw new RuntimeException("La ruta ya está cancelada");
        }

        boolean esConductor = route.getIdDriver().equals(reporterId);
        notificarIncidencia(routeId, reporterId, esConductor);
    }

    // notificar incidencias
    private void notificarIncidencia(Integer routeId, Integer reporterId, boolean esConductor) {
        Route route = routeRepository.findById(routeId).orElse(null);
        if (route == null) return;

        User reporter = userRepository.findUserByIdUser(reporterId).orElse(null);
        String nombreReporter = reporter != null
                ? reporter.getFirstname() + " " + reporter.getLastname()
                : esConductor ? "El conductor" : "Un pasajero";

        String rutaStr = route.getOrigin() + " → " + route.getDestination();

        if (esConductor) {
            // si el conductor reporta se notifica a los pasajeros
            TravelGroup group = travelGroupRepository.findByIdRoute(routeId).orElse(null);
            if (group == null) return;

            String title = "⚠️ Ruta cancelada por incidencia";
            String body = nombreReporter + " ha reportado una incidencia en la ruta "
                    + rutaStr + ". La ruta ha sido cancelada y se ha devuelto tu saldo.";

            groupPassengerRepository.findByIdGroup(group.getIdGroup()).forEach(gp -> {
                if (!gp.getIdUser().equals(reporterId)) crear(gp.getIdUser(), title, body);
            });
        } else {
            // si el pasajero reporta se notifica solo al conductor
            String title = "⚠️ Incidencia reportada";
            String body = nombreReporter + " ha reportado una incidencia en la ruta "
                    + rutaStr + ". La ruta ha sido cancelada y se han devuelto los saldos.";
            crear(route.getIdDriver(), title, body);
        }
    }
}