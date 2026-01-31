#!/bin/bash

# Write the deploy.sh script content directly via SSM
INSTANCE_ID="i-0e91a17492dc81172"
REGION="us-east-1"

# Simple recovery: just restart docker-compose with updated timeout
echo "=== Restarting containers with new timeout ==="

CMD_ID=$(aws ssm send-command \
  --instance-ids $INSTANCE_ID \
  --region $REGION \
  --document-name AWS-RunShellScript \
  --parameters 'commands=["cd /home/ubuntu && docker-compose -f docker-compose.prod.yml down && sleep 5 && docker-compose -f docker-compose.prod.yml up -d"]' \
  --query Command.CommandId \
  --output text 2>&1)

echo "Command sent: $CMD_ID"
echo "Waiting for containers to start..."
sleep 30

echo "Checking container status..."
aws ssm send-command \
  --instance-ids $INSTANCE_ID \
  --region $REGION \
  --document-name AWS-RunShellScript \
  --parameters 'commands=["docker ps -a"]' \
  --query Command.CommandId \
  --output text > /tmp/check_cmd.txt

CHECK_CMD=$(cat /tmp/check_cmd.txt)
sleep 8

echo ""
echo "Container Status:"
aws ssm get-command-invocation \
  --command-id "$CHECK_CMD" \
  --instance-id $INSTANCE_ID \
  --region $REGION \
  --query StandardOutputContent \
  --output text
