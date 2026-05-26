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

    public MessageService(MessageRepository repository, TravelGroupRepository travelGroupRepository, RouteRepository routeRepository,
                          UserRepository userRepository, GroupPassengerRepository groupPassengerRepository) {
        this.messageRepository = repository;
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
            User user = userRepository.findUserByIdUser(m.getIdUser()).orElseThrow();
            Map<String, Object> map = new HashMap<>();
            map.put("idMessage", m.getIdMessage());
            map.put("idUser", m.getIdUser());
            map.put("text", m.getText());
            map.put("sentAt", m.getSentAt());
            map.put("fullName", user.getFirstname() + " " + user.getLastname());
            map.put("isDriver", group.getIdDriver().equals(m.getIdUser()));
            result.add(map);
        }
        return result;
    }

    public void delete(Integer id) {
        messageRepository.deleteById(id);
    }

    public List<Map<String, Object>> getUserChats(Integer userId) {
        List<Route> routes = routeRepository.findMyRoutes(userId);
        List<Map<String, Object>> chats = new ArrayList<>();
        for (Route route : routes) {
            Optional<TravelGroup> groupOpt = travelGroupRepository.findByIdRoute(route.getIdRoute());
            if (groupOpt.isEmpty())
                continue;

            TravelGroup group = groupOpt.get();
            List<Message> messages = messageRepository.findByGroup(group.getIdGroup());
            String lastMessage = "Todavía no hay mensajes";

            if (!messages.isEmpty()) {
                lastMessage = messages.get(messages.size() - 1).getText();
            }
            Map<String, Object> chat = new HashMap<>();
            chat.put("id_group", group.getIdGroup());
            chat.put("destination", route.getDestination());
            chat.put("lastMessage", lastMessage);
            chat.put("travel_time", group.getTravelTime());
            chat.put("ruta", route);
            chats.add(chat);
        }
        return chats;
    }

    public Integer getGroupIdByRoute(Integer routeId) {
        TravelGroup group = travelGroupRepository.findByIdRoute(routeId)
                        .orElseThrow(() -> new RuntimeException("Grupo no encontrado"));
        return group.getIdGroup();
    }

    public Message sendMessage(Message message) {
        if (!travelGroupRepository.existsById(message.getIdGroup())) {
            throw new RuntimeException("Grupo no existe");
        }
        message.setSentAt(LocalDateTime.now());
        return messageRepository.save(message);
    }

    public List<Map<String, Object>> getGroupMembers(Integer groupId) {
        TravelGroup group = travelGroupRepository.findById(groupId).orElseThrow();
        List<Map<String, Object>> result = new ArrayList<>();
        User driver = userRepository.findUserByIdUser(group.getIdDriver()).orElseThrow();

        Map<String, Object> driverMap = new HashMap<>();

        driverMap.put("idUser", driver.getIdUser());
        driverMap.put("fullName", driver.getFirstname() + " " + driver.getLastname());
        driverMap.put("profilePhoto", driver.getProfile_photo());
        driverMap.put("role", "Conductor");
        result.add(driverMap);

        List<GroupPassenger> passengers = groupPassengerRepository.findByIdGroup(groupId);
        for (GroupPassenger gp : passengers) {
            User passenger = userRepository.findUserByIdUser(gp.getIdUser()).orElseThrow();
            Map<String, Object> map = new HashMap<>();

            map.put("idUser", passenger.getIdUser());
            map.put("fullName", passenger.getFirstname() + " " + passenger.getLastname());
            map.put("profilePhoto", passenger.getProfile_photo());
            map.put("role", "Pasajero");
            result.add(map);
        }
        return result;
    }
}