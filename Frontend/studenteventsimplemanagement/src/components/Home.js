import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import { FiCalendar, FiMapPin, FiClock, FiSearch } from 'react-icons/fi';
import './Home.css';

function Home() {
  const navigate = useNavigate();
  const [events, setEvents] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    fetchApprovedEvents();
  }, []);

  const fetchApprovedEvents = async () => {
    try {
      const response = await axios.get('http://localhost:8080/api/events/approved');
      setEvents(response.data);
    } catch (error) {
      console.error('Error fetching events:', error);
    }
  };

  const handleSearch = async (e) => {
    const value = e.target.value;
    setSearchTerm(value);
    
    if (value.trim() === '') {
      fetchApprovedEvents();
    } else {
      try {
        const response = await axios.get(`http://localhost:8080/api/events/search?keyword=${value}`);
        setEvents(response.data.filter(event => event.status === 'APPROVED'));
      } catch (error) {
        console.error('Error searching events:', error);
      }
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

  return (
    <div className="home-container">
      <header className="home-header">
        <div className="header-content">
          <h1 className="logo">Student Event Management System</h1>
          <nav className="nav-menu">
            <a href="/">Home</a>
            <a href="#about">About</a>
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
          <button onClick={() => window.scrollTo({ top: 600, behavior: 'smooth' })} className="cta-button">
            View Approved Events
          </button>
        </div>
      </section>

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
            {events.length > 0 ? (
              events.slice(0, 6).map((event) => (
                <div key={event.id} className="event-card">
                  <div className="event-icon">
                    {event.title.includes('Cultural') ? (
                      <FiCalendar size={24} color="#4285f4" />
                    ) : event.title.includes('Hackathon') ? (
                      <span style={{ fontSize: '24px' }}>💻</span>
                    ) : (
                      <span style={{ fontSize: '24px' }}>⚽</span>
                    )}
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
