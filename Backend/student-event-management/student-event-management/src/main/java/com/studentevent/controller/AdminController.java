package com.studentevent.controller;

import com.studentevent.dto.LoginRequest;
import com.studentevent.dto.LoginResponse;
import com.studentevent.model.Admin;
import com.studentevent.service.AdminService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin")
@CrossOrigin(origins = {
    "http://localhost:3000",
    "http://localhost",           // ✅ Added: local port 80
    "http://localhost:80",        // ✅ Added: explicit port 80
    "http://98.95.8.184:3000",    // Port 3000
    "http://98.95.8.184",         // ✅ Added: production port 80 (default)
    "http://98.95.8.184:80"       // ✅ Added: explicit port 80
})
public class AdminController {

    @Autowired
    private AdminService adminService;

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@RequestBody LoginRequest loginRequest) {
        LoginResponse response = adminService.login(loginRequest);
        if (response.getId() != null) {
            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
        }
    }

    @PostMapping("/register")
    public ResponseEntity<Admin> createAdmin(@RequestBody Admin admin) {
        Admin createdAdmin = adminService.createAdmin(admin);
        return ResponseEntity.status(HttpStatus.CREATED).body(createdAdmin);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Admin> getAdminById(@PathVariable Long id) {
        return adminService.getAdminById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}
