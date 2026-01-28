output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.app_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.app_server.private_ip
}

output "elastic_ip_address" {
  description = "Elastic IP address (stable public IP)"
  value       = var.enable_public_ip ? aws_eip.app_eip[0].public_ip : null
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.app_server.public_dns
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.app_sg.id
}

output "security_group_name" {
  description = "Security group name"
  value       = aws_security_group.app_sg.name
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = data.aws_ami.ubuntu.id
}

output "ami_name" {
  description = "AMI name"
  value       = data.aws_ami.ubuntu.name
}

output "ssh_command" {
  description = "Command to SSH into the instance"
  value       = "ssh -i /path/to/your-key.pem ubuntu@${aws_instance.app_server.public_ip}"
}

output "application_urls" {
  description = "URLs to access the application"
  value = {
    frontend = "http://${aws_instance.app_server.public_ip}:3000"
    backend  = "http://${aws_instance.app_server.public_ip}:8080"
    api      = "http://${aws_instance.app_server.public_ip}:8080/api/events"
  }
}

output "deployment_summary" {
  description = "Summary of the deployment"
  value = {
    instance_id      = aws_instance.app_server.id
    instance_type    = var.instance_type
    region           = var.aws_region
    environment      = var.environment
    public_ip        = aws_instance.app_server.public_ip
    elastic_ip       = var.enable_public_ip ? aws_eip.app_eip[0].public_ip : null
    frontend_url     = "http://${aws_instance.app_server.public_ip}:3000"
    backend_url      = "http://${aws_instance.app_server.public_ip}:8080"
    backend_image    = var.dockerhub_backend_image
    frontend_image   = var.dockerhub_frontend_image
    status           = "Check the EC2 console for instance status"
    logs_command     = "ssh -i /path/to/your-key.pem ubuntu@${aws_instance.app_server.public_ip} 'docker-compose logs -f'"
  }
}
