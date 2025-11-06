package com.studentevent.service;

import com.studentevent.model.Event;
import com.studentevent.repository.EventRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class EventService {

    @Autowired
    private EventRepository eventRepository;

    public List<Event> getAllEvents() {
        return eventRepository.findAll();
    }

    // Get approved events sorted by date (ascending)
    public List<Event> getApprovedEventsSortedByDate() {
        return eventRepository.findByStatusOrderByDateAscTimeAsc("APPROVED");
    }

    // Get recent events (PENDING + APPROVED) excluding REJECTED, sorted by date
    public List<Event> getRecentEventsSortedByDate() {
        return eventRepository.findRecentEventsExcludingRejected();
    }

    public List<Event> getApprovedEvents() {
        return eventRepository.findByStatus("APPROVED");
    }

    public Optional<Event> getEventById(Long id) {
        return eventRepository.findById(id);
    }

    public Event createEvent(Event event) {
        return eventRepository.save(event);
    }

    public Event updateEvent(Long id, Event eventDetails) {
        Event event = eventRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Event not found"));

        event.setTitle(eventDetails.getTitle());
        event.setDescription(eventDetails.getDescription());
        event.setDate(eventDetails.getDate());
        event.setTime(eventDetails.getTime());
        event.setLocation(eventDetails.getLocation());
        event.setStatus(eventDetails.getStatus());

        return eventRepository.save(event);
    }

    public void deleteEvent(Long id) {
        eventRepository.deleteById(id);
    }

    public Event approveEvent(Long id) {
        Event event = eventRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Event not found"));
        event.setStatus("APPROVED");
        return eventRepository.save(event);
    }

    public Event rejectEvent(Long id) {
        Event event = eventRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Event not found"));
        event.setStatus("REJECTED");
        return eventRepository.save(event);
    }

    public List<Event> searchEvents(String keyword) {
        return eventRepository.searchNonRejectedEvents(keyword);
    }

    public long countEventsByStatus(String status) {
        return eventRepository.findByStatus(status).size();
    }
}
