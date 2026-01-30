#!/bin/bash
# Deployment script to pull latest Docker images and restart containers
# Run this script on EC2 to update the application

set -e

echo "🚀 Starting deployment from Docker Hub..."

# Configuration
COMPOSE_FILE="/home/ubuntu/docker-compose.yml"
PROJECT_NAME="student-event-management"

# Check if docker-compose.yml exists
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "❌ Error: docker-compose.yml not found at $COMPOSE_FILE"
    exit 1
fi

# Navigate to the directory
cd "$(dirname "$COMPOSE_FILE")"

echo "📥 Pulling latest images from Docker Hub..."
docker-compose pull

echo "🛑 Stopping current containers..."
docker-compose down

echo "🧹 Cleaning up unused images..."
docker image prune -f

echo "🚀 Starting containers with new images..."
docker-compose up -d

echo "⏳ Waiting for services to be healthy..."
sleep 10

echo "📊 Container status:"
docker-compose ps

echo "✅ Deployment complete!"
echo ""
echo "🌐 Application URLs:"
echo "   Frontend: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000"
echo "   Backend:  http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo ""
echo "📝 View logs:"
echo "   docker-compose logs -f"
