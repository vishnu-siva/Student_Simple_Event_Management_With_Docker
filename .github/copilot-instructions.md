# AI Copilot Instructions for Student Event Management System

## Project Overview
Full-stack event management system with **Spring Boot 3.5.7** backend (Java 24), **React 19** frontend, **MySQL 8.0** database, and containerized deployment via Docker Compose. The system manages student events with approval workflows (PENDING → APPROVED/REJECTED states).

---

## Architecture & Key Components

### Backend (Spring Boot)
- **Location**: `Backend/student-event-management/student-event-management/`
- **Key Pattern**: Layered architecture (Controller → Service → Repository → Entity)
- **Main packages**:
  - `controller/`: REST endpoints (`EventController`, `AdminController`)
  - `service/`: Business logic (`EventService`, `AdminService`)
  - `model/`: JPA entities (`Event`, `Admin`) with Lombok annotations
  - `repository/`: Spring Data JPA interfaces with custom queries
  - `config/`: Security & CORS configuration

### Frontend (React)
- **Location**: `Frontend/studenteventsimplemanagement/`
- **Key Libraries**: React Router (v7), Axios (HTTP client), React Icons
- **Key Components**: Home, Dashboard, AdminLogin, CreateEvent, ManageEvents, About
- **API Base**: Communicates with backend at `http://localhost:8080` (hardcoded in services)

### Database Schema
- **Service**: MySQL 8.0 running on port 3307 (mapped from 3306)
- **Event Model Fields**: id, title, description, date (LocalDate), time (LocalTime), location, status (PENDING/APPROVED/REJECTED), createdAt
- **Status Workflow**: All new events start as PENDING, then approved/rejected by admins

### Docker Compose Stack
- **Services**: mysql, backend (port 8080), frontend (port 3000)
- **Configuration**: Environment variables for DB credentials (root/Vishnu hardcoded - INSECURE)
- **Networking**: All services on `student-event-network` bridge
- **Health Checks**: MySQL service health check before backend startup (depends_on condition)

---

## Critical Patterns & Conventions

