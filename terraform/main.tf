# AWS EC2 Infrastructure Configuration
# Data source to find the latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# User data script to setup Docker and deploy application
locals {
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    docker_compose_repo   = var.docker_compose_repo
    docker_compose_branch = var.docker_compose_branch
    backend_image         = var.dockerhub_backend_image
    frontend_image        = var.dockerhub_frontend_image
  }))
}

# EC2 Instance
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  
  # Enable public IP assignment
  associate_public_ip_address = var.enable_public_ip
  key_name = var.key_name

  # User data to install Docker and deploy application
  user_data = local.user_data

  # Enable detailed monitoring (optional, add cost)
  monitoring = var.enable_detailed_monitoring

  # Storage configuration
  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true

    tags = {
      Name = "${var.instance_name}-root-volume"
    }
  }

  # Instance metadata options (security best practice)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tags = merge(
    {
      Name = var.instance_name
    },
    var.tags
  )

  depends_on = [aws_security_group.app_sg]

  # Lifecycle configuration to avoid accidental destruction
  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP for stable public address
resource "aws_eip" "app_eip" {
  count    = var.enable_public_ip ? 1 : 0
  instance = aws_instance.app_server.id
  domain   = "vpc"

  tags = {
    Name = "${var.instance_name}-eip"
  }

  depends_on = [aws_instance.app_server]
}
