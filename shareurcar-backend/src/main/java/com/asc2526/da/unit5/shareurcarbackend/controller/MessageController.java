package com.asc2526.da.unit5.shareurcarbackend.controller;

import com.asc2526.da.unit5.shareurcarbackend.model.Message;
import com.asc2526.da.unit5.shareurcarbackend.service.MessageService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/messages")
public class MessageController {

    private final MessageService service;

    public MessageController(MessageService service) {
        this.service = service;
    }

    // GET mensajes de un grupo
    @GetMapping("/group/{groupId}")
    public List<Map<String, Object>> getByGroup(@PathVariable Integer groupId) {
        return service.getByGroup(groupId);
    }

    // POST enviar mensaje
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Message send(@Valid @RequestBody Message message) {
        return service.sendMessage(message);
    }

    // DELETE
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Integer id) {
        service.delete(id);
    }

    @GetMapping("/user/{userId}")
    public List<Map<String, Object>> getUserChats(@PathVariable Integer userId) { return service.getUserChats(userId); }

    @GetMapping("/group-by-route/{routeId}")
    public Integer getGroupIdByRoute(@PathVariable Integer routeId) { return service.getGroupIdByRoute(routeId); }

    @GetMapping("/group-members/{groupId}")
    public List<Map<String,Object>> getGroupMembers(@PathVariable Integer groupId) {
        return service.getGroupMembers(groupId);
    }
}