import React from 'react';
import { useNavigate } from 'react-router-dom';
import { FiCalendar, FiUsers, FiTarget, FiAward, FiHeart, FiTrendingUp } from 'react-icons/fi';
import './About.css';

function About() {
  const navigate = useNavigate();

  return (
    <div className="about-container">
      <header className="about-header">
        <div className="header-content">
          <h1 className="logo" onClick={() => navigate('/')}>Student Event Management System</h1>
          <nav className="nav-menu">
            <a href="/">Home</a>
            <a href="/about" className="active">About</a>
            <button onClick={() => navigate('/admin-login')} className="admin-login-btn">
              Admin Login
            </button>
          </nav>
        </div>
      </header>

      <section className="about-hero">
        <div className="hero-content">
          <h2 className="hero-title">About Our Platform</h2>
          <p className="hero-subtitle">
            Connecting students with amazing campus events and experiences
          </p>
        </div>
      </section>

      <section className="about-content-section">
        <div className="about-content">
          <div className="about-intro">
            <h2>Who We Are</h2>
            <p>
              The Student Event Management System is a comprehensive platform designed to streamline
              event management and enhance student engagement on campus. We believe that every student
              deserves easy access to exciting events, workshops, competitions, and cultural activities.
            </p>
            <p>
              Our mission is to create a centralized hub where students can discover, explore, and
              participate in campus events while administrators can efficiently manage and organize
              these activities.
            </p>
          </div>

          <div className="features-grid">
            <div className="feature-card">
              <div className="feature-icon">
                <FiCalendar size={32} />
              </div>
              <h3>Event Discovery</h3>
              <p>
                Browse and discover upcoming campus events in one convenient location. Never miss
                out on exciting opportunities again.
              </p>
            </div>

            <div className="feature-card">
              <div className="feature-icon">
                <FiUsers size={32} />
              </div>
              <h3>Community Building</h3>
              <p>
                Connect with fellow students through shared interests and activities. Build a
                stronger campus community together.
              </p>
            </div>

            <div className="feature-card">
              <div className="feature-icon">
                <FiTarget size={32} />
              </div>
              <h3>Easy Management</h3>
              <p>
                Administrators can easily create, approve, and manage events with our intuitive
                management dashboard.
              </p>
            </div>

            <div className="feature-card">
              <div className="feature-icon">
                <FiAward size={32} />
              </div>
              <h3>Quality Events</h3>
              <p>
                All events are reviewed and approved to ensure high-quality experiences for all
                participants.
              </p>
            </div>

            <div className="feature-card">
              <div className="feature-icon">
                <FiHeart size={32} />
              </div>
              <h3>Student-Focused</h3>
              <p>
                Built with students in mind, our platform prioritizes user experience and
                accessibility for everyone.
              </p>
            </div>

            <div className="feature-card">
              <div className="feature-icon">
                <FiTrendingUp size={32} />
              </div>
              <h3>Continuous Growth</h3>
              <p>
                We're constantly evolving and adding new features based on student feedback and
                campus needs.
              </p>
            </div>
          </div>

          <div className="mission-section">
            <h2>Our Mission</h2>
            <p>
              To empower students with seamless access to campus events and provide administrators
              with powerful tools to create memorable experiences. We strive to foster a vibrant
              campus culture where every student can find their place and make lasting connections.
            </p>
          </div>

          <div className="stats-section">
            <div className="stat-item">
              <div className="stat-number">500+</div>
              <div className="stat-label">Events Hosted</div>
            </div>
            <div className="stat-item">
              <div className="stat-number">2000+</div>
              <div className="stat-label">Active Students</div>
            </div>
            <div className="stat-item">
              <div className="stat-number">50+</div>
              <div className="stat-label">Student Organizations</div>
            </div>
            <div className="stat-item">
              <div className="stat-number">95%</div>
              <div className="stat-label">Satisfaction Rate</div>
            </div>
          </div>

          <div className="cta-section">
            <h2>Ready to Get Started?</h2>
            <p>Join thousands of students discovering amazing campus events every day.</p>
            <button onClick={() => navigate('/')} className="cta-button">
              Explore Events
            </button>
          </div>
        </div>
      </section>

      <footer className="about-footer">
        <p>&copy; 2025 Student Event Management System. All rights reserved.</p>
      </footer>
    </div>
  );
}

export default About;
