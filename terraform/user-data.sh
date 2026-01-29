#!/bin/bash
set -euo pipefail

# Log output for debugging
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=========================================="
echo "Starting EC2 user-data script..."
echo "=========================================="
echo "Timestamp: $(date)"

# Update system packages
echo "[1/6] Updating system packages..."
apt-get update
apt-get upgrade -y
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    wget

# Install Docker
echo "[2/6] Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify Docker installation
docker --version
docker compose version

# Start Docker service
systemctl enable docker
systemctl start docker

# Install Docker Compose (legacy)
echo "[3/6] Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose --version

# Clone repository
echo "[4/6] Cloning repository..."
cd /home/ubuntu
git clone --branch ${docker_compose_branch} ${docker_compose_repo}
cd Student_Simple_Event_Management_With_Docker || cd student-event-management || true

# Start Docker containers using production compose file
echo "[5/6] Starting Docker containers..."
# Use docker-compose.prod.yml if available, otherwise fall back to docker-compose.yml
if [ -f "docker-compose.prod.yml" ]; then
  echo "Using docker-compose.prod.yml (production configuration)"
  docker-compose -f docker-compose.prod.yml pull
  docker-compose -f docker-compose.prod.yml up -d
else
  echo "Using docker-compose.yml"
  # Remove jenkins service from docker-compose if it exists
  docker-compose pull --ignore-pull-failures || true
  docker-compose up -d mysql backend frontend
fi

echo "[6/6] Checking Docker containers..."
sleep 30

# Check service status
echo "=========================================="
echo "Service status:"
echo "=========================================="
docker-compose ps

echo ""
echo "=========================================="
echo "Container logs (last 20 lines):"
echo "=========================================="
docker-compose logs --tail=20

# Display access information
echo ""
echo "=========================================="
echo "Application is starting up!"
echo "=========================================="
echo "Timestamp: $(date)"
echo "User data script completed successfully!"
echo ""
echo "Access the application at:"
echo "  Frontend:   http://$(hostname -I | awk '{print $1}'):3000"
echo "  Backend:    http://$(hostname -I | awk '{print $1}'):8080"
echo "  API:        http://$(hostname -I | awk '{print $1}'):8080/api/events"
echo ""
echo "View logs:"
echo "  docker-compose logs -f"
echo ""
echo "To SSH into the instance:"
echo "  ssh -i /path/to/your-key.pem ubuntu@$(hostname -I | awk '{print $1}')"
echo "=========================================="
