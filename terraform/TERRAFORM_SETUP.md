# Terraform AWS EC2 Deployment Guide
## Student Event Management System

---

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [File Structure](#file-structure)
3. [Quick Start](#quick-start)
4. [Configuration](#configuration)
5. [Deployment](#deployment)
6. [Accessing Your Application](#accessing-your-application)
7. [Monitoring & Logs](#monitoring--logs)
8. [Cleanup](#cleanup)
9. [Troubleshooting](#troubleshooting)
10. [Cost Estimation](#cost-estimation)

---

## Prerequisites

### Required Tools

1. **Terraform** (v1.0+)
   ```bash
   # Install Terraform
   # macOS
   brew install terraform
   
   # Ubuntu/Debian
   sudo apt-get install terraform
   
   # Windows
   choco install terraform
   
   # Verify installation
   terraform --version
   ```

2. **AWS CLI** (v2.0+)
   ```bash
   # Install AWS CLI
   # macOS
   brew install awscli
   
   # Ubuntu/Debian
   sudo apt-get install awscliv2
   
   # Windows
   choco install awscli
   
   # Verify installation
   aws --version
   ```

3. **AWS Account**
   - Create account at https://aws.amazon.com
   - Free tier includes t2.micro instance (perfect for this project)

### AWS Credentials

1. Create AWS Access Keys:
   - Go to AWS Console → IAM → Users → Your Username
   - Click "Create access key"
   - Save Access Key ID and Secret Access Key

2. Configure AWS CLI:
   ```bash
   aws configure
   # Enter:
   # - AWS Access Key ID
   # - AWS Secret Access Key
   # - Default region: us-east-1
   # - Default output format: json
   ```

   Or set environment variables:
   ```bash
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   export AWS_DEFAULT_REGION="us-east-1"
   ```

3. Verify credentials:
   ```bash
   aws sts get-caller-identity
   ```

---

## File Structure

```
terraform/
├── provider.tf              # AWS provider configuration
├── variables.tf             # Input variables (configurable)
├── main.tf                  # EC2 instance definition
├── security_groups.tf       # Networking & firewall rules
├── outputs.tf               # Output values (IP, URLs, etc)
├── terraform.tfvars         # Variable values (your config)
├── user-data.sh            # Script to setup Docker on EC2
├── TERRAFORM_SETUP.md       # This file
├── terraform.tfstate        # State file (auto-generated - DO NOT EDIT)
└── .terraform/              # Terraform cache (auto-generated)
```

---

## Quick Start

### 1. Initialize Terraform

```bash
cd terraform/
terraform init
```

**What it does:**
- Downloads AWS provider
- Sets up .terraform directory
- Validates provider configuration

**Expected output:**
```
Terraform has been successfully configured!
```

---

### 2. Review Configuration

Edit `terraform.tfvars` if you want to change defaults:

```hcl
aws_region = "us-east-1"           # ← Change region if desired
instance_type = "t2.micro"         # ← Free tier instance
environment = "dev"                # ← Your environment name
allowed_ssh_cidrs = ["0.0.0.0/0"]  # ⚠️ Restrict this for production!
```

**Important variables:**
- `instance_type`: t2.micro (free), t2.small, t3.micro, etc
- `aws_region`: Where to deploy (us-east-1, eu-west-1, etc)
- `environment`: dev, staging, or prod
- `dockerhub_backend_image`: Docker Hub image for backend
- `dockerhub_frontend_image`: Docker Hub image for frontend

---

### 3. Plan Deployment

```bash
terraform plan
```

**What it does:**
- Analyzes current state
- Compares desired state
- Shows what will be created/modified

**You'll see:**
```
Plan: 8 to add, 0 to change, 0 to destroy.
```

**Review the output carefully before proceeding!**

---

### 4. Apply Configuration

```bash
terraform apply
```

**What it does:**
- Creates EC2 instance on AWS
- Configures security groups
- Runs user-data.sh to setup Docker

**Steps:**
1. Review the plan again
2. Type `yes` to confirm
3. Wait 2-5 minutes for infrastructure creation

**Important:** Note the output values (public IP, URLs)

---

### 5. Access Your Application

Once deployment completes, you'll see:

```
Outputs:

instance_public_ip = "54.123.45.67"
instance_public_dns = "ec2-54-123-45-67.compute-1.amazonaws.com"
application_urls = {
  "api" = "http://54.123.45.67:8080/api/events"
  "backend" = "http://54.123.45.67:8080"
  "frontend" = "http://54.123.45.67:3000"
}
```

**Wait 2-3 minutes for services to start**, then:
- Frontend: http://54.123.45.67:3000
- Backend: http://54.123.45.67:8080
- API: http://54.123.45.67:8080/api/events

---

## Configuration

### terraform.tfvars Variables

#### AWS Configuration

```hcl
aws_region = "us-east-1"           # AWS region
environment = "dev"                # dev, staging, or prod
```

**Available AWS regions:**
- us-east-1 (N. Virginia)
- us-west-2 (Oregon)
- eu-west-1 (Ireland)
- ap-northeast-1 (Tokyo)

#### Instance Configuration

```hcl
instance_type = "t2.micro"         # Instance type
instance_name = "student-event-app" # Name tag
```

**Free tier eligible:**
- t2.micro (1 vCPU, 1GB RAM) - Recommended
- t2.small (1 vCPU, 2GB RAM)
- t3.micro (2 vCPU, 1GB RAM)

**⚠️ Note:** t2.micro is free for 12 months (750 hours/month)

#### Network Configuration

```hcl
enable_public_ip = true            # Assign public IP
allowed_ssh_cidrs = ["0.0.0.0/0"]  # SSH access control
```

**For production, restrict SSH:**
```hcl
allowed_ssh_cidrs = ["203.0.113.0/32"]  # Your IP only
```

To find your IP:
```bash
curl https://checkip.amazonaws.com
```

#### Container Images

```hcl
dockerhub_backend_image  = "vishnuha/student-event-backend:latest"
dockerhub_frontend_image = "vishnuha/student-event-frontend:latest"
```

Change to use different image versions:
```hcl
dockerhub_backend_image = "vishnuha/student-event-backend:1.0.0"
```

#### Repository Configuration

```hcl
docker_compose_repo = "https://github.com/vishnu-siva/Student_Simple_Event_Management_With_Docker.git"
docker_compose_branch = "main"
```

Change to deploy from different branch:
```hcl
docker_compose_branch = "development"
```

### Advanced Configuration

#### Change Instance Size Later

```bash
# Edit terraform.tfvars
instance_type = "t2.small"

# Apply changes
terraform plan
terraform apply
```

#### Add More Security Group Rules

Edit `security_groups.tf` to add new rules:

```hcl
# Example: Allow custom port
resource "aws_vpc_security_group_ingress_rule" "custom_port" {
  security_group_id = aws_security_group.app_sg.id
  description       = "Allow custom port"
  from_port         = 5000
  to_port           = 5000
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "custom-port-ingress"
  }
}
```

---

## Deployment

### Step-by-Step Deployment

#### Step 1: Navigate to terraform directory
```bash
cd terraform/
```

#### Step 2: Initialize Terraform
```bash
terraform init
```

#### Step 3: Review the plan
```bash
terraform plan
```

Look for:
- ✅ 8 resources to add (EC2, security group, Elastic IP)
- ✅ No changes or deletions
- ✅ Correct region (us-east-1 or your choice)

#### Step 4: Deploy
```bash
terraform apply
```

Type `yes` when prompted.

**⏱️ Wait 3-5 minutes for complete deployment**

Terraform will:
1. Create EC2 instance (30 seconds)
2. Configure security groups (10 seconds)
3. Assign Elastic IP (10 seconds)
4. Run user-data script (2-4 minutes)

#### Step 5: Copy output values
Save the output for later:
```
instance_public_ip = "54.123.45.67"
application_urls = {...}
```

---

### Verify Deployment

```bash
# Check instance status
aws ec2 describe-instances --query 'Reservations[0].Instances[0].State'

# Check Docker containers
ssh -i your-key.pem ubuntu@54.123.45.67 'docker-compose ps'

# Check logs
ssh -i your-key.pem ubuntu@54.123.45.67 'docker-compose logs'
```

---

## Accessing Your Application

### Via Browser

Once deployed, access at:

| Service | URL |
|---------|-----|
| **Frontend** | http://YOUR_PUBLIC_IP:3000 |
| **Backend API** | http://YOUR_PUBLIC_IP:8080 |
| **API Endpoint** | http://YOUR_PUBLIC_IP:8080/api/events |

**Replace `YOUR_PUBLIC_IP` with actual IP from Terraform output**

### Via SSH

Connect to your instance:

```bash
ssh -i your-key.pem ubuntu@54.123.45.67
```

**Note:** AWS generates a key pair. You need the private key file (.pem)

#### To generate key pair:
```bash
aws ec2 create-key-pair --key-name student-event-key \
  --query 'KeyMaterial' --output text > student-event-key.pem
chmod 400 student-event-key.pem
```

Then specify it in terraform.tfvars:
```hcl
key_name = "student-event-key"
```

### Via AWS Console

1. Go to AWS Console → EC2 → Instances
2. Find instance named "student-event-app"
3. View details:
   - Public IP
   - Security Groups
   - Status
   - Monitoring

---

## Monitoring & Logs

### View User-Data Logs

SSH into instance and check startup logs:

```bash
ssh -i your-key.pem ubuntu@54.123.45.67
cat /var/log/user-data.log
```

### View Docker Logs

```bash
# SSH into instance first
ssh -i your-key.pem ubuntu@54.123.45.67

# View all container logs
docker-compose logs

# View specific service
docker-compose logs backend
docker-compose logs frontend
docker-compose logs mysql

# Follow logs in real-time
docker-compose logs -f

# View last N lines
docker-compose logs --tail=50
```

### Monitor Instance in AWS Console

1. Go to EC2 Dashboard
2. Select your instance
3. Click "Monitoring" tab
4. View:
   - CPU Utilization
   - Network traffic
   - Disk operations

### Check Terraform State

```bash
# View current state
terraform show

# Show specific resource
terraform state show aws_instance.app_server

# List all resources
terraform state list
```

---

## Cleanup

### Destroy Infrastructure (Delete Everything)

⚠️ **This will delete your EC2 instance and all data!**

```bash
terraform destroy
```

**Prompts:**
```
Do you really want to destroy all resources?
Only 'yes' will be accepted to confirm.
```

Type `yes` to confirm.

**What gets deleted:**
- EC2 instance
- Security groups
- Elastic IP
- Associated volumes

**What doesn't get deleted:**
- Terraform state file (.tfstate)
- docker-compose configurations in repository

### Preserve Infrastructure

To keep the instance but stop Terraform management:

```bash
# Remove from state (doesn't delete resources)
terraform state rm aws_instance.app_server
terraform state rm aws_security_group.app_sg

# Now you can manually manage via AWS Console
```

### Keep Infrastructure, Pause Billing

```bash
# SSH into instance
ssh -i your-key.pem ubuntu@54.123.45.67

# Stop containers
docker-compose down

# Stop EC2 instance (via AWS Console)
# Right-click instance → Instance State → Stop
```

Restarting:
```bash
# Start instance (via AWS Console)
# SSH back in
docker-compose up -d
```

---

## Troubleshooting

### Problem: "terraform init" fails

**Error:** "No valid credential sources found"

**Solution:**
```bash
aws configure
# Or set environment variables
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
```

### Problem: "terraform apply" fails

**Error:** "InvalidKeyPair.NotFound"

**Solution:** EC2 key pair doesn't exist. Create it:
```bash
aws ec2 create-key-pair --key-name student-event-key \
  --query 'KeyMaterial' --output text > student-event-key.pem
chmod 400 student-event-key.pem
```

### Problem: Application not accessible after deployment

**Possible causes:**
1. Services still starting (wait 2-3 minutes)
2. Security group rules not applied
3. Docker containers failed to start

**Debug steps:**
```bash
# SSH into instance
ssh -i your-key.pem ubuntu@54.123.45.67

# Check containers
docker-compose ps

# View logs
docker-compose logs

# Check if ports are listening
netstat -tulpn | grep LISTEN
```

### Problem: "Permission denied" when SSHing

**Error:** "Permission denied (publickey)"

**Solution:**
```bash
# Ensure key file has correct permissions
chmod 400 your-key.pem

# Verify key matches instance
aws ec2 describe-key-pairs --key-names your-key-name

# Try with verbose output
ssh -vv -i your-key.pem ubuntu@YOUR_IP
```

### Problem: Docker images not pulling

**Error:** "Error response from daemon: pull access denied"

**Solution:**
```bash
# SSH into instance
ssh -i your-key.pem ubuntu@YOUR_IP

# Check Docker login
docker login

# Check image availability
docker pull vishnuha/student-event-backend:latest
```

### Problem: Port 3000 or 8080 not responding

**Check if ports are open:**
```bash
# From your computer
curl http://YOUR_IP:3000
curl http://YOUR_IP:8080

# From instance
ssh -i your-key.pem ubuntu@YOUR_IP
curl localhost:3000
curl localhost:8080

# Check security group rules
aws ec2 describe-security-groups --query 'SecurityGroups[0].IpPermissions'
```

### Problem: Terraform state issues

**State file corrupted:**
```bash
# Backup current state
cp terraform.tfstate terraform.tfstate.backup

# Refresh state
terraform refresh

# Re-import resources if needed
terraform import aws_instance.app_server i-0123456789abcdef
```

---

## Cost Estimation

### Free Tier (First 12 Months)

| Resource | Free Tier | Cost |
|----------|-----------|------|
| EC2 t2.micro | 750 hours/month | FREE |
| Elastic IP | 1 | FREE (if associated) |
| Data transfer | 15 GB/month | FREE |

**Total:** FREE (as long as you use t2.micro and stay within limits)

### After Free Tier

| Resource | Size | Cost/Month |
|----------|------|-----------|
| EC2 t2.micro | 1 vCPU, 1GB | ~$9 |
| Elastic IP | static IP | ~$3 |
| Data transfer | 1 GB | ~$0.09 |

**Total:** ~$12/month for production setup

### Cost Optimization

1. **Use t2.micro** - Free tier eligible, sufficient for learning
2. **Stop instance when not needed** - Elastic IP still charges (~$3)
3. **Use spot instances** - Up to 70% cheaper (add to Terraform)
4. **Monitor with CloudWatch** - Set up billing alerts

### AWS Billing Alert

```bash
# Go to AWS Console → Billing → Billing Preferences
# Enable "Receive CloudWatch Alarms"
# Set alert threshold ($10, $25, etc)
```

---

## Next Steps

After successful deployment:

1. ✅ **Verify application works** - Test frontend and API
2. ✅ **Check logs** - Ensure services started correctly
3. ✅ **Test database** - Create an event through API
4. ☐ **Configure domain name** - Use Route53 or external DNS
5. ☐ **Add SSL certificate** - Use ACM + ALB
6. ☐ **Set up backups** - Automated database backups
7. ☐ **Configure auto-scaling** - Auto Scaling Groups
8. ☐ **Add monitoring** - CloudWatch dashboards

---

## Additional Resources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [Terraform Best Practices](https://www.terraform.io/cloud-docs/recommended-practices)
- [AWS Free Tier Details](https://aws.amazon.com/free/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

---

## Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review Terraform output (run `terraform show`)
3. Check AWS Console logs
4. Consult official documentation

---

**Last Updated:** January 28, 2026  
**Status:** Complete Terraform setup ready for AWS deployment  
**Next:** Run `terraform init` to begin!
