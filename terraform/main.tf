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
    PUBLIC_IP             = ""  # This will be fetched dynamically on EC2
  }))
}

# IAM Role for EC2 to access SSM
resource "aws_iam_role" "ec2_ssm_role" {
  name = "${var.project_name}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-ssm-role"
  }
}

# Attach AWS managed policy for SSM
resource "aws_iam_role_policy_attachment" "ec2_ssm_policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

# EC2 Instance
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  
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

resource "aws_ebs_volume" "mysql_data" {
  availability_zone = aws_instance.app_server.availability_zone
  size              = 20
  type              = "gp3"
  encrypted         = true

  tags = {
    Name = "${var.project_name}-mysql-ebs"
  }
}

resource "aws_volume_attachment" "mysql_data_attach" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.mysql_data.id
  instance_id = aws_instance.app_server.id
}
