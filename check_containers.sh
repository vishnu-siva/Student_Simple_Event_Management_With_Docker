#!/bin/bash

# Send command to check Docker containers
COMMAND_ID=$(aws ssm send-command \
  --instance-ids i-0230831a6bf5c2650 \
  --region us-east-1 \
  --document-name AWS-RunShellScript \
  --parameters 'commands=["sudo docker ps -a","echo ---","sudo docker-compose -f /home/ubuntu/docker-compose.prod.yml ps"]' \
  --output text \
  --query 'Command.CommandId')

echo "Command ID: $COMMAND_ID"
echo "Waiting for execution..."
sleep 8

# Retrieve the output
echo "=== DOCKER PS OUTPUT ==="
aws ssm get-command-invocation \
  --command-id $COMMAND_ID \
  --instance-id i-0230831a6bf5c2650 \
  --region us-east-1 \
  --output text \
  --query 'StandardOutputContent'

echo ""
echo "=== ERRORS (if any) ==="
aws ssm get-command-invocation \
  --command-id $COMMAND_ID \
  --instance-id i-0230831a6bf5c2650 \
  --region us-east-1 \
  --output text \
  --query 'StandardErrorContent'
