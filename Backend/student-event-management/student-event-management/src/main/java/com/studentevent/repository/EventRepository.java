package com.studentevent.repository;

import com.studentevent.model.Event;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface EventRepository extends JpaRepository<Event, Long> {
    List<Event> findByStatus(String status);
    List<Event> findByTitleContainingIgnoreCase(String title);

    // Get approved events sorted by date ascending
    List<Event> findByStatusOrderByDateAscTimeAsc(String status);

    // Get events that are not rejected, sorted by date ascending
    @Query("SELECT e FROM Event e WHERE e.status != 'REJECTED' ORDER BY e.date ASC, e.time ASC")
    List<Event> findRecentEventsExcludingRejected();

    // Get all non-rejected events for search
    @Query("SELECT e FROM Event e WHERE e.status != 'REJECTED' AND (LOWER(e.title) LIKE LOWER(CONCAT('%', ?1, '%')) OR LOWER(e.location) LIKE LOWER(CONCAT('%', ?1, '%')))")
    List<Event> searchNonRejectedEvents(String keyword);
}
