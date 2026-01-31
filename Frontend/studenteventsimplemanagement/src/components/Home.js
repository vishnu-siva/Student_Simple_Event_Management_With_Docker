import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import { FiCalendar, FiMapPin, FiClock, FiSearch } from 'react-icons/fi';
import './Home.css';
import API_BASE_URL from '../config';

function Home() {
  const navigate = useNavigate();
  const [recentEvents, setRecentEvents] = useState([]);
  const [approvedEvents, setApprovedEvents] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    fetchRecentEvents();
    fetchApprovedEvents();
  }, []);

  const fetchRecentEvents = async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/events/recent`);
      // Ensure response.data is an array
      const data = Array.isArray(response.data) ? response.data : [];
      setRecentEvents(data);
    } catch (error) {
      console.error('Error fetching recent events:', error);
      setRecentEvents([]);
    }
  };

  const fetchApprovedEvents = async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/events/approved`);
      // Ensure response.data is an array
      const data = Array.isArray(response.data) ? response.data : [];
      setApprovedEvents(data);
    } catch (error) {
      console.error('Error fetching approved events:', error);
      setApprovedEvents([]);
    }
  };

  const handleSearch = async (e) => {
    const value = e.target.value;
    setSearchTerm(value);
    
    if (value.trim() === '') {
      fetchRecentEvents();
    } else {
      try {
        const response = await axios.get(`${API_BASE_URL}/api/events/search?keyword=${value}`);
        // Ensure response.data is an array
        const data = Array.isArray(response.data) ? response.data : [];
        setRecentEvents(data);
      } catch (error) {
        console.error('Error searching events:', error);
        setRecentEvents([]);
      }
    }
  };

  const scrollToApprovedEvents = () => {
    const approvedSection = document.getElementById('approved-events-section');
    if (approvedSection) {
      approvedSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  };

  const formatDate = (date) => {
    return new Date(date).toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric', 
      year: 'numeric' 
    });
  };

  const formatTime = (time) => {
    const [hours, minutes] = time.split(':');
    const hour = parseInt(hours);
    const ampm = hour >= 12 ? 'PM' : 'AM';
    const displayHour = hour % 12 || 12;
    return `${displayHour}:${minutes} ${ampm}`;
  };

  const getEventIcon = (title) => {
    if (title.toLowerCase().includes('cultural')) {
      return <FiCalendar size={24} color="#4285f4" />;
    } else if (title.toLowerCase().includes('hackathon') || title.toLowerCase().includes('tech')) {
      return <span style={{ fontSize: '24px' }}>💻</span>;
    } else if (title.toLowerCase().includes('sports')) {
      return <span style={{ fontSize: '24px' }}>⚽</span>;
    } else if (title.toLowerCase().includes('music')) {
      return <span style={{ fontSize: '24px' }}>🎵</span>;
    } else {
      return <FiCalendar size={24} color="#4285f4" />;
    }
  };

  const getStatusBadge = (status) => {
    if (status === 'APPROVED') {
      return <span className="status-badge approved">Approved</span>;
    } else if (status === 'PENDING') {
      return <span className="status-badge pending">Pending</span>;
    }
    return null;
  };

  return (
    <div className="home-container">
      <header className="home-header">
        <div className="header-content">
          <h1 className="logo">Student Event Management System</h1>
            <nav className="nav-menu">
              <a href="/">Home</a>
              <a href="/about">About</a>
              <button onClick={() => navigate('/admin-login')} className="admin-login-btn">
                 Admin Login
              </button>
            </nav>

        </div>
      </header>

      <section className="hero-section">
        <div className="hero-content">
          <h2 className="hero-title">Explore campus events in one place!</h2>
          <p className="hero-subtitle">Stay up-to-date with the latest happenings on campus.</p>
          <button onClick={scrollToApprovedEvents} className="cta-button">
            View Approved Events
          </button>
        </div>
      </section>

      {/* Recent Events Section - Shows All (Approved + Pending) */}
      <section className="events-section">
        <div className="events-container">
          <div className="section-header">
            <h2>Recent Events</h2>
            <div className="search-box">
              <FiSearch className="search-icon" />
              <input
                type="text"
                placeholder="Search..."
                value={searchTerm}
                onChange={handleSearch}
                className="search-input"
              />
            </div>
          </div>

          <div className="events-grid">
            {recentEvents.length > 0 ? (
              recentEvents.map((event) => (
                <div key={event.id} className="event-card">
                  <div className="event-header">
                    <div className="event-icon">
                      {getEventIcon(event.title)}
                    </div>
                    {getStatusBadge(event.status)}
                  </div>
                  <h3 className="event-title">{event.title}</h3>
                  <div className="event-details">
                    <div className="event-detail">
                      <FiMapPin size={16} />
                      <span>{event.location}</span>
                    </div>
                    <div className="event-detail">
                      <FiClock size={16} />
                      <span>{formatDate(event.date)} – {formatTime(event.time)}</span>
                    </div>
                  </div>
                </div>
              ))
            ) : (
              <p className="no-events">No recent events available at the moment.</p>
            )}
          </div>
        </div>
      </section>

      {/* Approved Events Section - Shows Only Approved */}
      <section id="approved-events-section" className="approved-events-section">
        <div className="events-container">
          <div className="section-header">
            <h2>Approved Events</h2>
          </div>

          <div className="events-grid">
            {approvedEvents.length > 0 ? (
              approvedEvents.map((event) => (
                <div key={event.id} className="event-card approved-card">
                  <div className="event-header">
                    <div className="event-icon">
                      {getEventIcon(event.title)}
                    </div>
                    <span className="status-badge approved">Approved</span>
                  </div>
                  <h3 className="event-title">{event.title}</h3>
                  <div className="event-details">
                    <div className="event-detail">
                      <FiMapPin size={16} />
                      <span>{event.location}</span>
                    </div>
                    <div className="event-detail">
                      <FiClock size={16} />
                      <span>{formatDate(event.date)} – {formatTime(event.time)}</span>
                    </div>
                  </div>
                </div>
              ))
            ) : (
              <p className="no-events">No approved events available at the moment.</p>
            )}
          </div>
        </div>
      </section>
    </div>
  );
}

export default Home;
