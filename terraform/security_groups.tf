# Security Group for Application
resource "aws_security_group" "app_sg" {
  name_prefix = "${var.project_name}-sg-"
  description = "Security group for Student Event Management application"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

# Inbound Rules

# HTTP traffic (port 80)
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.app_sg.id

  description = "Allow HTTP traffic"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "http-ingress"
  }
}

# HTTPS traffic (port 443)
resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.app_sg.id

  description = "Allow HTTPS traffic"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "https-ingress"
  }
}

# Frontend React app (port 3000)
resource "aws_vpc_security_group_ingress_rule" "frontend" {
  security_group_id = aws_security_group.app_sg.id

  description = "Allow Frontend traffic (development)"
  from_port   = 3000
  to_port     = 3000
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "frontend-ingress"
  }
}

# Backend API (port 8080)
resource "aws_vpc_security_group_ingress_rule" "backend" {
  security_group_id = aws_security_group.app_sg.id

  description = "Allow Backend API traffic (development)"
  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "backend-ingress"
  }
}

# SSH traffic (port 22)
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.app_sg.id

  description = "Allow SSH traffic"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
  cidr_ipv4   = var.allowed_ssh_cidrs[0]

  tags = {
    Name = "ssh-ingress"
  }
}

# Add additional SSH CIDR rules if needed
resource "aws_vpc_security_group_ingress_rule" "ssh_additional" {
  count = length(var.allowed_ssh_cidrs) > 1 ? length(var.allowed_ssh_cidrs) - 1 : 0

  security_group_id = aws_security_group.app_sg.id

  description = "Allow SSH traffic from additional CIDR"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
  cidr_ipv4   = var.allowed_ssh_cidrs[count.index + 1]

  tags = {
    Name = "ssh-ingress-${count.index + 1}"
  }
}

# Outbound Rules (Allow all outbound traffic)
resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.app_sg.id

  description = "Allow all outbound traffic"
  from_port   = -1
  to_port     = -1
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "all-outbound"
  }
}
