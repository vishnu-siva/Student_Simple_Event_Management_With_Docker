import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Home from './components/Home';
import About from './components/About';
import AdminLogin from './components/AdminLogin';
import Dashboard from './components/Dashboard';
import CreateEvent from './components/CreateEvent';
import ManageEvents from './components/ManageEvents';
import './App.css';

function App() {
  return (
    <Router>
      <div className="App">
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/about" element={<About />} />
          <Route path="/admin-login" element={<AdminLogin />} />
          <Route path="/dashboard" element={<Dashboard />} />
          <Route path="/create-event" element={<CreateEvent />} />
          <Route path="/manage-events" element={<ManageEvents />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
