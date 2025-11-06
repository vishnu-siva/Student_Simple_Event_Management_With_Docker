package com.studentevent.service;

import com.studentevent.dto.LoginRequest;
import com.studentevent.dto.LoginResponse;
import com.studentevent.model.Admin;
import com.studentevent.repository.AdminRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class AdminService {

    @Autowired
    private AdminRepository adminRepository;

    public LoginResponse login(LoginRequest loginRequest) {
        Optional<Admin> admin = adminRepository
                .findByEmailAndPassword(loginRequest.getEmail(), loginRequest.getPassword());

        if (admin.isPresent()) {
            Admin adminData = admin.get();
            return new LoginResponse(
                    adminData.getId(),
                    adminData.getName(),
                    adminData.getEmail(),
                    "Login successful"
            );
        } else {
            return new LoginResponse(null, null, null, "Invalid credentials");
        }
    }

    public Admin createAdmin(Admin admin) {
        return adminRepository.save(admin);
    }

    public Optional<Admin> getAdminById(Long id) {
        return adminRepository.findById(id);
    }
}
