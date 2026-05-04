# Task Manager — Docker Compose Multi-Tier Application

A full-stack task management application deployed with Docker Compose, demonstrating a three-tier architecture with network segmentation, persistent storage, health checks, and resource limits.

## Architecture

```
Browser ─► :8080 ─► [Frontend (nginx)] ─► [Backend (Express)] ─► [Database (PostgreSQL)]
                     frontend-net          frontend-net            backend-net
                                           backend-net
```

- **Frontend**: Vanilla HTML/CSS/JS served by nginx (reverse-proxies `/api/*` to the backend)
- **Backend**: Node.js + Express REST API (multi-stage Docker build)
- **Database**: PostgreSQL 16 with init script and named volume

**Security principle**: The frontend container can only reach the backend — it has no direct access to the database.

## Tech Stack

| Component | Technology |
|-----------|------------|
| Frontend  | HTML/CSS/JS + nginx 1.25 |
| Backend   | Node.js 20 + Express 4 |
| Database  | PostgreSQL 16 |
| Orchestration | Docker Compose 3.8 |

## Quick Start

### Prerequisites
- Docker & Docker Compose installed

### 1. Clone and configure
```bash
git clone <repo-url>
cd docker-compose-lab
cp .env.example .env
# Edit .env to set your own DB_PASSWORD
```

### 2. Build and start
```bash
docker-compose up -d --build
```

### 3. Access the app
Open [http://localhost:8080](http://localhost:8080) in your browser.

### 4. Stop
```bash
docker-compose down          # Keep data
docker-compose down -v       # Remove data (volumes)
```

## API Endpoints

| Method | Endpoint         | Description        |
|--------|------------------|--------------------|
| GET    | `/health`        | Health check       |
| GET    | `/api/tasks`     | List all tasks     |
| POST   | `/api/tasks`     | Create a task      |
| PUT    | `/api/tasks/:id` | Update a task      |
| DELETE | `/api/tasks/:id` | Delete a task      |

## Project Structure

```
docker-compose-lab/
├── docker-compose.yml
├── .env / .env.example
├── .gitignore
├── init-db/
│   └── init.sql               # DB schema + seed data
├── backend/
│   ├── Dockerfile              # Multi-stage build
│   ├── .dockerignore
│   ├── package.json
│   └── src/
│       └── index.js            # Express API
├── frontend/
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── nginx.conf              # Reverse proxy config
│   └── public/
│       ├── index.html
│       ├── style.css
│       └── app.js
├── screenshots/                # Validation screenshots
└── README.md
```

## Network Segmentation

- **frontend-net**: connects `frontend` ↔ `backend`
- **backend-net**: connects `backend` ↔ `database`

The frontend container **cannot** reach the database directly.

## Resource Limits

| Service   | CPU  | Memory |
|-----------|------|--------|
| database  | 0.5  | 512M   |
| backend   | 0.5  | 256M   |
| frontend  | 0.25 | 128M   |

## Validation Tests

### Test 1: Database Connectivity
```bash
docker exec taskmanager-backend wget -qO- http://localhost:3000/health
```

### Test 2: API Endpoints
```bash
# Health check
curl http://localhost:8080/health

# List tasks
curl http://localhost:8080/api/tasks

# Create a task
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"New Task","description":"Test","status":"pending"}'
```

### Test 3: Frontend
Open http://localhost:8080 and verify the CRUD interface works.

### Test 4: Network Isolation
```bash
# This should FAIL — frontend cannot reach database
docker exec taskmanager-frontend wget --timeout=3 -qO- http://database:5432 || echo "Connection refused (expected)"
```

### Test 5: Data Persistence
```bash
# Add data, then restart
docker-compose down
docker-compose up -d
# Verify data is still present
```

### Test 6: Resource Limits
```bash
docker stats --no-stream
```

### Test 7: Health Checks
```bash
docker inspect --format='{{json .State.Health}}' taskmanager-backend
docker inspect --format='{{json .State.Health}}' taskmanager-frontend
docker inspect --format='{{json .State.Health}}' taskmanager-db
```

## Screenshots

Place your validation screenshots in the `/screenshots/` directory:

- `docker-compose-ps.png` — all services healthy
- `docker-network-ls.png` — custom networks
- `docker-volume-ls.png` — named volume
- `docker-stats.png` — resource limits
- `frontend-ui.png` — working interface
- `network-isolation.png` — failed frontend→database connection
- `health-checks.png` — health status
