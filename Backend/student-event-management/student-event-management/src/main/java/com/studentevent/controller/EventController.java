package com.studentevent.controller;

import com.studentevent.model.Event;
import com.studentevent.service.EventService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/events")
@CrossOrigin(origins = {
    "http://localhost:3000",
    "http://98.95.8.184:3000"
})
public class EventController {

    @Autowired
    private EventService eventService;

    @GetMapping
    public ResponseEntity<List<Event>> getAllEvents() {
        return ResponseEntity.ok(eventService.getAllEvents());
    }

    @GetMapping("/approved")
    public ResponseEntity<List<Event>> getApprovedEvents() {
        return ResponseEntity.ok(eventService.getApprovedEventsSortedByDate());
    }

    @GetMapping("/recent")
    public ResponseEntity<List<Event>> getRecentEvents() {
        return ResponseEntity.ok(eventService.getRecentEventsSortedByDate());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Event> getEventById(@PathVariable Long id) {
        return eventService.getEventById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<Event> createEvent(@RequestBody Event event) {
        Event createdEvent = eventService.createEvent(event);
        return ResponseEntity.status(HttpStatus.CREATED).body(createdEvent);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Event> updateEvent(@PathVariable Long id, @RequestBody Event event) {
        try {
            Event updatedEvent = eventService.updateEvent(id, event);
            return ResponseEntity.ok(updatedEvent);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, String>> deleteEvent(@PathVariable Long id) {
        eventService.deleteEvent(id);
        Map<String, String> response = new HashMap<>();
        response.put("message", "Event deleted successfully");
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{id}/approve")
    public ResponseEntity<Event> approveEvent(@PathVariable Long id) {
        try {
            Event approvedEvent = eventService.approveEvent(id);
            return ResponseEntity.ok(approvedEvent);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @PutMapping("/{id}/reject")
    public ResponseEntity<Event> rejectEvent(@PathVariable Long id) {
        try {
            Event rejectedEvent = eventService.rejectEvent(id);
            return ResponseEntity.ok(rejectedEvent);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/search")
    public ResponseEntity<List<Event>> searchEvents(@RequestParam String keyword) {
        return ResponseEntity.ok(eventService.searchEvents(keyword));
    }

    @GetMapping("/count")
    public ResponseEntity<Map<String, Long>> getEventCounts() {
        Map<String, Long> counts = new HashMap<>();
        counts.put("approved", eventService.countEventsByStatus("APPROVED"));
        counts.put("pending", eventService.countEventsByStatus("PENDING"));
        counts.put("rejected", eventService.countEventsByStatus("REJECTED"));
        counts.put("total", (long) eventService.getAllEvents().size());
        return ResponseEntity.ok(counts);
    }
}
