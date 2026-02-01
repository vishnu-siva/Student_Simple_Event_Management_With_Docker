# Complete Deployment Guide - Student Event Management System

**Date**: January 31, 2026  
**EC2 Instance**: i-0e91a17492dc81172 (t3.small)  
**Public IP**: 98.95.8.184  
**Application URLs**:
- Frontend: http://98.95.8.184:3000
- Backend API: http://98.95.8.184:8080/api/events

---

## Table of Contents
1. [Overview](#overview)
2. [All Changes Made](#all-changes-made)
3. [Configuration Files](#configuration-files)
4. [Shell Scripts](#shell-scripts)
5. [AWS Systems Manager](#aws-systems-manager)
6. [Deployment Workflow](#deployment-workflow)
7. [Troubleshooting Guide](#troubleshooting-guide)

---

## Overview

This system is a full-stack event management application with:
- **Backend**: Spring Boot 3.5.7 (Java 24) - Port 8080
- **Frontend**: React 19 - Port 3000
- **Database**: MySQL 8.0 - Port 3306
- **Deployment**: Jenkins CI/CD → Docker Hub → AWS EC2
- **Infrastructure**: Docker Compose, AWS SSM, Terraform

---

## All Changes Made

### 1. **SecurityConfig.java - Fixed CORS Configuration**
**File**: `Backend/student-event-management/student-event-management/src/main/java/com/studentevent/config/SecurityConfig.java`

**Problem**: Duplicate `http://` in CORS origin and semicolon instead of comma

**Fix**:
```java
@CrossOrigin(origins = {
    "http://localhost:3000",
    "http://98.95.8.184:3000"  // ✅ Fixed: removed duplicate http://
})
```

**Commit**: eb51118

---

### 2. **CorsConfig.java - Added Missing Imports and Production IP**
**File**: `Backend/student-event-management/student-event-management/src/main/java/com/studentevent/config/CorsConfig.java`

**Problem**: Missing imports and production IP not in allowed origins

**Fix**:
```java
package com.studentevent.config;

// ✅ Added these imports
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class CorsConfig {
    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/api/**")
                        .allowedOrigins(
                            "http://localhost:3000",
                            "http://98.95.8.184:3000"  // ✅ Added production IP
                        )
                        .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                        .allowedHeaders("*")
                        .allowCredentials(true);
            }
        };
    }
}
```

**Commits**: Multiple fixes

---

### 3. **docker-compose.prod.yml - Health Check Fix**
**File**: `docker-compose.prod.yml`

**Problem 1**: Obsolete `version` line causing warnings
**Fix**: Removed `version: '3.8'` line

**Problem 2**: Health check using `curl` which isn't in Spring Boot image
**Fix**: Changed to TCP port check
```yaml
backend:
  image: vishnuha/student-event-backend:latest
  container_name: student-event-backend
  healthcheck:
    # ✅ OLD: curl -f http://localhost:8080/api/events
    # ✅ NEW: TCP port check (no curl needed)
    test: ["CMD-SHELL", "timeout 5 bash -lc '</dev/tcp/localhost/8080' && echo OK || exit 1"]
    timeout: 10s
    retries: 5
    interval: 10s
    start_period: 180s  # ✅ Increased from 60s to 180s for Spring Boot startup
```

**Commit**: d18dcbc

---

### 4. **deploy.sh - Download Latest docker-compose.prod.yml**
**File**: `deploy.sh`

**Problem**: Script used stale local copy of docker-compose.prod.yml

**Fix**: Download latest from GitHub before deployment
```bash
#!/bin/bash
set -e

echo "🚀 Starting deployment from Docker Hub..."
echo "📅 $(date)"

# Configuration
COMPOSE_FILE="/home/ubuntu/docker-compose.prod.yml"
GITHUB_REPO="https://raw.githubusercontent.com/vishnu-siva/Student_Simple_Event_Management_With_Docker/main"

# ✅ NEW: Download latest docker-compose.prod.yml from GitHub
echo "📥 Downloading latest docker-compose.prod.yml from GitHub..."
curl -fsSL "${GITHUB_REPO}/docker-compose.prod.yml" -o "$COMPOSE_FILE"
if [ $? -eq 0 ]; then
    echo "✅ Successfully downloaded docker-compose.prod.yml"
else
    echo "❌ Failed to download docker-compose.prod.yml from GitHub"
    exit 1
fi

cd "$(dirname "$COMPOSE_FILE")"

echo "📥 Step 1: Pulling latest images from Docker Hub..."
docker-compose -f docker-compose.prod.yml pull

echo "🛑 Step 2: Stopping existing containers..."
docker-compose -f docker-compose.prod.yml down || true

echo "🚀 Step 3: Starting services in order..."
docker-compose -f docker-compose.prod.yml up -d
```

**Commit**: e6ccfbb

---

### 5. **Jenkinsfile - EC2 Instance ID and deploy.sh Download**
**File**: `Jenkinsfile`

**Problem 1**: Wrong EC2 instance ID (pointing to terminated instance)
**Fix**: Updated default to i-0e91a17492dc81172

**Problem 2**: deploy.sh not found on EC2
**Fix**: Download from GitHub before execution
```groovy
parameters {
    string(
        name: 'EC2_INSTANCE_ID',
        defaultValue: 'i-0e91a17492dc81172',  // ✅ Updated from old instance
        description: 'EC2 instance ID for deployment'
    )
}

stage('Deploy to EC2') {
    steps {
        script {
            sh """
                aws ssm send-command \\
                    --instance-ids ${params.EC2_INSTANCE_ID} \\
                    --region us-east-1 \\
                    --document-name AWS-RunShellScript \\
                    --parameters commands='[
                        // ✅ NEW: Download deploy.sh from GitHub
                        "sudo -u ubuntu bash -lc 'curl -fsSL https://raw.githubusercontent.com/vishnu-siva/Student_Simple_Event_Management_With_Docker/main/deploy.sh -o /home/ubuntu/deploy.sh'",
                        "sudo -u ubuntu bash -lc 'chmod +x /home/ubuntu/deploy.sh'",
                        "sudo -u ubuntu bash /home/ubuntu/deploy.sh"
                    ]'
            """
        }
    }
}
```

**Commit**: b2e9ced

---

### 6. **Frontend Home.js - Defensive Array Checks**
**File**: `Frontend/studenteventsimplemanagement/src/components/Home.js`

**Problem**: `.map()` error when API returns non-array response

**Fix**: Add defensive checks
```javascript
const fetchRecentEvents = async () => {
  try {
    const response = await axios.get(`${API_BASE_URL}/api/events/recent`);
    // ✅ NEW: Ensure response.data is an array
    const data = Array.isArray(response.data) ? response.data : [];
    setRecentEvents(data);
  } catch (error) {
    console.error('Error fetching recent events:', error);
    setRecentEvents([]);  // ✅ NEW: Set empty array on error
  }
};

const fetchApprovedEvents = async () => {
  try {
    const response = await axios.get(`${API_BASE_URL}/api/events/approved`);
    // ✅ NEW: Ensure response.data is an array
    const data = Array.isArray(response.data) ? response.data : [];
    setApprovedEvents(data);
  } catch (error) {
    console.error('Error fetching approved events:', error);
    setApprovedEvents([]);  // ✅ NEW: Set empty array on error
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
      // ✅ NEW: Ensure response.data is an array
      const data = Array.isArray(response.data) ? response.data : [];
      setRecentEvents(data);
    } catch (error) {
      console.error('Error searching events:', error);
      setRecentEvents([]);  // ✅ NEW: Set empty array on error
    }
  }
};
```

**Commit**: 4022f74

---

### 7. **Frontend config.js - Missing Export**
**File**: `Frontend/studenteventsimplemanagement/src/config.js`

**Problem**: Missing `export default` causing API_BASE_URL to be undefined

**Fix**:
```javascript
const API_BASE_URL =
  process.env.REACT_APP_API_URL || 'http://98.95.8.184:8080';

export default API_BASE_URL;  // ✅ Added this line
```

**Before this fix, frontend was making requests to:**
```
http://98.95.8.184:3000/[object%20Object]/api/admin/login  ❌ Wrong!
```

**After fix:**
```
http://98.95.8.184:8080/api/admin/login  ✅ Correct!
```

**Commit**: e4e078f

---

## Configuration Files

### Where IP Address is Configured

#### Frontend Configuration
**File**: `Frontend/studenteventsimplemanagement/src/config.js`
```javascript
const API_BASE_URL = 'http://98.95.8.184:8080';  // ← Backend API URL
export default API_BASE_URL;
```

**Used in**:
- `Home.js` - Fetching events
- `AdminLogin.js` - Admin authentication
- `CreateEvent.js` - Creating new events
- `Dashboard.js` - Admin dashboard
- `ManageEvents.js` - Event management

#### Backend CORS Configuration
**File 1**: `Backend/.../config/SecurityConfig.java`
```java
@CrossOrigin(origins = {
    "http://localhost:3000",      // Local development
    "http://98.95.8.184:3000"     // Production frontend
})
```

**File 2**: `Backend/.../config/CorsConfig.java`
```java
.allowedOrigins(
    "http://localhost:3000",      // Local development
    "http://98.95.8.184:3000"     // Production frontend
)
```

**File 3**: `Backend/.../controller/AdminController.java`
```java
@CrossOrigin(origins = {
    "http://localhost:3000",
    "http://98.95.8.184:3000"
})
```

**File 4**: `Backend/.../controller/EventController.java`
```java
@CrossOrigin(origins = {
    "http://localhost:3000",
    "http://98.95.8.184:3000"
})
```

#### Docker Compose Configuration
**File**: `docker-compose.prod.yml`
```yaml
frontend:
  image: vishnuha/student-event-frontend:latest
  ports:
    - "80:80"       # HTTP
    - "3000:80"     # Frontend accessible at http://98.95.8.184:3000

backend:
  image: vishnuha/student-event-backend:latest
  ports:
    - "8080:8080"   # Backend API at http://98.95.8.184:8080
  environment:
    DB_HOST: mysql  # Container name (Docker network resolution)

mysql:
  image: mysql:8.0
  ports:
    - "3306:3306"
```

---

## Shell Scripts

### 1. deploy.sh - Main Deployment Script
**Location**: `/home/ubuntu/deploy.sh` (on EC2)

```bash
#!/bin/bash
# EC2 Deployment Script
# This script runs ON EC2 to pull latest images and deploy in correct order
# Order: MySQL → Backend → Frontend

set -e

echo "🚀 Starting deployment from Docker Hub..."
echo "📅 $(date)"

# Configuration
COMPOSE_FILE="/home/ubuntu/docker-compose.prod.yml"
PROJECT_NAME="student-event-management"
GITHUB_REPO="https://raw.githubusercontent.com/vishnu-siva/Student_Simple_Event_Management_With_Docker/main"

# Download latest docker-compose.prod.yml from GitHub
echo "📥 Downloading latest docker-compose.prod.yml from GitHub..."
curl -fsSL "${GITHUB_REPO}/docker-compose.prod.yml" -o "$COMPOSE_FILE"
if [ $? -eq 0 ]; then
    echo "✅ Successfully downloaded docker-compose.prod.yml"
else
    echo "❌ Failed to download docker-compose.prod.yml from GitHub"
    exit 1
fi

# Navigate to deployment directory
cd "$(dirname "$COMPOSE_FILE")"

echo ""
echo "📥 Step 1: Pulling latest images from Docker Hub..."
echo "   - vishnuha/student-event-backend:latest"
echo "   - vishnuha/student-event-frontend:latest"
docker-compose -f docker-compose.prod.yml pull

echo ""
echo "🛑 Step 2: Stopping existing containers (if any)..."
docker-compose -f docker-compose.prod.yml down || true

echo ""
echo "🧹 Step 3: Cleaning up unused images..."
docker image prune -af --filter "label!=keep" || true

echo ""
echo "🚀 Step 4: Starting services in order..."
echo "   Order: MySQL → Backend → Frontend"
docker-compose -f docker-compose.prod.yml up -d

echo ""
echo "⏳ Step 5: Waiting for services to be ready..."
echo "   MySQL: Waiting for health check..."
timeout 60 bash -c 'until docker-compose -f docker-compose.prod.yml ps mysql | grep -q "healthy"; do sleep 2; done' || echo "MySQL health check timeout"

echo "   Backend: Waiting for health check (180s max)..."
timeout 200 bash -c 'until docker-compose -f docker-compose.prod.yml ps backend | grep -q "healthy"; do sleep 5; done' || echo "Backend health check timeout"

echo "   Frontend: Starting..."
sleep 10

echo ""
echo "📊 Step 6: Container Status:"
docker-compose -f docker-compose.prod.yml ps

echo ""
echo "✅ Deployment Complete!"
echo "🌐 Frontend: http://98.95.8.184:3000"
echo "🔌 Backend API: http://98.95.8.184:8080/api/events"
echo "📅 $(date)"
```

**How it works:**
1. Downloads latest docker-compose.prod.yml from GitHub
2. Pulls latest Docker images from Docker Hub
3. Stops old containers
4. Cleans up old images
5. Starts containers in order: MySQL → Backend → Frontend
6. Waits for health checks
7. Reports deployment status

---

### 2. add-test-data.sh - Add Sample Data
**Location**: Root of project

```bash
#!/bin/bash
# Add test data to your application
# Usage: ./add-test-data.sh [server-url]

SERVER="${1:-http://98.95.8.184:8080}"

echo "Server: $SERVER"
echo "Adding test events to database..."

# Event 1: Tech Workshop (Approved)
curl -X POST "$SERVER/api/events" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Spring Boot Workshop",
    "description": "Learn modern backend development with Spring Boot 3",
    "date": "2026-02-15",
    "time": "14:00:00",
    "location": "Computer Lab A",
    "status": "APPROVED"
  }'

# Event 2: Career Fair (Approved)
curl -X POST "$SERVER/api/events" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Tech Career Fair 2026",
    "description": "Meet recruiters from top tech companies",
    "date": "2026-02-20",
    "time": "10:00:00",
    "location": "Main Auditorium",
    "status": "APPROVED"
  }'

# Event 3: Hackathon (Pending)
curl -X POST "$SERVER/api/events" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Hackathon 2026",
    "description": "24-hour coding challenge",
    "date": "2026-03-01",
    "time": "09:00:00",
    "location": "Main Hall",
    "status": "PENDING"
  }'

echo ""
echo "✅ Test data added successfully!"
```

---

### 3. Add Admin via curl
**Manual command to add admin:**

```bash
# Add admin user
curl -X POST "http://98.95.8.184:8080/api/admin/register" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Vishnu",
    "email": "vishnu8855@gmail.com",
    "password": "vishnu1111"
  }'
```

**Admin Credentials:**
- Email: vishnu8855@gmail.com
- Password: vishnu1111

---

## AWS Systems Manager

### What is AWS Systems Manager (SSM)?

AWS Systems Manager is a service that allows you to **remotely execute commands on EC2 instances without SSH**.

**Benefits:**
- ✅ No need to open SSH port 22 (more secure)
- ✅ No need to manage SSH keys for multiple users
- ✅ Audit trail of all commands executed
- ✅ Centralized command execution from Jenkins/CLI
- ✅ Works even if instance is in private subnet

### How SSM Works in This Project

**Architecture:**
```
Jenkins → AWS SSM → EC2 Instance (i-0e91a17492dc81172)
         (us-east-1)
```

**Flow:**
1. Jenkins triggers deployment
2. Jenkins sends command to AWS SSM
3. SSM agent on EC2 receives command
4. Command executes on EC2 (downloads deploy.sh and runs it)
5. SSM returns output to Jenkins

### SSM Commands Used

**1. Send Command (from Jenkins)**
```bash
aws ssm send-command \
  --instance-ids i-0e91a17492dc81172 \
  --region us-east-1 \
  --document-name AWS-RunShellScript \
  --parameters commands='[
    "sudo -u ubuntu bash -lc '\''curl -fsSL https://raw.githubusercontent.com/vishnu-siva/Student_Simple_Event_Management_With_Docker/main/deploy.sh -o /home/ubuntu/deploy.sh'\''",
    "sudo -u ubuntu bash -lc '\''chmod +x /home/ubuntu/deploy.sh'\''",
    "sudo -u ubuntu bash /home/ubuntu/deploy.sh"
  ]' \
  --comment "Jenkins triggered deployment - Build #103" \
  --output text
```

**2. Check Command Status**
```bash
aws ssm list-command-invocations \
  --command-id <COMMAND_ID> \
  --details \
  --region us-east-1
```

**3. Get Command Output**
```bash
aws ssm get-command-invocation \
  --command-id <COMMAND_ID> \
  --instance-id i-0e91a17492dc81172 \
  --region us-east-1
```

### SSM Configuration on EC2

**Prerequisites:**
1. EC2 instance has IAM role with `AmazonSSMManagedInstanceCore` policy
2. SSM agent installed and running (pre-installed on Amazon Linux 2/Ubuntu)
3. Instance can reach SSM endpoints (internet or VPC endpoints)

**Check SSM agent status on EC2:**
```bash
sudo systemctl status amazon-ssm-agent
```

**Verify instance is managed by SSM:**
```bash
aws ssm describe-instance-information \
  --filters "Key=InstanceIds,Values=i-0e91a17492dc81172" \
  --region us-east-1
```

---

## Deployment Workflow

### Full CI/CD Pipeline

```
Developer → GitHub → Jenkins → Docker Hub → EC2
   │           │         │          │         │
   │           │         │          │         └─→ Containers Running
   │           │         │          └─→ Pull Images
   │           │         └─→ Build & Push Images
   │           └─→ Trigger Build (webhook or manual)
   └─→ git push origin main
```

### Step-by-Step Deployment Process

#### 1. **Code Changes (Developer)**
```bash
# Make changes locally
vim Backend/...SecurityConfig.java

# Commit and push
git add .
git commit -m "Fix: Update CORS configuration"
git push origin main
```

#### 2. **Jenkins Build (Automated)**
**Stages:**
1. **Verify Tools** - Check Docker, Maven, Node.js
2. **Checkout** - Clone code from GitHub
3. **Build Backend** - `mvn clean package -DskipTests`
4. **Build Frontend** - `npm install && npm run build`
5. **Test** - `mvn test`
6. **Build Docker Images**
   ```bash
   docker build -t vishnuha/student-event-backend:103 Backend/
   docker build -t vishnuha/student-event-frontend:103 Frontend/
   ```
7. **Push to Docker Hub**
   ```bash
   docker push vishnuha/student-event-backend:latest
   docker push vishnuha/student-event-frontend:latest
   ```
8. **Deploy to EC2 via SSM** - Trigger deploy.sh

#### 3. **Deployment on EC2 (Automated via SSM)**
```bash
# deploy.sh executes these steps:
1. Download latest docker-compose.prod.yml from GitHub
2. Pull latest images from Docker Hub
3. Stop old containers
4. Start new containers:
   - MySQL (wait for healthy)
   - Backend (wait for healthy, 180s timeout)
   - Frontend (starts after backend healthy)
```

#### 4. **Verification**
```bash
# Check container status
docker ps

# Check logs
docker logs student-event-backend
docker logs student-event-frontend
docker logs student-event-mysql

# Test endpoints
curl http://98.95.8.184:8080/api/events
curl http://98.95.8.184:3000
```

---

### Manual Deployment (Without Jenkins)

**If Jenkins fails, deploy manually:**

```bash
# 1. SSH to EC2
ssh -i ~/.ssh/student-event-app-key.pem ubuntu@98.95.8.184

# 2. Download deploy.sh
curl -fsSL https://raw.githubusercontent.com/vishnu-siva/Student_Simple_Event_Management_With_Docker/main/deploy.sh -o /home/ubuntu/deploy.sh
chmod +x /home/ubuntu/deploy.sh

# 3. Run deployment
bash /home/ubuntu/deploy.sh

# 4. Check status
docker ps
docker logs student-event-backend
```

---

## Troubleshooting Guide

### Common Issues and Solutions

#### 1. Backend Container Unhealthy

**Symptom:**
```
Container student-event-backend is unhealthy
```

**Causes & Solutions:**

**A. Health check timeout too short**
```yaml
# docker-compose.prod.yml
healthcheck:
  start_period: 180s  # ✅ Needs to be at least 180s for Spring Boot
```

**B. Health check using curl (not available)**
```yaml
# ❌ OLD (doesn't work):
test: ["CMD-SHELL", "curl -f http://localhost:8080/api/events"]

# ✅ NEW (works):
test: ["CMD-SHELL", "timeout 5 bash -lc '</dev/tcp/localhost/8080' && echo OK || exit 1"]
```

**C. Backend can't connect to MySQL**
```bash
# Check MySQL is healthy
docker ps | grep mysql

# Check backend logs for DB connection errors
docker logs student-event-backend | grep -i "connection"

# Verify DB credentials in docker-compose.prod.yml match
```

---

#### 2. Frontend Shows Blank Page or [object Object] Error

**Symptom:**
```
POST http://98.95.8.184:3000/[object%20Object]/api/admin/login
```

**Cause**: Missing `export default` in config.js

**Solution:**
```javascript
// Frontend/studenteventsimplemanagement/src/config.js
const API_BASE_URL = 'http://98.95.8.184:8080';
export default API_BASE_URL;  // ✅ Must have this line
```

---

#### 3. CORS Errors in Browser Console

**Symptom:**
```
Access to XMLHttpRequest at 'http://98.95.8.184:8080/api/events' from origin 'http://98.95.8.184:3000' has been blocked by CORS policy
```

**Solution**: Ensure production IP is in ALL CORS configurations:

**SecurityConfig.java:**
```java
@CrossOrigin(origins = {
    "http://localhost:3000",
    "http://98.95.8.184:3000"  // ✅ Must include production IP
})
```

**CorsConfig.java:**
```java
.allowedOrigins(
    "http://localhost:3000",
    "http://98.95.8.184:3000"  // ✅ Must include production IP
)
```

**AdminController.java & EventController.java:**
```java
@CrossOrigin(origins = {
    "http://localhost:3000",
    "http://98.95.8.184:3000"  // ✅ Must include production IP
})
```

---

#### 4. Admin Login Fails with "Invalid credentials"

**Symptom**: Admin registered successfully but login fails

**Cause**: Admin not in database or table name mismatch

**Solution**:
```bash
# 1. Register admin
curl -X POST "http://98.95.8.184:8080/api/admin/register" \
  -H "Content-Type: application/json" \
  -d '{"name":"Vishnu","email":"vishnu8855@gmail.com","password":"vishnu1111"}'

# 2. Verify admin exists
curl http://98.95.8.184:8080/api/admin/1

# 3. Check database directly
docker exec -it student-event-mysql mysql -uroot -pVishnu student_event_db -e "SELECT * FROM admins;"
```

**Note**: Admin entity uses table name `admins` (plural)

---

#### 5. Jenkins Build Fails

**Common Failures:**

**A. Docker Hub Connection Reset**
```
Put "https://registry-1.docker.io/v2/...": read: connection reset by peer
```
**Solution**: Retry build (temporary network issue)

**B. Terraform Provider Download Fails**
```
Error: Failed to install provider hashicorp/aws
```
**Solution**: This doesn't affect deployment (Terraform stage is optional)

**C. Maven Compilation Errors**
```
[ERROR] cannot find symbol: class Configuration
```
**Solution**: Check for missing imports in Java files

---

#### 6. Containers Not Starting After Deployment

**Check these:**

```bash
# 1. Check if containers exist
docker ps -a

# 2. Check container logs
docker logs student-event-mysql
docker logs student-event-backend
docker logs student-event-frontend

# 3. Check disk space
df -h

# 4. Check memory usage
free -h

# 5. Restart containers manually
cd /home/ubuntu
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d

# 6. Check health status
docker inspect student-event-backend --format='{{.State.Health.Status}}'
```

---

#### 7. MySQL Data Loss After Restart

**Problem**: Data disappears when MySQL container restarts

**Cause**: Volume not properly mounted

**Solution**: Ensure volume is configured in docker-compose.prod.yml
```yaml
mysql:
  volumes:
    - /data/mysql:/var/lib/mysql  # ✅ EBS volume mounted at /data
```

**Verify volume:**
```bash
# Check if /data directory exists
ls -la /data/

# Check volume mount
docker inspect student-event-mysql --format='{{json .Mounts}}'
```

---

### Useful Commands

#### Docker Commands
```bash
# View all containers
docker ps -a

# View container logs (last 100 lines)
docker logs --tail 100 student-event-backend

# Follow logs in real-time
docker logs -f student-event-backend

# Execute command in running container
docker exec -it student-event-mysql bash

# Inspect container health
docker inspect student-event-backend --format='{{json .State.Health}}'

# Check container resource usage
docker stats

# Remove stopped containers
docker container prune

# Remove unused images
docker image prune -a
```

#### Docker Compose Commands
```bash
# Start services
docker compose -f docker-compose.prod.yml up -d

# Stop services
docker compose -f docker-compose.prod.yml down

# View service status
docker compose -f docker-compose.prod.yml ps

# View logs
docker compose -f docker-compose.prod.yml logs -f

# Restart specific service
docker compose -f docker-compose.prod.yml restart backend

# Pull latest images
docker compose -f docker-compose.prod.yml pull
```

#### AWS SSM Commands
```bash
# List managed instances
aws ssm describe-instance-information --region us-east-1

# Send command to instance
aws ssm send-command \
  --instance-ids i-0e91a17492dc81172 \
  --region us-east-1 \
  --document-name AWS-RunShellScript \
  --parameters 'commands=["docker ps"]'

# Get command output
aws ssm get-command-invocation \
  --command-id <COMMAND_ID> \
  --instance-id i-0e91a17492dc81172 \
  --region us-east-1
```

#### MySQL Commands
```bash
# Connect to MySQL in container
docker exec -it student-event-mysql mysql -uroot -pVishnu student_event_db

# List all tables
docker exec -it student-event-mysql mysql -uroot -pVishnu student_event_db -e "SHOW TABLES;"

# View events
docker exec -it student-event-mysql mysql -uroot -pVishnu student_event_db -e "SELECT * FROM events;"

# View admins
docker exec -it student-event-mysql mysql -uroot -pVishnu student_event_db -e "SELECT * FROM admins;"

# Add admin directly via SQL
docker exec -it student-event-mysql mysql -uroot -pVishnu student_event_db -e "INSERT INTO admins (name, email, password) VALUES ('Vishnu', 'vishnu8855@gmail.com', 'vishnu1111');"
```

---

## Summary of All Commits

| Commit | File(s) Changed | Purpose |
|--------|----------------|---------|
| 65880ff | docker-compose.prod.yml | Increased health check timeout 60s → 180s |
| eb51118 | SecurityConfig.java | Fixed duplicate http:// and semicolon/comma |
| b2e9ced | Jenkinsfile | Download deploy.sh before SSM run, fix EC2 instance ID |
| d18dcbc | docker-compose.prod.yml | Use TCP port check instead of curl, remove version line |
| e6ccfbb | deploy.sh | Download latest docker-compose.prod.yml from GitHub |
| 4022f74 | Home.js | Add defensive array checks to prevent map() errors |
| e4e078f | config.js | Add export default for API_BASE_URL |

---

## Quick Reference

### Application URLs
- **Frontend**: http://98.95.8.184:3000
- **Backend API**: http://98.95.8.184:8080/api/events
- **Jenkins**: http://localhost:9090
- **Admin Login**: http://98.95.8.184:3000/admin-login

### Credentials
- **Admin Email**: vishnu8855@gmail.com
- **Admin Password**: vishnu1111
- **MySQL User**: root
- **MySQL Password**: Vishnu
- **Database Name**: student_event_db

### EC2 Instance
- **Instance ID**: i-0e91a17492dc81172
- **Type**: t3.small (2 vCPU, 2GB RAM)
- **Public IP**: 98.95.8.184
- **Region**: us-east-1
- **Availability Zone**: us-east-1c

### Docker Images
- **Backend**: vishnuha/student-event-backend:latest
- **Frontend**: vishnuha/student-event-frontend:latest
- **Database**: mysql:8.0

### Key Ports
- **3000**: Frontend (React)
- **8080**: Backend API (Spring Boot)
- **3306**: MySQL Database
- **9090**: Jenkins (local)

---

## Next Steps / Improvements

### Security Improvements
1. **Change default MySQL password** (currently hardcoded as "Vishnu")
2. **Add password hashing** for admin accounts (currently plain text)
3. **Add JWT authentication** instead of storing admin ID in localStorage
4. **Use HTTPS** (add SSL certificate via AWS Certificate Manager)
5. **Remove hardcoded credentials** (use AWS Secrets Manager or environment variables)

### Performance Improvements
1. **Add Redis caching** for frequently accessed events
2. **Enable database connection pooling** in Spring Boot
3. **Add CDN** for static frontend assets
4. **Implement pagination** for event listings
5. **Add database indexes** on commonly queried fields

### Monitoring & Logging
1. **Add CloudWatch logs** for container monitoring
2. **Set up CloudWatch alarms** for health check failures
3. **Add application logging** (ELK stack or CloudWatch Logs Insights)
4. **Add APM tool** (New Relic, Datadog, or AWS X-Ray)

### CI/CD Improvements
1. **Add automated tests** in Jenkins pipeline
2. **Add staging environment** before production
3. **Implement blue-green deployment** for zero downtime
4. **Add rollback mechanism** in case of failed deployment
5. **Set up GitHub webhook** for automatic Jenkins triggers

---

**Document Version**: 1.0  
**Last Updated**: January 31, 2026  
**Maintained By**: Vishnu (vishnu8855@gmail.com)
