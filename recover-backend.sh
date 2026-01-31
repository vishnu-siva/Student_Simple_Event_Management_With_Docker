#!/bin/bash
set -e

INSTANCE_ID="i-0e91a17492dc81172"
REGION="us-east-1"

echo "=== Step 1: Stop all containers ==="
aws ssm send-command \
  --instance-ids $INSTANCE_ID \
  --region $REGION \
  --document-name AWS-RunShellScript \
  --parameters 'commands=["cd /home/ubuntu && docker-compose -f docker-compose.prod.yml down"]' \
  --query Command.CommandId --output text > /tmp/cmd1.txt

sleep 5

echo "=== Step 2: Start MySQL only ==="
aws ssm send-command \
  --instance-ids $INSTANCE_ID \
  --region $REGION \
  --document-name AWS-RunShellScript \
  --parameters 'commands=["cd /home/ubuntu && docker-compose -f docker-compose.prod.yml up -d mysql"]' \
  --query Command.CommandId --output text > /tmp/cmd2.txt

sleep 10
echo "Waiting for MySQL to be ready..."
sleep 30

echo "=== Step 3: Start Backend only and watch logs ==="
aws ssm send-command \
  --instance-ids $INSTANCE_ID \
  --region $REGION \
  --document-name AWS-RunShellScript \
  --parameters 'commands=["cd /home/ubuntu && docker-compose -f docker-compose.prod.yml up backend"]' \
  --query Command.CommandId --output text > /tmp/cmd3.txt

CMD_ID=$(cat /tmp/cmd3.txt)
sleep 15

echo "Getting backend startup logs..."
aws ssm get-command-invocation \
  --command-id "$CMD_ID" \
  --instance-id $INSTANCE_ID \
  --region $REGION \
  --query StandardOutputContent \
  --output text
