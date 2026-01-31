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

# Start MySQL first
echo ""
echo "   📊 Starting MySQL database..."
docker-compose -f docker-compose.prod.yml up -d mysql

# Wait for MySQL to be healthy
echo "   ⏳ Waiting for MySQL to be healthy..."
timeout 120 bash -c 'until docker exec student-event-mysql mysqladmin ping -h localhost -pVishnu --silent; do sleep 2; done' || {
    echo "❌ MySQL failed to start"
    docker-compose -f docker-compose.prod.yml logs mysql
    exit 1
}
echo "   ✅ MySQL is healthy"

# Start Backend
echo ""
echo "   🔧 Starting Backend (Spring Boot)..."
docker-compose -f docker-compose.prod.yml up -d backend

# Wait for Backend to be healthy
echo "   ⏳ Waiting for Backend to be healthy..."
timeout 120 bash -c 'until curl -f http://localhost:8080/api/events > /dev/null 2>&1; do sleep 3; done' || {
    echo "❌ Backend failed to start"
    docker-compose -f docker-compose.prod.yml logs backend
    exit 1
}
echo "   ✅ Backend is healthy"

# Start Frontend
echo ""
echo "   ⚛️  Starting Frontend (React)..."
docker-compose -f docker-compose.prod.yml up -d frontend

# Wait a bit for frontend
sleep 10

echo ""
echo "📊 Step 5: Verifying deployment..."
docker-compose -f docker-compose.prod.yml ps

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 Application URLs:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "localhost")
echo "   Frontend:  http://$PUBLIC_IP"
echo "   Frontend:  http://$PUBLIC_IP:3000"
echo "   Backend:   http://$PUBLIC_IP:8080"
echo "   API:       http://$PUBLIC_IP:8080/api/events"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 View logs:"
echo "   docker-compose -f docker-compose.prod.yml logs -f"
echo ""
echo "🔄 To manually redeploy:"
echo "   bash /home/ubuntu/deploy.sh"
echo ""
