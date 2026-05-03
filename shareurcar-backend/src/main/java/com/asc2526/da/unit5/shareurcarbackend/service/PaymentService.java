package com.asc2526.da.unit5.shareurcarbackend.service;

import com.asc2526.da.unit5.shareurcarbackend.exception.AlreadyExistsException;
import com.asc2526.da.unit5.shareurcarbackend.model.Payment;
import com.asc2526.da.unit5.shareurcarbackend.repository.PaymentRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class PaymentService {

    private final PaymentRepository repository;

    public PaymentService(PaymentRepository repository) {
        this.repository = repository;
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
        payment.setPaymentStatus("pendiente");
        return repository.save(payment);
    }

    public Payment markAsCompleted(Integer id) {
        Payment payment = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Pago no encontrado: " + id));

        payment.setPaymentStatus("completado");
        return repository.save(payment);
    }

    public void delete(Integer id) {
        repository.deleteById(id);
    }
}