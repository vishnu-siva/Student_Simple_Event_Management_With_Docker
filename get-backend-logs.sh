#!/bin/bash
aws ssm send-command \
  --instance-ids i-0e91a17492dc81172 \
  --region us-east-1 \
  --document-name AWS-RunShellScript \
  --parameters "commands=[\"docker logs student-event-backend\"]" \
  --query Command.CommandId \
  --output text > /tmp/cmd_id.txt

CMD_ID=$(cat /tmp/cmd_id.txt)
echo "Command ID: $CMD_ID"
sleep 10

aws ssm get-command-invocation \
  --command-id "$CMD_ID" \
  --instance-id i-0e91a17492dc81172 \
  --region us-east-1 \
  --query StandardOutputContent \
  --output text
