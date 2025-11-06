import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import { FiHome, FiPlusCircle, FiList, FiLogOut, FiCalendar, FiClock, FiMapPin } from 'react-icons/fi';
import './CreateEvent.css';

function CreateEvent() {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    date: '',
    time: '',
    location: ''
  });
  const [success, setSuccess] = useState('');
  const [error, setError] = useState('');

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setSuccess('');

    try {
      await axios.post('http://localhost:8080/api/events', {
        ...formData,
        status: 'PENDING'
      });
      setSuccess('Event created successfully!');
      setFormData({
        title: '',
        description: '',
        date: '',
        time: '',
        location: ''
      });
      setTimeout(() => {
        navigate('/manage-events');
      }, 1500);
    } catch (err) {
      setError('Failed to create event. Please try again.');
    }
  };

  const handleLogout = () => {
    localStorage.clear();
    navigate('/admin-login');
  };

  return (
    <div className="create-event-container">
      <aside className="sidebar">
        <div className="sidebar-menu">
          <button className="sidebar-item" onClick={() => navigate('/dashboard')}>
            <FiHome size={20} />
            <span>Dashboard</span>
          </button>
          <button className="sidebar-item active">
            <FiPlusCircle size={20} />
            <span>Create Event</span>
          </button>
          <button className="sidebar-item" onClick={() => navigate('/manage-events')}>
            <FiList size={20} />
            <span>Manage Events</span>
          </button>
        </div>
        <button className="sidebar-item logout" onClick={handleLogout}>
          <FiLogOut size={20} />
          <span>Log Out</span>
        </button>
      </aside>

      <main className="create-event-main">
        <div className="create-event-content">
          <h1 className="page-title">Create New Event</h1>

          <form onSubmit={handleSubmit} className="event-form">
            <div className="form-group">
              <label>Event Title</label>
              <input
                type="text"
                name="title"
                placeholder="Description"
                value={formData.title}
                onChange={handleChange}
                required
              />
            </div>

            <div className="form-group">
              <label>Description</label>
              <textarea
                name="description"
                placeholder="DressBall"
                value={formData.description}
                onChange={handleChange}
                rows="4"
                required
              />
            </div>

            <div className="form-row">
              <div className="form-group">
                <label>Date</label>
                <div className="input-with-icon">
                  <FiCalendar className="input-icon" />
                  <input
                    type="date"
                    name="date"
                    value={formData.date}
                    onChange={handleChange}
                    required
                  />
                </div>
              </div>

              <div className="form-group">
                <label>Time</label>
                <div className="input-with-icon">
                  <FiClock className="input-icon" />
                  <input
                    type="time"
                    name="time"
                    value={formData.time}
                    onChange={handleChange}
                    required
                  />
                </div>
              </div>
            </div>

            <div className="form-group">
              <label>Location</label>
              <div className="input-with-icon">
                <FiMapPin className="input-icon" />
                <input
                  type="text"
                  name="location"
                  placeholder="Enter location"
                  value={formData.location}
                  onChange={handleChange}
                  required
                />
              </div>
            </div>

            {success && <div className="success-message">{success}</div>}
            {error && <div className="error-message">{error}</div>}

            <div className="form-actions">
              <button type="button" onClick={() => navigate('/dashboard')} className="cancel-btn">
                Cancel
              </button>
              <button type="submit" className="submit-btn">
                Create Event
              </button>
            </div>
          </form>
        </div>
      </main>
    </div>
  );
}

export default CreateEvent;
