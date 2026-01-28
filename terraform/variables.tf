variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "student-event-management"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"

  validation {
    condition     = can(regex("^t[2-3]\\.", var.instance_type))
    error_message = "Instance type must be t2 or t3 family."
  }
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "student-event-app-server"
}

variable "enable_public_ip" {
  description = "Enable public IP assignment"
  type        = bool
  default     = true
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH into the instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]
  # ⚠️ WARNING: "0.0.0.0/0" allows SSH from anywhere. For production, use your IP only!
}

variable "docker_compose_repo" {
  description = "GitHub repository URL for docker-compose.yml"
  type        = string
  default     = "https://github.com/vishnu-siva/Student_Simple_Event_Management_With_Docker.git"
}

variable "docker_compose_branch" {
  description = "Git branch to clone"
  type        = string
  default     = "main"
}

variable "dockerhub_backend_image" {
  description = "DockerHub image for backend"
  type        = string
  default     = "vishnuha/student-event-backend:latest"
}

variable "dockerhub_frontend_image" {
  description = "DockerHub image for frontend"
  type        = string
  default     = "vishnuha/student-event-frontend:latest"
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default = {
    Team   = "Development"
    CostCenter = "Education"
  }
}
