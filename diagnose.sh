#!/bin/bash
set -e

INSTANCE_ID="i-0e91a17492dc81172"
REGION="us-east-1"

# Function to send and retrieve command output
run_command() {
    local cmd="$1"
    local desc="$2"
    
    echo ">>> $desc"
    echo "    Command: $cmd"
    
    CMD_ID=$(aws ssm send-command \
        --instance-ids "$INSTANCE_ID" \
        --region "$REGION" \
        --document-name "AWS-RunShellScript" \
        --parameters "commands=$cmd" \
        --query "Command.CommandId" \
        --output text 2>/dev/null)
    
    echo "    Command ID: $CMD_ID"
    sleep 8
    
    OUTPUT=$(aws ssm get-command-invocation \
        --command-id "$CMD_ID" \
        --instance-id "$INSTANCE_ID" \
        --region "$REGION" \
        --query "StandardOutputContent" \
        --output text 2>/dev/null | head -200)
    
    echo "$OUTPUT"
    echo ""
}

echo "=========================================="
echo "Diagnostics for Instance $INSTANCE_ID"
echo "=========================================="
echo ""

run_command '["/bin/bash", "-c", "docker ps -a"]' "Check Docker Containers"
run_command '["/bin/bash", "-c", "ls -lah /home/ubuntu/docker-compose.prod.yml"]' "Check if docker-compose.prod.yml exists"
run_command '["/bin/bash", "-c", "ls -lah /home/ubuntu/deploy.sh"]' "Check if deploy.sh exists"
run_command '["/bin/bash", "-c", "tail -100 /var/log/cloud-init-output.log"]' "Last 100 lines of cloud-init log"

echo "=========================================="
echo "End of Diagnostics"
echo "=========================================="
