$commands = @(
    "cd /home/ubuntu"
    "echo '=== Stopping containers ==='"
    "docker compose -f docker-compose.prod.yml down || true"
    "echo '=== Pulling images ==='"
    "docker compose -f docker-compose.prod.yml pull"
    "echo '=== Starting MySQL ==='"
    "docker compose -f docker-compose.prod.yml up -d mysql"
    "sleep 40"
    "echo '=== Starting Backend ==='"
    "docker compose -f docker-compose.prod.yml up -d backend"
    "sleep 30"
    "echo '=== Starting Frontend ==='"
    "docker compose -f docker-compose.prod.yml up -d frontend"
    "sleep 10"
    "echo '=== Container Status ==='"
    "docker compose -f docker-compose.prod.yml ps"
)

$commandsJson = $commands | ConvertTo-Json -Compress

aws ssm send-command `
    --instance-ids i-0230831a6bf5c2650 `
    --region us-east-1 `
    --document-name "AWS-RunShellScript" `
    --parameters "commands=$commandsJson" `
    --comment "Manual container deployment" `
    --output json
