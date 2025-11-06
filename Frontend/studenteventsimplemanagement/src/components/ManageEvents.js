import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import { FiHome, FiPlusCircle, FiList, FiLogOut, FiSearch, FiEdit2, FiTrash2, FiCheck, FiX } from 'react-icons/fi';
import './ManageEvents.css';

function ManageEvents() {
  const navigate = useNavigate();
  const [events, setEvents] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [filteredEvents, setFilteredEvents] = useState([]);

  useEffect(() => {
    fetchEvents();
  }, []);

  const fetchEvents = async () => {
    try {
      const response = await axios.get('http://localhost:8080/api/events');
      setEvents(response.data);
      setFilteredEvents(response.data);
    } catch (error) {
      console.error('Error fetching events:', error);
    }
  };

  const handleSearch = (value) => {
    setSearchTerm(value);
    if (value.trim() === '') {
      setFilteredEvents(events);
    } else {
      const filtered = events.filter(event =>
        event.title.toLowerCase().includes(value.toLowerCase()) ||
        event.location.toLowerCase().includes(value.toLowerCase())
      );
      setFilteredEvents(filtered);
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this event?')) {
      try {
        await axios.delete(`http://localhost:8080/api/events/${id}`);
        fetchEvents();
      } catch (error) {
        console.error('Error deleting event:', error);
      }
    }
  };

  const handleApprove = async (id) => {
    try {
      await axios.put(`http://localhost:8080/api/events/${id}/approve`);
      fetchEvents();
    } catch (error) {
      console.error('Error approving event:', error);
    }
  };

  const handleReject = async (id) => {
    try {
      await axios.put(`http://localhost:8080/api/events/${id}/reject`);
      fetchEvents();
    } catch (error) {
      console.error('Error rejecting event:', error);
    }
  };

  const formatDate = (date) => {
    return new Date(date).toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric', 
      year: 'numeric' 
    });
  };

  const handleLogout = () => {
    localStorage.clear();
    navigate('/admin-login');
  };

  return (
    <div className="manage-events-container">
      <aside className="sidebar">
        <div className="sidebar-menu">
          <button className="sidebar-item" onClick={() => navigate('/dashboard')}>
            <FiHome size={20} />
            <span>Dashboard</span>
          </button>
          <button className="sidebar-item" onClick={() => navigate('/create-event')}>
            <FiPlusCircle size={20} />
            <span>Create Events</span>
          </button>
          <button className="sidebar-item active">
            <FiList size={20} />
            <span>Manage Events</span>
          </button>
        </div>
        <button className="sidebar-item logout" onClick={handleLogout}>
          <FiLogOut size={20} />
          <span>Log Out</span>
        </button>
      </aside>

      <main className="manage-events-main">
        <div className="manage-events-content">
          <h1 className="page-title">Manage Events</h1>

          <div className="search-container">
            <FiSearch className="search-icon" />
            <input
              type="text"
              placeholder="Search"
              value={searchTerm}
              onChange={(e) => handleSearch(e.target.value)}
              className="search-input"
            />
          </div>

          <div className="table-container">
            <table className="events-table">
              <thead>
                <tr>
                  <th>Title</th>
                  <th>Date</th>
                  <th>Location</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredEvents.map((event) => (
                  <tr key={event.id}>
                    <td>{event.title}</td>
                    <td>{formatDate(event.date)}</td>
                    <td>{event.location}</td>
                    <td>
                      <div className="action-buttons">
                        <button className="action-btn edit-btn" title="Edit">
                          <FiEdit2 size={16} />
                        </button>
                        <button 
                          className="action-btn delete-btn" 
                          onClick={() => handleDelete(event.id)}
                          title="Delete"
                        >
                          <FiTrash2 size={16} />
                        </button>
                        <button 
                          className={`status-btn approve-btn ${event.status === 'APPROVED' ? 'active' : ''}`}
                          onClick={() => handleApprove(event.id)}
                          disabled={event.status === 'APPROVED'}
                        >
                          {event.status === 'APPROVED' ? '✓ Approved' : 'Approve'}
                        </button>
                        <button 
                          className={`status-btn reject-btn ${event.status === 'REJECTED' ? 'active' : ''}`}
                          onClick={() => handleReject(event.id)}
                          disabled={event.status === 'REJECTED'}
                        >
                          {event.status === 'REJECTED' ? '✕ Rejected' : 'Reject'}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {filteredEvents.length === 0 && (
              <div className="no-events">No events found</div>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}

export default ManageEvents;
