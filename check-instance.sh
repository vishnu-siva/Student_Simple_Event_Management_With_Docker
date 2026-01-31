#!/bin/bash
set -e

INSTANCE_ID="i-0e91a17492dc81172"
REGION="us-east-1"

echo "=== Checking Docker Containers ==="
CMD_ID=$(aws ssm send-command \
  --instance-ids $INSTANCE_ID \
  --document-name "AWS-RunShellScript" \
  --parameters "commands=[\"docker ps -a\"]" \
  --region $REGION \
  --query "Command.CommandId" \
  --output text)

echo "Command ID: $CMD_ID"
sleep 5

echo ""
echo "=== Container Status ==="
aws ssm get-command-invocation \
  --command-id $CMD_ID \
  --instance-id $INSTANCE_ID \
  --region $REGION \
  --query "StandardOutputContent" \
  --output text

echo ""
echo "=== Checking if deploy.sh exists ==="
CMD_ID2=$(aws ssm send-command \
  --instance-ids $INSTANCE_ID \
  --document-name "AWS-RunShellScript" \
  --parameters "commands=[\"ls -lah /home/ubuntu/deploy.sh\"]" \
  --region $REGION \
  --query "Command.CommandId" \
  --output text)

sleep 5
aws ssm get-command-invocation \
  --command-id $CMD_ID2 \
  --instance-id $INSTANCE_ID \
  --region $REGION \
  --query "StandardOutputContent" \
  --output text

echo ""
echo "=== Last 50 lines of cloud-init log ==="
CMD_ID3=$(aws ssm send-command \
  --instance-ids $INSTANCE_ID \
  --document-name "AWS-RunShellScript" \
  --parameters "commands=[\"tail -50 /var/log/cloud-init-output.log\"]" \
  --region $REGION \
  --query "Command.CommandId" \
  --output text)

sleep 5
aws ssm get-command-invocation \
  --command-id $CMD_ID3 \
  --instance-id $INSTANCE_ID \
  --region $REGION \
  --query "StandardOutputContent" \
  --output text
