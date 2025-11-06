import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import { FiHome, FiPlusCircle, FiList, FiLogOut } from 'react-icons/fi';
import './Dashboard.css';

function Dashboard() {
  const navigate = useNavigate();
  const [adminName, setAdminName] = useState('');
  const [adminEmail, setAdminEmail] = useState('');
  const [eventCounts, setEventCounts] = useState({
    approved: 0,
    total: 0
  });

  useEffect(() => {
    const name = localStorage.getItem('adminName');
    const email = localStorage.getItem('adminEmail');
    
    if (!name || !email) {
      navigate('/dashboard');
      return;
    }

    setAdminName(name);
    setAdminEmail(email);
    fetchEventCounts();
  }, [navigate]);

  const fetchEventCounts = async () => {
    try {
      const response = await axios.get('http://localhost:8080/api/events/count');
      setEventCounts({
        approved: response.data.approved,
        total: response.data.total - response.data.rejected
      });
    } catch (error) {
      console.error('Error fetching event counts:', error);
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('adminId');
    localStorage.removeItem('adminName');
    localStorage.removeItem('adminEmail');
    navigate('/admin-login');
  };

  const getInitial = (name) => {
    return name ? name.charAt(0).toUpperCase() : 'A';
  };

  return (
    <div className="dashboard-container">
      <aside className="sidebar">
        <div className="sidebar-menu">
          <button className="sidebar-item active">
            <FiHome size={20} />
            <span>Dashboard</span>
          </button>
          <button className="sidebar-item" onClick={() => navigate('/create-event')}>
            <FiPlusCircle size={20} />
            <span>Create Events</span>
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

      <main className="dashboard-main">
        <div className="dashboard-content">
          <div className="admin-profile">
            <div className="avatar">{getInitial(adminName)}</div>
            <div className="admin-info">
              <h2>{adminName}</h2>
              <p>{adminEmail}</p>
            </div>
            <button onClick={handleLogout} className="logout-btn">Logout</button>
          </div>

          <div className="stats-grid">
            <div className="stat-card">
              <h3>Approved Events</h3>
              <div className="stat-value">{eventCounts.approved}</div>
            </div>
            <div className="stat-card">
              <h3>Created Events</h3>
              <div className="stat-value">{eventCounts.total}</div>
            </div>
          </div>

          <button onClick={() => navigate('/create-event')} className="create-event-btn">
            <FiPlusCircle size={20} />
            <span>Create Event</span>
          </button>
        </div>
      </main>
    </div>
  );
}

export default Dashboard;
