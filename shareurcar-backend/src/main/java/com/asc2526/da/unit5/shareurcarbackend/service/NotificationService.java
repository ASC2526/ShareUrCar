package com.asc2526.da.unit5.shareurcarbackend.service;

import com.asc2526.da.unit5.shareurcarbackend.model.*;
import com.asc2526.da.unit5.shareurcarbackend.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.ArrayList;
import java.util.HashMap;

@Service
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final RouteRepository routeRepository;
    private final TravelGroupRepository travelGroupRepository;
    private final GroupPassengerRepository groupPassengerRepository;
    private final PaymentRepository paymentRepository;

    public NotificationService(NotificationRepository notificationRepository,
                               UserRepository userRepository,
                               RouteRepository routeRepository,
                               TravelGroupRepository travelGroupRepository,
                               GroupPassengerRepository groupPassengerRepository,
                               PaymentRepository paymentRepository) {
        this.notificationRepository = notificationRepository;
        this.userRepository = userRepository;
        this.routeRepository = routeRepository;
        this.travelGroupRepository = travelGroupRepository;
        this.groupPassengerRepository = groupPassengerRepository;
        this.paymentRepository = paymentRepository;
    }

    public Notification crear(Integer idUser, String title, String body) {
        Notification n = new Notification();
        n.setIdUser(idUser);
        n.setTitle(title);
        n.setBody(body);
        return notificationRepository.save(n);
    }

    public List<Map<String, Object>> getByUser(Integer userId) {
        List<Notification> lista =
                notificationRepository.findByIdUserOrderByCreatedAtDesc(userId);
        List<Map<String, Object>> result = new ArrayList<>();
        for (Notification n : lista) {
            Map<String, Object> m = new HashMap<>();
            m.put("idNotification", n.getIdNotification());
            m.put("title", n.getTitle());
            m.put("body", n.getBody());
            m.put("isRead", n.getIsRead());
            m.put("createdAt", n.getCreatedAt());
            result.add(m);
        }
        return result;
    }

    public long countUnread(Integer userId) {
        return notificationRepository.countByIdUserAndIsReadFalse(userId);
    }

    public void markAllAsRead(Integer userId) {
        notificationRepository.markAllAsRead(userId);
    }

    public void notificarIncidenciaPasajero(Integer routeId, Integer reporterId) {
        Route route = routeRepository.findById(routeId).orElse(null);
        if (route == null) return;

        User reporter = userRepository.findUserByIdUser(reporterId).orElse(null);
        String nombreReporter = reporter != null
                ? reporter.getFirstname() + " " + reporter.getLastname()
                : "Un pasajero";

        String title = "⚠️ Incidencia reportada";
        String body = nombreReporter + " ha reportado una incidencia en la ruta "
                + route.getOrigin() + " → " + route.getDestination()
                + ". La ruta ha sido cancelada y se han devuelto los saldos.";

        crear(route.getIdDriver(), title, body);
    }

    public void notificarIncidenciaConductor(Integer routeId, Integer reporterId) {
        Route route = routeRepository.findById(routeId).orElse(null);
        if (route == null) return;

        TravelGroup group = travelGroupRepository.findByIdRoute(routeId).orElse(null);
        if (group == null) return;

        User driver = userRepository.findUserByIdUser(reporterId).orElse(null);
        String nombreDriver = driver != null
                ? driver.getFirstname() + " " + driver.getLastname()
                : "El conductor";

        String title = "⚠️ Ruta cancelada por incidencia";
        String body = nombreDriver + " ha reportado una incidencia en la ruta "
                + route.getOrigin() + " → " + route.getDestination()
                + ". La ruta ha sido cancelada y se ha devuelto tu saldo.";

        List<GroupPassenger> passengers =
                groupPassengerRepository.findByIdGroup(group.getIdGroup());

        for (GroupPassenger gp : passengers) {
            if (gp.getIdUser().equals(reporterId)) continue;
            crear(gp.getIdUser(), title, body);
        }
    }

    public void notificarViajeConfirmado(Integer routeId) {
        Route route = routeRepository.findById(routeId).orElse(null);
        if (route == null) return;

        TravelGroup group = travelGroupRepository.findByIdRoute(routeId).orElse(null);
        if (group == null) return;

        String title = "✅ Viaje confirmado";
        String body = "El viaje " + route.getOrigin() + " → " + route.getDestination()
                + " ha sido confirmado por todos. El pago ha sido procesado.";

        crear(route.getIdDriver(), title, body);

        List<GroupPassenger> passengers =
                groupPassengerRepository.findByIdGroup(group.getIdGroup());
        for (GroupPassenger gp : passengers) {
            if (gp.getIdUser().equals(route.getIdDriver())) continue;
            crear(gp.getIdUser(), title, body);
        }
    }

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

        TravelGroup group = travelGroupRepository.findByIdRoute(routeId).orElse(null);
        if (group != null) {
            List<Payment> payments = paymentRepository.findByGroup(group.getIdGroup());
            for (Payment payment : payments) {
                if ("COMPLETED".equals(payment.getPaymentStatus())) continue;
                User passenger = userRepository.findUserByIdUser(payment.getIdUser()).orElse(null);
                if (passenger == null) continue;

                double held = passenger.getHeldBalance() != null ? passenger.getHeldBalance() : 0.0;
                double balance = passenger.getBalance() != null ? passenger.getBalance() : 0.0;
                passenger.setHeldBalance(Math.max(0, held - payment.getAmount()));
                passenger.setBalance(balance + payment.getAmount());
                userRepository.save(passenger);

                payment.setPaymentStatus("CANCELLED");
                paymentRepository.save(payment);
            }
        }

        route.setStatus("CANCELLED");
        routeRepository.save(route);

        if (esConductor) {
            notificarIncidenciaConductor(routeId, reporterId);
        } else {
            notificarIncidenciaPasajero(routeId, reporterId);
        }
    }
}