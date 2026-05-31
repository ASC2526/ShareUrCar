package com.asc2526.da.unit5.shareurcarbackend.service;

import com.asc2526.da.unit5.shareurcarbackend.model.*;
import com.asc2526.da.unit5.shareurcarbackend.repository.*;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.*;

@Service
public class MessageService {

    private final MessageRepository messageRepository;
    private final TravelGroupRepository travelGroupRepository;
    private final RouteRepository routeRepository;
    private final UserRepository userRepository;
    private final GroupPassengerRepository groupPassengerRepository;

    public MessageService(MessageRepository messageRepository,
                          TravelGroupRepository travelGroupRepository,
                          RouteRepository routeRepository,
                          UserRepository userRepository,
                          GroupPassengerRepository groupPassengerRepository) {
        this.messageRepository = messageRepository;
        this.travelGroupRepository = travelGroupRepository;
        this.routeRepository = routeRepository;
        this.userRepository = userRepository;
        this.groupPassengerRepository = groupPassengerRepository;
    }

    public List<Map<String, Object>> getByGroup(Integer groupId) {
        List<Message> messages = messageRepository.findByGroup(groupId);
        TravelGroup group = travelGroupRepository.findById(groupId).orElseThrow();

        List<Map<String, Object>> result = new ArrayList<>();
        for (Message m : messages) {
            User user = userRepository.findUserByIdUser(m.getIdUser()).orElse(null);
            Map<String, Object> map = new HashMap<>();
            map.put("idMessage", m.getIdMessage());
            map.put("idUser", m.getIdUser());
            map.put("text", m.getText());
            map.put("sentAt", m.getSentAt());
            map.put("fullName", user != null
                    ? user.getFirstname() + " " + user.getLastname()
                    : "Usuario");
            map.put("profilePhoto", user != null ? user.getProfile_photo() : null);
            map.put("isDriver", group.getIdDriver().equals(m.getIdUser()));
            result.add(map);
        }
        return result;
    }

    public Message sendMessage(Message message) {
        if (!travelGroupRepository.existsById(message.getIdGroup())) {
            throw new RuntimeException("Grupo no existe");
        }
        message.setSentAt(LocalDateTime.now());
        return messageRepository.save(message);
    }

    public void delete(Integer id) {
        messageRepository.deleteById(id);
    }

