package com.asc2526.da.unit5.shareurcarbackend.service;

import com.asc2526.da.unit5.shareurcarbackend.model.*;
import com.asc2526.da.unit5.shareurcarbackend.repository.*;
import com.asc2526.da.unit5.shareurcarbackend.util.RouteMapper;
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
    private final DriverRepository driverRepository;

    public MessageService(MessageRepository messageRepository,
                          TravelGroupRepository travelGroupRepository,
                          RouteRepository routeRepository,
                          UserRepository userRepository,
                          GroupPassengerRepository groupPassengerRepository, DriverRepository driverRepository) {
        this.messageRepository = messageRepository;
        this.travelGroupRepository = travelGroupRepository;
        this.routeRepository = routeRepository;
        this.userRepository = userRepository;
        this.groupPassengerRepository = groupPassengerRepository;
        this.driverRepository = driverRepository;
    }

    public List<Map<String, Object>> getByGroup(Integer groupId) {
        TravelGroup group = travelGroupRepository.findById(groupId).orElseThrow();
        return messageRepository.findByGroup(groupId).stream().map(m -> {
            User user = userRepository.findUserByIdUser(m.getIdUser()).orElse(null);
            Map<String, Object> map = new HashMap<>();
            map.put("idMessage",    m.getIdMessage());
            map.put("idUser",       m.getIdUser());
            map.put("text",         m.getText());
            map.put("sentAt",       m.getSentAt());
            map.put("fullName",     user != null ? user.getFirstname() + " " + user.getLastname() : "Usuario");
            map.put("profilePhoto", user != null ? user.getProfile_photo() : null);
            map.put("isDriver",     group.getIdDriver().equals(m.getIdUser()));
            return map;
        }).toList();
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
        Set<Integer> groupIds = new LinkedHashSet<>();
        travelGroupRepository.findByIdDriver(userId).forEach(g -> groupIds.add(g.getIdGroup()));
        groupPassengerRepository.findByIdUser(userId).forEach(gp -> groupIds.add(gp.getIdGroup()));

        List<Map<String, Object>> result = new ArrayList<>();

        for (Integer groupId : groupIds) {
            TravelGroup group = travelGroupRepository.findById(groupId).orElse(null);
            if (group == null) continue;
            Route route = routeRepository.findById(group.getIdRoute()).orElse(null);
            if (route == null) continue;

            User driver = userRepository.findUserByIdUser(route.getIdDriver()).orElse(null);
            String driverName = driver != null
                    ? driver.getFirstname() + " " + driver.getLastname() : "Conductor";
            Integer maxSeats = driverRepository.findByIdDriver(route.getIdDriver())
                    .map(Driver::getMaxSeats).orElse(4);

            List<Message> messages = messageRepository.findByGroup(groupId);
            String lastMessage = messages.isEmpty() ? "" : messages.get(messages.size() - 1).getText();
            String lastMessageAt = messages.isEmpty() ? null
                    : messages.get(messages.size() - 1).getSentAt() != null
                    ? messages.get(messages.size() - 1).getSentAt().toString()
                    : null;

            Map<String, Object> chatMap = new HashMap<>();
            chatMap.put("idGroup",     groupId);
            chatMap.put("idRoute",     route.getIdRoute());
            chatMap.put("destination", route.getDestination());
            chatMap.put("origin",      route.getOrigin());
            chatMap.put("travel_date", route.getTravel_date() != null ? route.getTravel_date().toString() : null);
            chatMap.put("travel_time", route.getDeparture_time() != null ? route.getDeparture_time().toString() : null);
            chatMap.put("lastMessage", lastMessage);
            chatMap.put("driverName",  driverName);
            chatMap.put("driverId",    route.getIdDriver());
            chatMap.put("seriesId",    route.getSeriesId());
            chatMap.put("status",      route.getStatus());
            chatMap.put("ruta",        RouteMapper.toMap(route, driverName, maxSeats));
            chatMap.put("lastMessageAt", lastMessageAt);

            result.add(chatMap);
        }

        result.sort((a, b) -> {
            String dA = (String) a.get("lastMessageAt");
            String dB = (String) b.get("lastMessageAt");
            if (dA == null && dB == null) return 0;
            if (dA == null) return 1;
            if (dB == null) return -1;
            return dB.compareTo(dA);
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

        userRepository.findUserByIdUser(group.getIdDriver()).ifPresent(driver ->
                result.add(memberMap(driver, "Conductor")));

        groupPassengerRepository.findByIdGroup(groupId).forEach(gp -> {
            User passenger = userRepository.findUserByIdUser(gp.getIdUser()).orElse(null);
            if (passenger == null || passenger.getIdUser().equals(group.getIdDriver())) return;
            result.add(memberMap(passenger, "Pasajero"));
        });

        return result;
    }

    private Map<String, Object> memberMap(User user, String role) {
        Map<String, Object> m = new HashMap<>();
        m.put("idUser",       user.getIdUser());
        m.put("fullName",     user.getFirstname() + " " + user.getLastname());
        m.put("profilePhoto", user.getProfile_photo());
        m.put("role",         role);
        m.put("rating",       user.getRating());
        return m;
    }
}