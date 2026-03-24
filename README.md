# Student Event Management System

A full-stack event platform where students can submit events and admins can review, approve, or reject them.

## Live Demo

- Frontend: http://98.95.8.184:3000
- Backend API: http://98.95.8.184:8080/api/events

## Why This Project

This project demonstrates end-to-end product delivery:

- Modern full-stack development (React + Spring Boot)
- Containerized development and production deployment
- CI/CD automation with Jenkins and Docker Hub
- Cloud deployment on AWS EC2 using Systems Manager (SSM)

## Key Features

- Student event creation with title, description, date, time, and location
- Admin workflow: `PENDING -> APPROVED / REJECTED`
- Event search and filtered listing
- REST API design with clean backend layering
- Docker Compose for local and production environments

## Tech Stack

- Frontend: React 19, React Router, Axios
- Backend: Spring Boot 3.5.7, Spring Security, Spring Data JPA, Lombok
- Database: MySQL 8.0
- DevOps: Docker, Docker Compose, Jenkins, AWS EC2, AWS SSM, Terraform

## Project Structure

```text
.
|- Backend/student-event-management/student-event-management/
|  |- src/main/java/com/studentevent/
|  |  |- config/
|  |  |- controller/
|  |  |- model/
|  |  |- repository/
|  |  `- service/
|  `- src/main/resources/application.properties
|- Frontend/studenteventsimplemanagement/
|  `- src/components/
|- terraform/
|- docker-compose.yml
|- docker-compose.prod.yml
|- deploy.sh
`- Jenkinsfile
```

## Architecture Overview

```text
React Frontend (Port 3000)
          |
          v
Spring Boot API (Port 8080)
          |
          v
MySQL 8.0 (Port 3306 / 3307 local mapping)
```

## Quick Start (Docker)

Run from repository root:

```bash
docker-compose up --build
```

Local services:

- Frontend: http://localhost:3000
- Backend API: http://localhost:8080/api/events
- MySQL: localhost:3307
- Jenkins: http://localhost:9090

Stop:

```bash
docker-compose down
```

## Run Without Docker

### Backend

```bash
cd Backend/student-event-management/student-event-management
mvn clean install
mvn spring-boot:run
```

### Frontend

```bash
cd Frontend/studenteventsimplemanagement
npm install
npm start
```

## API Highlights

Base path: `/api/events`

- `GET /api/events`
- `POST /api/events`
- `PUT /api/events/{id}/approve`
- `PUT /api/events/{id}/reject`
- `GET /api/events/approved`
- `GET /api/events/recent`
- `GET /api/events/search?keyword=...`

Admin endpoints are under `/api/admin`.

## CI/CD Pipeline

Current flow:

1. Push code to GitHub
2. Jenkins builds backend and frontend
3. Docker images pushed to Docker Hub
4. Jenkins triggers AWS SSM command
5. EC2 runs `deploy.sh` and updates containers

## Environment Configuration

- Backend DB vars (with defaults in `application.properties`):
  - `DB_HOST`
  - `DB_PORT`
  - `DB_NAME`
  - `DB_USER`
  - `DB_PASSWORD`
- Frontend API URL:
  - `REACT_APP_API_URL`

## Screenshots

Add screenshots to make this README stand out:

- Home page UI
- Admin login page
- Event approval dashboard
- Docker containers running on EC2

Suggested folder:

```text
/docs/images/
```

Then reference like:

```markdown
![Home](docs/images/home.png)
```

## Security Notes

This repository currently contains development-style defaults (for example, DB password and public IP references).

Before production use:

- Move secrets to environment variables or a secrets manager
- Hash admin passwords
- Add proper authentication and authorization (JWT/session)
- Restrict CORS origins
- Enable HTTPS

## Author

Vishnu
