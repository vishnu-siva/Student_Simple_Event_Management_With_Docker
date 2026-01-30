# 🚀 EC2 Deployment Automation - Complete Setup

## ✅ What's Configured

### **1. Docker Compose Production File** (`docker-compose.prod.yml`)
- **Strict startup order**: MySQL → Backend → Frontend
- **Health checks** for each service
- **EBS volume** mounted at `/data/mysql` for persistent MySQL data
- Uses Docker Hub images (not building locally)

### **2. Deployment Script** (`deploy.sh`)
- Runs on EC2 instance
- Pulls latest images from Docker Hub
- Restarts containers in correct order
- Validates each service before starting the next
- Located at: `/home/ubuntu/deploy.sh` on EC2

### **3. Terraform Configuration** (Updated)
- **IAM role for SSM** (no SSH needed)
- **SSM Agent** auto-installed on EC2
- **User-data script** that:
  - Installs Docker & Docker Compose
  - Mounts EBS volume for MySQL
  - Pulls images from Docker Hub
  - Starts containers in order: MySQL → Backend → Frontend
  - Sets up deployment script

### **4. Jenkins Pipeline** (Updated Jenkinsfile)
New stage added: **"Deploy to EC2"**
- Triggers after "Push Images" stage
- Two deployment options:
  - **Option 1** (Active): AWS SSM - no SSH needed
  - **Option 2** (Commented): SSH deployment

## 📋 Complete Workflow

```
GitHub (main branch)
  ↓
Jenkins detects push
  ↓
Build Backend Image → Build Frontend Image
  ↓
Run Tests
  ↓
Push to Docker Hub (when PUSH_IMAGES=true)
  - vishnuha/student-event-backend:latest
  - vishnuha/student-event-frontend:latest
  ↓
Deploy to EC2 (automatic)
  - AWS SSM sends command to EC2
  - Runs /home/ubuntu/deploy.sh
  ↓
EC2 Deployment:
  1. Pull latest images
  2. Stop old containers
  3. Start MySQL → wait until healthy
  4. Start Backend → wait until healthy
  5. Start Frontend
```

## 🔧 Setting Up EC2 Instance

### **Option A: Create New Instance with Terraform**

```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```

This creates:
- ✅ EC2 instance with SSM support
- ✅ Elastic IP (permanent address)
- ✅ EBS volume for MySQL (/data/mysql)
- ✅ Security groups (ports 22, 80, 443, 3000, 8080)
- ✅ Auto-deployment on startup

### **Option B: Manual EC2 Setup**

If you prefer manual setup:

1. **Create EC2 instance** (Ubuntu 22.04, t3.micro)
2. **Attach Elastic IP**
3. **Create & attach EBS volume** (20GB, mount at `/data`)
4. **Create IAM role** with `AmazonSSMManagedInstanceCore` policy
5. **SSH to instance** and run:

```bash
# Install Docker
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker ubuntu

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Clone repo
git clone https://github.com/vishnu-siva/Student_Simple_Event_Management_With_Docker.git
cd Student_Simple_Event_Management_With_Docker

# Copy files
cp docker-compose.prod.yml /home/ubuntu/
cp deploy.sh /home/ubuntu/
chmod +x /home/ubuntu/deploy.sh

# Initial deployment
sudo bash /home/ubuntu/deploy.sh
```

## 🎯 Jenkins Configuration

### **Required Credentials**

1. **`dockerhub-credentials`** (Username/Password)
   - Docker Hub username & password

2. **`aws-access-key-id`** (Secret text)
   - AWS Access Key ID

3. **`aws-secret-access-key`** (Secret text)
   - AWS Secret Access Key

4. **`ec2-ssh-key`** (SSH Username + Private Key) - Optional
   - Username: `ubuntu`
   - Private key: your `.pem` file content

### **Environment Variable to Set**

After Terraform creates EC2:

1. Go to Jenkins → Configure System
2. Add environment variable:
   - Name: `EC2_INSTANCE_ID`
   - Value: `i-xxxxxxxxxxxxxxxxx` (from Terraform output)

OR modify Jenkinsfile line 157 to hardcode your instance ID.

## 🔄 Manual Deployment (Anytime)

### From Jenkins:
1. Go to your pipeline
2. Click "Build with Parameters"
3. Check ✅ **PUSH_IMAGES**
4. Click "Build"

### From EC2 directly:
```bash
ssh -i your-key.pem ubuntu@<ELASTIC_IP>
sudo bash /home/ubuntu/deploy.sh
```

### From your local machine (with AWS CLI):
```bash
aws ssm send-command \
    --instance-ids i-xxxxxxxxxxxxxxxxx \
    --region us-east-1 \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["sudo -u ubuntu bash /home/ubuntu/deploy.sh"]'
```

## 📊 Monitoring Deployment

### Check container status:
```bash
docker-compose -f /home/ubuntu/docker-compose.prod.yml ps
```

### View logs:
```bash
# All services
docker-compose -f /home/ubuntu/docker-compose.prod.yml logs -f

# Specific service
docker-compose -f /home/ubuntu/docker-compose.prod.yml logs -f mysql
docker-compose -f /home/ubuntu/docker-compose.prod.yml logs -f backend
docker-compose -f /home/ubuntu/docker-compose.prod.yml logs -f frontend
```

### Access application:
- Frontend: `http://<ELASTIC_IP>` or `http://<ELASTIC_IP>:3000`
- Backend: `http://<ELASTIC_IP>:8080`
- API: `http://<ELASTIC_IP>:8080/api/events`

## 🎉 Next Steps

1. **Create EC2 instance**:
   ```bash
   cd terraform
   terraform apply -auto-approve
   ```

2. **Note the Elastic IP** from Terraform output

3. **Set `EC2_INSTANCE_ID` in Jenkins** (from Terraform output)

4. **Run Jenkins pipeline** with `PUSH_IMAGES=true`

5. **Access your app** at `http://<ELASTIC_IP>`

## 🔐 Security Notes

⚠️ **Before Production:**
- Change MySQL password in `docker-compose.prod.yml`
- Restrict SSH access in security group (not 0.0.0.0/0)
- Use AWS Secrets Manager for sensitive data
- Enable HTTPS with SSL certificate
- Set up CloudWatch monitoring

---

**All files are committed to GitHub and ready for use!** 🚀
