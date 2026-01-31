#!/bin/bash
INSTANCE_ID="i-0e91a17492dc81172"
REGION="us-east-1"

echo "Sending deploy command to instance..."
CMD_ID=$(aws ssm send-command \
  --instance-ids $INSTANCE_ID \
  --region $REGION \
  --document-name AWS-RunShellScript \
  --parameters 'commands=["/home/ubuntu/deploy.sh"]' \
  --query Command.CommandId \
  --output text 2>&1)

echo "Command ID: $CMD_ID"
echo "Waiting for deployment to complete..."
sleep 20

echo ""
echo "Deployment Status:"
aws ssm get-command-invocation \
  --command-id "$CMD_ID" \
  --instance-id $INSTANCE_ID \
  --region $REGION \
  --query '{Status:Status, StandardOutputContent:StandardOutputContent}' \
  --output text 2>&1 | head -200
