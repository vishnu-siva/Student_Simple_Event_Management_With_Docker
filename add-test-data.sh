#!/bin/bash

# Add test data to your application
# Usage: ./add-test-data.sh [server-url]
# Example: ./add-test-data.sh http://100.48.233.10:8080

# Use provided URL or get from Terraform output
if [ -n "$1" ]; then
  SERVER="$1"
elif [ -f "terraform/terraform.tfstate" ]; then
  ELASTIC_IP=$(cd terraform && terraform output -raw elastic_ip_address 2>/dev/null)
  SERVER="http://${ELASTIC_IP}:8080"
else
  echo "Error: Please provide server URL"
  echo "Usage: ./add-test-data.sh http://YOUR-IP:8080"
  exit 1
fi

echo "Server: $SERVER"
echo "Adding test events to database..."

# Event 1: Tech Workshop (Approved)
curl -X POST "$SERVER/api/events" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Spring Boot Workshop",
    "description": "Learn modern backend development with Spring Boot 3",
    "date": "2026-02-15",
    "time": "14:00:00",
    "location": "Computer Lab A",
    "status": "APPROVED"
  }'
echo ""

# Event 2: Career Fair (Approved)
curl -X POST "$SERVER/api/events" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Tech Career Fair 2026",
    "description": "Meet recruiters from top tech companies",
    "date": "2026-02-20",
    "time": "10:00:00",
    "location": "Main Auditorium",
    "status": "APPROVED"
  }'
echo ""

# Event 3: Hackathon (Pending)
curl -X POST "$SERVER/api/events" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "24-Hour Hackathon",
    "description": "Build innovative solutions in 24 hours",
    "date": "2026-03-01",
    "time": "09:00:00",
    "location": "Engineering Building",
    "status": "PENDING"
  }'
echo ""

# Event 4: AI Seminar (Approved)
curl -X POST "$SERVER/api/events" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "AI & Machine Learning Seminar",
    "description": "Introduction to AI and ML fundamentals",
    "date": "2026-02-25",
    "time": "15:30:00",
    "location": "Lecture Hall 101",
    "status": "APPROVED"
  }'
echo ""

echo ""
echo "Test data added! Check your application at:"
echo "Frontend: ${SERVER%:8080}:3000"
echo "Backend: $SERVER"
echo ""
echo "Fetching all events:"
curl -s "$SERVER/api/events" | python3 -m json.tool || curl -s "$SERVER/api/events"