    public List<Map<String, Object>> getUserChats(Integer userId) {

        // Grupos donde es conductor
        List<TravelGroup> driverGroups = travelGroupRepository.findByIdDriver(userId);
        // Grupos donde es pasajero
        List<GroupPassenger> passengerEntries = groupPassengerRepository.findByUserId(userId);

        // LinkedHashSet evita duplicados
        Set<Integer> groupIds = new LinkedHashSet<>();
        for (TravelGroup g : driverGroups) groupIds.add(g.getIdGroup());
        for (GroupPassenger gp : passengerEntries) groupIds.add(gp.getIdGroup());

        List<Map<String, Object>> result = new ArrayList<>();

        for (Integer groupId : groupIds) {
            TravelGroup group = travelGroupRepository.findById(groupId).orElse(null);
            if (group == null) continue;

            Route route = routeRepository.findById(group.getIdRoute()).orElse(null);
            if (route == null) continue;

            // Saltar rutas completadas para la vista principal
            User driver = userRepository.findUserByIdUser(route.getIdDriver()).orElse(null);
            String driverName = driver != null
                    ? driver.getFirstname() + " " + driver.getLastname()
                    : "Conductor";

            // Último mensaje
            List<Message> messages = messageRepository.findByGroup(groupId);
            String lastMessage = messages.isEmpty()
                    ? ""
                    : messages.get(messages.size() - 1).getText();

            // Objeto ruta completo
            Map<String, Object> rutaMap = new HashMap<>();
            rutaMap.put("idRoute", route.getIdRoute());
            rutaMap.put("id_route", route.getIdRoute());
            rutaMap.put("idDriver", route.getIdDriver());
            rutaMap.put("origin", route.getOrigin());
            rutaMap.put("destination", route.getDestination());
            rutaMap.put("originLat", route.getOriginLat());
            rutaMap.put("originLng", route.getOriginLng());
            rutaMap.put("destinationLat", route.getDestinationLat());
            rutaMap.put("destinationLng", route.getDestinationLng());
            rutaMap.put("departure_time", route.getDeparture_time() != null
                    ? route.getDeparture_time().toString() : null);
            rutaMap.put("arrival_time", route.getArrival_time() != null
                    ? route.getArrival_time().toString() : null);
            rutaMap.put("return_time", route.getReturn_time() != null
                    ? route.getReturn_time().toString() : null);
            rutaMap.put("travel_date", route.getTravel_date() != null
                    ? route.getTravel_date().toString() : null);
            rutaMap.put("frequency", route.getFrequency());
            rutaMap.put("days_of_week", route.getDays_of_week());
            rutaMap.put("available_seats", route.getAvailable_seats());
            rutaMap.put("status", route.getStatus());
            rutaMap.put("allowRoundTrip", route.getAllowRoundTrip());
            rutaMap.put("pref_no_talk", route.getPrefNoTalk());
            rutaMap.put("pref_luggage", route.getPrefLuggage());
            rutaMap.put("pref_music", route.getPrefMusic());
            rutaMap.put("pref_smoke", route.getPrefSmoke());
            rutaMap.put("seriesId", route.getSeriesId());
            rutaMap.put("driverName", driverName);
            rutaMap.put("passengers", route.getPassengers());

            // Objeto chat
            Map<String, Object> chatMap = new HashMap<>();
            chatMap.put("idGroup", groupId);
            chatMap.put("idRoute", route.getIdRoute());
            chatMap.put("destination", route.getDestination());
            chatMap.put("origin", route.getOrigin());
            chatMap.put("travel_date", route.getTravel_date() != null
                    ? route.getTravel_date().toString() : null);
            chatMap.put("travel_time", route.getDeparture_time() != null
                    ? route.getDeparture_time().toString() : null);
            chatMap.put("lastMessage", lastMessage);
            chatMap.put("driverName", driverName);
            chatMap.put("driverId", route.getIdDriver());
            chatMap.put("seriesId", route.getSeriesId());
            chatMap.put("status", route.getStatus());
            chatMap.put("ruta", rutaMap);

            result.add(chatMap);
        }

        result.sort((a, b) -> {
            String dA = (String) a.get("travel_date");
            String dB = (String) b.get("travel_date");
            if (dA == null) return 1;
            if (dB == null) return -1;
            return dA.compareTo(dB);
        });

        return result;
    }

    public Integer getGroupIdByRoute(Integer routeId) {
        Optional<TravelGroup> direct = travelGroupRepository.findByIdRoute(routeId);
        if (direct.isPresent()) {
            return direct.get().getIdGroup();
        }
        Route route = routeRepository.findById(routeId)
                .orElseThrow(() -> new RuntimeException("Ruta no encontrada"));
        String seriesId = route.getSeriesId();
        if (seriesId == null) {
            throw new RuntimeException("Grupo no encontrado para esta ruta");
        }
        TravelGroup group = travelGroupRepository.findBySeriesId(seriesId)
                .orElseThrow(() -> new RuntimeException("Grupo no encontrado para la serie"));
        return group.getIdGroup();
    }

    public List<Map<String, Object>> getGroupMembers(Integer groupId) {
        TravelGroup group = travelGroupRepository.findById(groupId).orElseThrow();
        List<Map<String, Object>> result = new ArrayList<>();

        // Conductor
        User driver = userRepository.findUserByIdUser(group.getIdDriver()).orElse(null);
        if (driver != null) {
            Map<String, Object> driverMap = new HashMap<>();
            driverMap.put("idUser", driver.getIdUser());
            driverMap.put("fullName", driver.getFirstname() + " " + driver.getLastname());
            driverMap.put("profilePhoto", driver.getProfile_photo());
            driverMap.put("role", "Conductor");
            driverMap.put("rating", driver.getRating());
            result.add(driverMap);
        }

        // Pasajeros
        List<GroupPassenger> passengers = groupPassengerRepository.findByIdGroup(groupId);
        for (GroupPassenger gp : passengers) {
            User passenger = userRepository.findUserByIdUser(gp.getIdUser()).orElse(null);
            if (passenger == null) continue;
            if (driver != null && passenger.getIdUser().equals(driver.getIdUser())) continue;

            Map<String, Object> map = new HashMap<>();
            map.put("idUser", passenger.getIdUser());
            map.put("fullName", passenger.getFirstname() + " " + passenger.getLastname());
            map.put("profilePhoto", passenger.getProfile_photo());
            map.put("role", "Pasajero");
            map.put("rating", passenger.getRating());
            result.add(map);
        }

        return result;
    }
}