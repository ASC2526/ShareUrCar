package com.asc2526.da.unit5.shareurcarbackend.service;

import com.asc2526.da.unit5.shareurcarbackend.model.Message;
import com.asc2526.da.unit5.shareurcarbackend.repository.MessageRepository;
import com.asc2526.da.unit5.shareurcarbackend.repository.TravelGroupRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class MessageService {

    private final MessageRepository messageRepository;
    private final TravelGroupRepository travelGroupRepository;

    public MessageService(MessageRepository repository, TravelGroupRepository travelGroupRepository) {
        this.messageRepository = repository;
        this.travelGroupRepository = travelGroupRepository;
    }

    public List<Message> getByGroup(Integer groupId) {
        return messageRepository.findByGroup(groupId);
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
}