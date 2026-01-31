#!/bin/bash
set -e

cat > /tmp/deploy.sh << 'DEPLOY_EOF'
#!/bin/bash
set -e
echo "🚀 Starting deployment from Docker Hub..."
echo "📅 $(date)"

COMPOSE_FILE="/home/ubuntu/docker-compose.prod.yml"

if [ ! -f "$COMPOSE_FILE" ]; then
    echo "❌ Error: $COMPOSE_FILE not found"
    exit 1
fi

cd "$(dirname "$COMPOSE_FILE")"

echo ""
echo "📥 Step 1: Pulling latest images from Docker Hub..."
docker compose -f docker-compose.prod.yml pull

echo ""
echo "🛑 Step 2: Stopping existing containers..."
docker compose -f docker-compose.prod.yml down || true

echo ""
echo "🚀 Step 3: Starting services in order..."

# Start MySQL
echo "📊 Starting MySQL..."
docker compose -f docker-compose.prod.yml up -d mysql
timeout 120 bash -c 'until docker exec student-event-mysql mysqladmin ping -h localhost -pVishnu --silent; do sleep 2; done' || echo "MySQL health check timed out"

# Start Backend
echo "🔧 Starting Backend..."
docker compose -f docker-compose.prod.yml up -d backend
timeout 180 bash -c 'until curl -f http://localhost:8080/api/events > /dev/null 2>&1; do sleep 3; done' || echo "Backend health check timed out"

# Start Frontend
echo "⚛️  Starting Frontend..."
docker compose -f docker-compose.prod.yml up -d frontend
sleep 10

echo ""
echo "📊 Deployment Status:"
docker compose -f docker-compose.prod.yml ps

echo "✅ Deployment completed!"
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "localhost")
echo "Frontend: http://$PUBLIC_IP:3000"
echo "Backend:  http://$PUBLIC_IP:8080"
DEPLOY_EOF

chmod +x /tmp/deploy.sh
echo "Deploy script created at /tmp/deploy.sh"
