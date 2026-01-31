#!/bin/bash
aws ssm send-command \
  --instance-ids i-0230831a6bf5c2650 \
  --region us-east-1 \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=[
    "cd /home/ubuntu",
    "echo === Pulling latest images ===",
    "docker compose -f docker-compose.prod.yml pull",
    "echo === Stopping containers ===",
    "docker compose -f docker-compose.prod.yml down || true",
    "echo === Starting MySQL ===",
    "docker compose -f docker-compose.prod.yml up -d mysql",
    "sleep 40",
    "echo === Starting Backend ===",
    "docker compose -f docker-compose.prod.yml up -d backend",
    "sleep 30",
    "echo === Starting Frontend ===",
    "docker compose -f docker-compose.prod.yml up -d frontend",
    "sleep 10",
    "docker compose -f docker-compose.prod.yml ps"
  ]' \
  --comment "Deploy all containers" \
  --output text
