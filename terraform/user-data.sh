#!/bin/bash
set -euo pipefail

# -------------------------
# Logging
# -------------------------
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=========================================="
echo "Starting EC2 user-data script"
echo "Timestamp: $(date)"
echo "=========================================="

# -------------------------
# 1. System update
# -------------------------
echo "[1/9] Updating system packages..."
apt-get update -y
apt-get upgrade -y
apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  git \
  wget

# -------------------------
# 2. Install AWS SSM Agent
# -------------------------
echo "[2/9] Installing AWS SSM Agent..."
snap install amazon-ssm-agent --classic
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
systemctl status snap.amazon-ssm-agent.amazon-ssm-agent.service || true

# -------------------------
# 3. Install Docker
# -------------------------
echo "[3/9] Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

docker --version
docker compose version

# -------------------------
# 4. Install docker-compose (legacy)
# -------------------------
echo "[4/9] Installing docker-compose (legacy)..."
curl -L \
  "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose --version

# -------------------------
# 5. Detect + Mount EBS (NVMe or xvdf)
# -------------------------
echo "[5/9] Detecting and mounting EBS volume..."

mkdir -p /data/mysql

DEVICE=""
for d in /dev/nvme1n1 /dev/xvdf; do
  if [ -b "$d" ]; then
    DEVICE="$d"
    break
  fi
done

if [ -z "$DEVICE" ]; then
  echo "ERROR: EBS device not found"
  lsblk
  exit 1
fi

echo "Using EBS device: $DEVICE"

# Format only if new
blkid "$DEVICE" || mkfs.ext4 "$DEVICE"

# Mount
mount "$DEVICE" /data || true

# Persist mount
UUID=$(blkid -s UUID -o value "$DEVICE")
grep -q "$UUID" /etc/fstab || \
  echo "UUID=$UUID /data ext4 defaults,nofail 0 2" >> /etc/fstab

# Permissions for MySQL container
mkdir -p /data/mysql
chown -R 999:999 /data/mysql || true

df -h | grep /data

# -------------------------
# 6. Clone application repo
# -------------------------
echo "[6/9] Cloning application repository..."
cd /home/ubuntu
rm -rf Student_Simple_Event_Management_With_Docker student-event-management || true

git clone --branch "${docker_compose_branch}" "${docker_compose_repo}"

cd Student_Simple_Event_Management_With_Docker || cd student-event-management

# -------------------------
# 7. Pull Docker images
# -------------------------
echo "[7/9] Pulling Docker images from Docker Hub..."
docker pull vishnuha/student-event-backend:latest || true
docker pull vishnuha/student-event-frontend:latest || true

# -------------------------
# 8. Start containers (STRICT ORDER: MySQL → Backend → Frontend)
# -------------------------
echo "[8/9] Starting containers in order..."

# Copy production compose file
cp docker-compose.prod.yml /home/ubuntu/docker-compose.prod.yml
chown ubuntu:ubuntu /home/ubuntu/docker-compose.prod.yml

# Start MySQL first
echo "Starting MySQL..."
cd /home/ubuntu
docker-compose -f docker-compose.prod.yml up -d mysql

# Wait for MySQL
echo "Waiting for MySQL to be healthy..."
timeout 120 bash -c 'until docker exec student-event-mysql mysqladmin ping -h localhost -pVishnu --silent 2>/dev/null; do sleep 3; done' || echo "MySQL may still be starting..."

# Start Backend
echo "Starting Backend (Spring Boot)..."
docker-compose -f docker-compose.prod.yml up -d backend

# Wait for Backend
echo "Waiting for Backend to be ready..."
sleep 30
timeout 120 bash -c 'until curl -f http://localhost:8080/api/events > /dev/null 2>&1; do sleep 5; done' || echo "Backend may still be starting..."

# Start Frontend
echo "Starting Frontend (React)..."
docker-compose -f docker-compose.prod.yml up -d frontend
sleep 10

# -------------------------
# 9. Health check and setup deployment script
# -------------------------
echo "[9/9] Verifying containers and setting up deployment script..."

# Copy deployment script
if [ -f "/home/ubuntu/Student_Simple_Event_Management_With_Docker/deploy.sh" ]; then
    cp /home/ubuntu/Student_Simple_Event_Management_With_Docker/deploy.sh /home/ubuntu/deploy.sh
    chmod +x /home/ubuntu/deploy.sh
    chown ubuntu:ubuntu /home/ubuntu/deploy.sh
fi

sleep 10
docker-compose -f /home/ubuntu/docker-compose.prod.yml ps

echo "=========================================="
echo "Deployment completed successfully"
echo "=========================================="
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || hostname -I | awk '{print $1}')
echo "Frontend: http://$$PUBLIC_IP"
echo "Frontend: http://$$PUBLIC_IP:3000"
echo "Backend:  http://$$PUBLIC_IP:8080"
echo "API:      http://$$PUBLIC_IP:8080/api/events"
echo ""
echo "To redeploy: sudo bash /home/ubuntu/deploy.sh"
echo "Logs:        docker-compose -f /home/ubuntu/docker-compose.prod.yml logs -f"
echo "=========================================="