### Event Status Management
- **States**: PENDING (default), APPROVED, REJECTED
- **Operations**: `approveEvent()`, `rejectEvent()` set status and persist immediately
- **Queries**: `getApprovedEventsSortedByDate()`, `getRecentEventsSortedByDate()`, `searchNonRejectedEvents(keyword)`
- **Example** ([EventService.java](EventService.java#L23-L29)): Sorting uses `OrderByDateAscTimeAsc` for consistent ordering

### API Endpoints Convention
- **Base Path**: `/api/events`
- **Standard CRUD**: GET/POST/PUT/DELETE for full event lifecycle
- **Approval**: `PUT /api/events/{id}/approve` and `PUT /api/events/{id}/reject`
- **Filtering**: `/approved`, `/recent`, `/search?keyword=`, `/count` for aggregations
- **CORS**: Configured for `http://localhost:3000` only (update in [SecurityConfig.java](SecurityConfig.java#L22) for production)

### Dependency Injection
- Uses `@Autowired` annotation for Spring beans (legacy style, not constructor injection)
- Services autowired in controllers; repositories autowired in services
- Single source of truth: repositories call `findAll()`, `save()`, `deleteById()`, or custom queries

### Error Handling
- **Simple approach**: `.orElseThrow()` for missing entities in services
- **Controllers catch** RuntimeException and return `ResponseEntity.notFound().build()`
- **No custom exceptions** yet - consider adding for production

---

## Developer Workflows

### Local Development (Docker Compose)
```bash
# From project root:
docker-compose up --build          # Start all services
docker-compose up -d               # Run in background
docker-compose logs -f             # Stream logs
docker-compose down                # Stop and remove containers
```

### Backend Development
- **Build**: `mvn clean install` (requires Java 24)
- **Run local**: `mvn spring-boot:run` or run `StudentEventManagementApplication.java` in IDE
- **Tests**: `mvn test` (currently only has `StudentEventManagementApplicationTests.java`)
- **Database migrations**: Hibernate DDL auto-update enabled (non-production)

### Frontend Development
- **Start**: `npm start` (runs on port 3000)
- **Build**: `npm run build`
- **Test**: `npm test` (interactive watch mode)
- **Dependencies update**: React 19.2, Router 7.9.5, Axios 1.13.2

### CI/CD Pipeline
- **Jenkins** orchestrates builds (see [Jenkinsfile](Jenkinsfile))
- **Stages**: Verify tools → Build backend (Maven) → Build frontend (npm) → Build Docker images → Push to DockerHub
- **Parameters**: DOCKERHUB_USERNAME, PUSH_IMAGES flag
- **Docker Hub Images**: `vishnuha/student-event-backend` and `vishnuha/student-event-frontend`

---

## Cross-Component Communication

### Frontend → Backend Flow
1. React components (e.g., [CreateEvent.js](../../Frontend/studenteventsimplemanagement/src/components/CreateEvent.js)) use Axios
2. POST to `http://localhost:8080/api/events` with Event payload
3. Backend `EventController.createEvent()` receives, validates (basic @RequestBody), persists via service
4. Response: HTTP 201 (Created) with created Event object

### Database Integration
- Spring Data JPA manages MySQL via Hibernate ORM
- Custom queries in [EventRepository.java](../../Backend/student-event-management/student-event-management/src/main/java/com/studentevent/repository/EventRepository.java):
  - `findByStatusOrderByDateAscTimeAsc()` for sorted approved events
  - `findRecentEventsExcludingRejected()` for combined pending+approved
  - `searchNonRejectedEvents(keyword)` for full-text search

---

## Important Files & Where To Look

| Component | Key Files |
|-----------|-----------|
| **Event Model** | [Event.java](../../Backend/student-event-management/student-event-management/src/main/java/com/studentevent/model/Event.java) - JPA entity with status field |
| **Event API** | [EventController.java](../../Backend/student-event-management/student-event-management/src/main/java/com/studentevent/controller/EventController.java) - All REST endpoints |
| **Business Logic** | [EventService.java](../../Backend/student-event-management/student-event-management/src/main/java/com/studentevent/service/EventService.java) - Filtering, approval logic |
| **Security** | [SecurityConfig.java](../../Backend/student-event-management/student-event-management/src/main/java/com/studentevent/config/SecurityConfig.java) - CORS & authentication (currently permissive) |
| **DB Connection** | [application.properties](../../Backend/student-event-management/student-event-management/src/main/resources/application.properties) - Environment-driven config |
| **Infrastructure** | [docker-compose.yml](../../docker-compose.yml) - Service definitions & networking |
| **Build** | [Jenkinsfile](../../Jenkinsfile) - Multi-stage build & deployment pipeline |

---

## Common Tasks for AI Agents

### Adding a New Event Field
1. Add field to [Event.java](../../Backend/student-event-management/student-event-management/src/main/java/com/studentevent/model/Event.java) with @Column annotation
2. Update [EventService.updateEvent()](../../Backend/student-event-management/student-event-management/src/main/java/com/studentevent/service/EventService.java#L48-L58) to map new field
3. Hibernate auto-creates DB column on next run
4. Update frontend [CreateEvent.js](../../Frontend/studenteventsimplemanagement/src/components/CreateEvent.js) form as needed

### Modifying API Response Format
- Change [EventController.java](../../Backend/student-event-management/student-event-management/src/main/java/com/studentevent/controller/EventController.java) response mapping (or introduce DTO layer if needed)
- Test with cURL or Postman: `GET http://localhost:8080/api/events`

### Deploying to Production
- Update credentials in [docker-compose.yml](../../docker-compose.yml) (currently hardcoded)
- Update CORS allowed origins in [SecurityConfig.java](../../Backend/student-event-management/student-event-management/src/main/java/com/studentevent/config/SecurityConfig.java#L22)
- Modify Jenkins parameters for target Docker registry
- Run pipeline for automated build & push

---

## Known Limitations & Technical Debt

- **Credentials hardcoded** in docker-compose.yml (Vishnu password)
- **CORS locked** to localhost:3000 - update for production domains
- **No authentication** on admin endpoints - SecurityConfig permits all requests
- **Minimal error handling** - consider custom exceptions & validation
- **Limited test coverage** - expand unit & integration tests
- **No API documentation** - consider Swagger/OpenAPI
- **Frontend hardcodes** backend URL (http://localhost:8080) - make configurable via environment

---

## When Adding Code

- **Use Lombok** (`@Data`, `@NoArgsConstructor`, `@AllArgsConstructor`) for entity boilerplate
- **Follow service layer pattern** - don't put logic in controllers
- **Respect event status workflow** - always validate state transitions
- **Test locally** with `docker-compose up` before pushing changes
- **Update both backend & frontend** when changing API contracts
