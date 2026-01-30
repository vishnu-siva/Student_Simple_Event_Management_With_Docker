#!/bin/bash

# Check container status
CMD_ID=$(aws ssm send-command \
  --instance-ids i-0230831a6bf5c2650 \
  --region us-east-1 \
  --document-name AWS-RunShellScript \
  --parameters 'commands=["docker ps -a","docker-compose -f /home/ubuntu/docker-compose.prod.yml ps"]' \
  --query 'Command.CommandId' \
  --output text)

echo "=== Checking EC2 Container Status ==="
echo "Command ID: $CMD_ID"
echo "Waiting for execution..."
sleep 8

echo ""
echo "=== Docker Containers ==="
aws ssm get-command-invocation \
  --command-id "$CMD_ID" \
  --instance-id i-0230831a6bf5c2650 \
  --region us-east-1 \
  --query 'StandardOutputContent' \
  --output text

echo ""
echo "=== Errors (if any) ==="
aws ssm get-command-invocation \
  --command-id "$CMD_ID" \
  --instance-id i-0230831a6bf5c2650 \
  --region us-east-1 \
  --query 'StandardErrorContent' \
  --output text
