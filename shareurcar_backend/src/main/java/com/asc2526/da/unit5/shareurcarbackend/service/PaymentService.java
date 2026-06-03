package com.asc2526.da.unit5.shareurcarbackend.service;

import com.asc2526.da.unit5.shareurcarbackend.exception.AlreadyExistsException;
import com.asc2526.da.unit5.shareurcarbackend.model.Payment;
import com.asc2526.da.unit5.shareurcarbackend.model.TravelGroup;
import com.asc2526.da.unit5.shareurcarbackend.model.User;
import com.asc2526.da.unit5.shareurcarbackend.repository.PaymentRepository;
import com.asc2526.da.unit5.shareurcarbackend.repository.TravelGroupRepository;
import com.asc2526.da.unit5.shareurcarbackend.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class PaymentService {

    private final PaymentRepository repository;
    private final UserRepository userRepository;
    private final TravelGroupRepository travelGroupRepository;


    public PaymentService(PaymentRepository repository, UserRepository userRepository, TravelGroupRepository travelGroupRepository) {
        this.repository = repository;
        this.userRepository = userRepository;
        this.travelGroupRepository = travelGroupRepository;
    }

    public List<Payment> getByGroup(Integer groupId) {
        return repository.findByGroup(groupId);
    }

    public List<Payment> getByUser(Integer userId) {
        return repository.findByUser(userId);
    }

    public Payment create(Payment payment) {
        if (repository.existsByIdGroupAndIdUser(payment.getIdGroup(), payment.getIdUser())) {
            throw new AlreadyExistsException("Pago ya realizado");
        }
        payment.setCreatedAt(LocalDateTime.now());
        payment.setPaymentStatus("PENDING");
        return repository.save(payment);
    }

    public Payment markAsCompleted(Integer id) {
        Payment payment = repository.findById(id).orElseThrow(() -> new RuntimeException("Pago no encontrado: " + id));
        User passenger = userRepository.findUserByIdUser(payment.getIdUser()).orElseThrow();

        TravelGroup group = travelGroupRepository.findById(payment.getIdGroup()).orElseThrow();
        User driver = userRepository.findUserByIdUser(group.getIdDriver()).orElseThrow();

        double amount = payment.getAmount();

        passenger.setHeldBalance(passenger.getHeldBalance() - amount);
        passenger.setBalance(passenger.getBalance() - amount);
        driver.setBalance(driver.getBalance() + amount);

        userRepository.save(passenger);
        userRepository.save(driver);
        payment.setPaymentStatus("COMPLETED");
        return repository.save(payment);
    }
    public Payment markAsFailed(Integer id) {
        Payment payment = repository.findById(id).orElseThrow(() -> new RuntimeException("Pago no encontrado: " + id));
        payment.setPaymentStatus("FAILED");
        return repository.save(payment);
    }

    public void delete(Integer id) {
        repository.deleteById(id);
    }
}