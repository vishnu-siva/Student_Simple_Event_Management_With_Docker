# AWS Region
aws_region = "us-east-1"

# Project Configuration
project_name = "student-event-management"
environment  = "dev"

# Instance Configuration
instance_type = "t3.micro"            # Free tier eligible
instance_name = "student-event-app"
key_name = "student-event-key"


# Networking
enable_public_ip   = true
allowed_ssh_cidrs  = ["0.0.0.0/0"]    # ⚠️  For production, restrict to your IP

# Container Images
dockerhub_backend_image  = "vishnuha/student-event-backend:latest"
dockerhub_frontend_image = "vishnuha/student-event-frontend:latest"

# Repository Configuration
docker_compose_repo   = "https://github.com/vishnu-siva/Student_Simple_Event_Management_With_Docker.git"
docker_compose_branch = "main"

# Monitoring
enable_detailed_monitoring = false    # true adds cost

# Additional Tags
tags = {
  Team       = "Development"
  CostCenter = "Education"
  Purpose    = "Learning & Deployment"
}
