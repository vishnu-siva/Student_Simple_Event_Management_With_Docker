# Complete Docker & Deployment Guide
## Student Event Management System

**Last Updated:** January 28, 2026

---

## Table of Contents
1. [Docker Images Overview](#docker-images-overview)
2. [DockerHub vs GitHub Container Registry](#dockerhub-vs-github-container-registry)
3. [Current Setup (Local Development)](#current-setup-local-development)
4. [Building Docker Images](#building-docker-images)
5. [Pushing to Registries](#pushing-to-registries)
6. [AWS EC2 & Terraform Deployment](#aws-ec2--terraform-deployment)
7. [Complete Deployment Pipeline](#complete-deployment-pipeline)
8. [FAQ & Common Questions](#faq--common-questions)

---

## Docker Images Overview

### What is a Docker Image?

A Docker image is a **standardized package that contains everything needed to run your application:**
- Application code
- Dependencies
- Configuration
- Runtime environment
- Database configuration

Think of it like a **shipping container** - once built, it can run the same way everywhere (your computer, AWS, another server, etc.).

### Container vs Image

| Term | Meaning | Analogy |
|------|---------|---------|
| **Image** | Blueprint/template (static) | Recipe for a cake |
| **Container** | Running instance (dynamic) | Actual baked cake |

---

## DockerHub vs GitHub Container Registry

### DockerHub

**What it is:** Default Docker registry, owned by Docker Inc.

**Location:** `hub.docker.com`

**Image Names:** `username/image-name:tag`

**Example:** `vishnuha/student-event-backend:latest`

**Pros:**
- ✅ Industry standard
- ✅ Free public images
- ✅ Easy to use
- ✅ Large community
- ✅ Well documented

**Cons:**
- ⚠️ Limited private image support (free tier)
- ⚠️ Separate from GitHub

### GitHub Container Registry (GHCR)

**What it is:** Docker registry hosted by GitHub

**Location:** `ghcr.io`

**Image Names:** `ghcr.io/username/image-name:tag`

**Example:** `ghcr.io/vishnu-siva/student-event-backend:latest`

**Pros:**
- ✅ Better GitHub integration
- ✅ Good private image support
- ✅ Everything in one place (code + images)
- ✅ Free for public images

**Cons:**
- ⚠️ Less community resources
- ⚠️ Newer than DockerHub

### Are They Connected?

**NO** - They are completely **separate registries.**

```
DockerHub                          GitHub Container Registry
├─ vishnuha/student-event-backend  ├─ ghcr.io/vishnu-siva/student-event-backend
├─ vishnuha/student-event-frontend ├─ ghcr.io/vishnu-siva/student-event-frontend
└─ hub.docker.com                  └─ ghcr.io
```

### Can Both Be Used?

**YES** - You can push the **same image to both registries:**

```
Build Docker Image (once)
        ↓
    Tag it twice
        ↓
    ┌─────────────────┬─────────────────┐
    ↓                 ↓
Push to DockerHub    Push to GHCR
    ↓                 ↓
hub.docker.com    ghcr.io (two separate locations)
```

**Benefits:**
- ✅ Redundancy - if one registry has issues, use the other
- ✅ Backup - images stored in two places
- ✅ Flexibility - deploy from either registry
- ✅ No conflicts - they work independently

---

## Current Setup (Local Development)

### Architecture

```
Your Computer
    ↓
Git Repository
    ↓
Docker Compose (docker-compose.yml)
    ↓
MySQL + Backend + Frontend (local containers)
    ↓
Accessible at: http://localhost:3000
```

### Services in Docker Compose

| Service | Port | Purpose |
|---------|------|---------|
| MySQL | 3307 (internal: 3306) | Database |
| Backend | 8080 | Spring Boot API |
| Frontend | 3000 | React web app |

### Files Involved

```
project-root/
├── docker-compose.yml          # Local development setup
├── docker-compose.test.yml     # Testing setup (Jenkins uses this)
├── Jenkinsfile                 # CI/CD pipeline
├── Backend/
│   └── student-event-management/
│       └── Dockerfile          # Backend image definition
└── Frontend/
    └── studenteventsimplemanagement/
        └── Dockerfile          # Frontend image definition
```

### Current Limitations

- ❌ Only runs on your computer
- ❌ Stops when you shut down PC
- ❌ Can't access from other devices
- ❌ No automatic updates
- ❌ No backup if computer crashes

---

## Building Docker Images

### Two Methods

#### Method 1: Local Clone & Build (RECOMMENDED - You're Using This)

**Steps:**
1. Clone repository locally
2. Navigate to project folder
3. Build image from Dockerfile
4. Push to registry

**Command:**
```bash
# Clone
git clone https://github.com/vishnu-siva/Student_Simple_Event_Management_With_Docker.git
cd Student_Simple_Event_Management_With_Docker

# Build Backend
cd Backend/student-event-management/student-event-management
docker build -t vishnuha/student-event-backend:latest .

# Build Frontend
cd ../../..
cd Frontend/studenteventsimplemanagement
docker build -t vishnuha/student-event-frontend:latest .
```

**Pros:**
- ✅ **Fast** - clone once, build multiple times
- ✅ **Flexible** - can modify code before building
- ✅ **Full control** - access to all files
- ✅ **Testing** - can run tests before building

**Cons:**
- ❌ Need to clone first

**This is what YOUR Jenkinsfile does!** ✅

---

#### Method 2: GitHub Direct Build

**Steps:**
1. Build directly from GitHub URL
2. Docker downloads and builds simultaneously

**Command:**
```bash
# Build Backend directly from GitHub
docker build -t student-event-backend:latest \
  https://github.com/vishnu-siva/Student_Simple_Event_Management_With_Docker.git#main:Backend/student-event-management/student-event-management

# Build Frontend directly from GitHub
docker build -t student-event-frontend:latest \
  https://github.com/vishnu-siva/Student_Simple_Event_Management_With_Docker.git#main:Frontend/studenteventsimplemanagement
```

**Syntax:**
```
docker build -t IMAGE_NAME GITHUB_URL#BRANCH:PATH_TO_DOCKERFILE
```

**Pros:**
- ✅ Simple - single command
- ✅ No cloning needed

**Cons:**
- ❌ **SLOWER** - downloads repo for each build
- ❌ **REPEATED clones** - can't reuse code
- ❌ **No testing** - hard to run tests
- ❌ **Limited control** - harder to modify

**NOT RECOMMENDED for production**

---

## Pushing to Registries

### Your Current Jenkinsfile

Your Jenkinsfile already pushes to **DockerHub** when `PUSH_IMAGES` parameter is true.

**Current behavior:**
```groovy
stage('Push Images') {
    when { expression { return params.PUSH_IMAGES } }
    steps {
        withCredentials([usernamePassword(...)]) {
            sh 'echo ${DOCKERHUB_PASS} | docker login -u ${DOCKERHUB_USER} --password-stdin'
            sh 'docker push ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER}'
            sh 'docker push ${DOCKER_IMAGE_BACKEND}:latest'
            sh 'docker push ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER}'
            sh 'docker push ${DOCKER_IMAGE_FRONTEND}:latest'
        }
    }
}
```

### To Push to Both (Future Enhancement)

You would add:

```groovy
stage('Push to DockerHub') {
    when { expression { return params.PUSH_IMAGES } }
    steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', ...)]) {
            sh 'echo ${DOCKERHUB_PASS} | docker login -u ${DOCKERHUB_USER} --password-stdin hub.docker.com'
            sh 'docker push ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER}'
            sh 'docker push ${DOCKER_IMAGE_BACKEND}:latest'
            sh 'docker push ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER}'
            sh 'docker push ${DOCKER_IMAGE_FRONTEND}:latest'
            sh 'docker logout'
        }
    }
}

stage('Push to GitHub Container Registry') {
    when { expression { return params.PUSH_IMAGES } }
    steps {
        withCredentials([usernamePassword(credentialsId: 'ghcr-credentials', ...)]) {
            sh 'echo ${GHCR_PASS} | docker login -u ${GHCR_USER} --password-stdin ghcr.io'
            sh 'docker tag ${DOCKER_IMAGE_BACKEND}:latest ghcr.io/${GHCR_USER}/student-event-backend:latest'
            sh 'docker tag ${DOCKER_IMAGE_FRONTEND}:latest ghcr.io/${GHCR_USER}/student-event-frontend:latest'
            sh 'docker push ghcr.io/${GHCR_USER}/student-event-backend:latest'
            sh 'docker push ghcr.io/${GHCR_USER}/student-event-frontend:latest'
            sh 'docker logout'
        }
    }
}
```

---

## AWS EC2 & Terraform Deployment

### What is AWS EC2?

**EC2 = Elastic Compute Cloud**

A **cloud server** that runs 24/7, accessible from anywhere in the world.

**Instead of:**
```
Your Computer (must be on)
    ↓
Docker Compose runs app
    ↓
http://localhost:3000
```

**You get:**
```
AWS EC2 Server (always on, in cloud)
    ↓
Docker containers run on server
    ↓
https://your-domain.com (accessible worldwide)
```

### What is Terraform?

**Terraform = Infrastructure as Code**

Code that **automatically creates and configures** cloud infrastructure.

**Instead of:**
```
Manually click AWS console buttons
    ↓
Create server
    ↓
Configure networking
    ↓
Install Docker
    ↓
Deploy app (error-prone, slow)
```

**You write:**
```hcl
resource "aws_instance" "app_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  ...
}
```

**Benefits:**
- ✅ Reproducible - same setup every time
- ✅ Version controlled - changes tracked in Git
- ✅ Automated - one command creates everything
- ✅ Scalable - easily create multiple servers

### How Terraform Works

**Step 1: Write Terraform code**
```hcl
# main.tf
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  tags = {
    Name = "event-app-server"
  }
}
```

**Step 2: Initialize Terraform**
```bash
terraform init
```

**Step 3: Plan (preview changes)**
```bash
terraform plan
# Shows what will be created
```

**Step 4: Apply (create infrastructure)**
```bash
terraform apply
# Actually creates the EC2 instance on AWS
```

**Step 5: Destroy (cleanup)**
```bash
terraform destroy
# Deletes everything created
```

---

## Complete Deployment Pipeline

### Phase 1: Local Development (NOW)

```
Developer writes code
    ↓
Git push to GitHub
    ↓
Jenkins detects push
    ↓
    ├─ Verify tools
    ├─ Checkout code
    ├─ Build Backend Docker image
    ├─ Build Frontend Docker image
    ├─ Test with docker-compose.test.yml
    └─ (Optional) Push to DockerHub
```

**Result:** Docker images built and tested locally

---

### Phase 2: Multi-Registry Push (NEXT)

```
Same as Phase 1, plus:
    ↓
    ├─ Push to DockerHub: vishnuha/student-event-backend:latest
    └─ Push to GHCR: ghcr.io/vishnu-siva/student-event-backend:latest
```

**Result:** Images stored in two registries for redundancy

---

### Phase 3: AWS Deployment (FUTURE)

```
Jenkins pushes to DockerHub/GHCR
    ↓
Terraform reads new image tags
    ↓
    ├─ Create AWS EC2 instance
    ├─ Install Docker on EC2
    ├─ Pull image from DockerHub
    ├─ Run containers on EC2
    └─ Expose ports (80, 443)
```

**Result:** App running on AWS, accessible at domain.com

---

### Complete Full Pipeline

```
Developer Code
    ↓
    ├─ Writes Java/React code
    └─ Commits to GitHub
    ↓
GitHub Webhook
    ↓
    └─ Triggers Jenkins automatically
    ↓
Jenkins Pipeline
    ├─ Clone code from GitHub
    ├─ Build Docker images
    ├─ Run tests
    ├─ Push to DockerHub
    └─ Push to GHCR
    ↓
Docker Registries
    ├─ DockerHub: vishnuha/student-event-backend
    └─ GHCR: ghcr.io/vishnu-siva/student-event-backend
    ↓
Terraform (AWS)
    ├─ Create EC2 instance
    ├─ Pull images from registry
    └─ Deploy containers
    ↓
AWS EC2 Running
    ├─ MySQL database
    ├─ Spring Boot backend
    └─ React frontend
    ↓
Users Access
    └─ https://your-event-management-app.com
```

---

## Your Current Status

### What You Have ✅

- ✅ Dockerized application (Backend + Frontend + MySQL)
- ✅ Docker Compose for local development
- ✅ Jenkins CI/CD pipeline
- ✅ Automated Docker image building
- ✅ Jenkinsfile with build & test stages
- ✅ DockerHub integration

### What's Next (Optional Enhancements)

| Phase | Task | Effort | Impact |
|-------|------|--------|--------|
| **Phase 2** | Add GHCR push to Jenkinsfile | 30 min | Medium |
| **Phase 3** | Create Terraform files for AWS | 2-3 hours | High |
| **Phase 4** | Set up domain name | 1 hour | High |
| **Phase 5** | Configure CI/CD for Terraform deployment | 2 hours | Very High |

---

## Why Do This?

### Learning Value

✅ **DevOps Skills** - Understanding cloud deployment, infrastructure as code, automation  
✅ **Portfolio** - Shows professional production deployment knowledge  
✅ **Career Ready** - Most companies use this exact stack (Jenkins → Docker → AWS → Terraform)  

### Technical Value

✅ **Reliability** - App always available (24/7)  
✅ **Scalability** - Easily add more servers  
✅ **Automation** - No manual deployments, reduces errors  
✅ **Version Control** - Infrastructure changes tracked in Git  

### Business Value

✅ **Professional** - Not just a student project, enterprise-ready  
✅ **Cost Effective** - AWS free tier for 12 months  
✅ **Accessible** - Anyone can access from anywhere  

---

## FAQ & Common Questions

### Q1: Do I need to use both DockerHub and GHCR?

**A:** No, you only need one.
- **DockerHub** - Industry standard, recommended (what you're using)
- **GHCR** - Nice to have as backup/redundancy

Start with DockerHub, add GHCR later if needed.

---

### Q2: What if I change my Jenkinsfile to GitHub direct build?

**A:** Your pipeline would:
- ❌ Be SLOWER (downloads repo for each build)
- ❌ Lose testing capability (docker-compose.test.yml can't run)
- ❌ Have less control (can't modify code before building)

**Recommendation:** Keep your current approach (local clone & build).

---

### Q3: Will AWS/Terraform affect my current Docker structure?

**A:** NO - Your Docker structure stays the same.
- Your Dockerfiles remain unchanged
- Docker Compose still works locally
- Images pushed same way to DockerHub

Terraform just deploys those same images to AWS.

---

### Q4: How much will AWS cost?

**A:** 
- **Free tier:** 750 hours/month EC2 t2.micro (first 12 months)
- **After free tier:** ~$8-15/month for basic setup
- **With RDS (managed database):** ~$15-30/month

Very cheap for learning and development.

---

### Q5: Can I test everything locally before deploying to AWS?

**A:** YES - Your Docker Compose setup IS your local testing environment.

```
Docker Compose (local) → Works? → Push images → Deploy to AWS (same images)
```

Same images, different hosting location.

---

### Q6: What's the difference between pushing to both registries?

**A:** 

| Aspect | Explanation |
|--------|-------------|
| **Same Build** | Build image once |
| **Tag Twice** | Tag with DockerHub name AND GHCR name |
| **Push Twice** | Push to both registries |
| **Storage** | Image stored in two places |
| **Deployment** | Can pull from either registry |

**No connection between them** - they're independent storage locations.

---

### Q7: When should I start with AWS?

**A:** When you:
- ✅ Have stable Docker Compose setup (you do!)
- ✅ Have working Jenkinsfile (you do!)
- ✅ Have DockerHub images working (you do!)
- ✅ Want to learn cloud deployment

**You're ready to start anytime!**

---

### Q8: Will my application architecture change for AWS?

**A:** NO - Architecture stays the same:

```
Local (Docker Compose):          AWS (Terraform):
├─ MySQL 8.0                     ├─ RDS (managed MySQL)
├─ Spring Boot backend           ├─ ECS/EC2 (backend)
├─ React frontend                └─ CloudFront (frontend CDN)
└─ Docker network

Same architecture, same containers, different hosting platform.
```

---

### Q9: Do I need to learn Kubernetes?

**A:** NO - Kubernetes is optional.

For your project:
- **Simple:** EC2 + Docker (what we recommend)
- **Advanced:** ECS (AWS container service)
- **Enterprise:** Kubernetes (if you need to)

Start with EC2, upgrade later if needed.

---

### Q10: What about security?

**A:** Production setup would include:
- ✅ Environment variables for secrets (not hardcoded)
- ✅ AWS security groups (firewall rules)
- ✅ HTTPS/SSL certificates
- ✅ Private database (not public)
- ✅ Authentication for admin endpoints

Currently your `docker-compose.yml` has hardcoded credentials - that's fine for learning, change for production!

---

## Next Steps Recommended

### Immediate (Week 1)
1. ✅ Understand current Docker setup (you have this!)
2. ✅ Know Jenkins CI/CD pipeline (you have this!)
3. ✅ Test locally with docker-compose (you have this!)

### Short Term (Week 2-3)
4. ☐ (Optional) Add GHCR push to Jenkinsfile
5. ☐ Create Terraform configuration for AWS
6. ☐ Set up AWS account (free tier)

### Medium Term (Week 4+)
7. ☐ Deploy to AWS EC2 with Terraform
8. ☐ Set up domain name
9. ☐ Configure automatic deployment from Jenkins

---

## Resources

### Docker
- Official Docs: https://docs.docker.com/
- Getting Started: https://docs.docker.com/get-started/

### Terraform
- Official Docs: https://www.terraform.io/docs
- AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs

### AWS
- EC2 Guide: https://docs.aws.amazon.com/ec2/
- Free Tier: https://aws.amazon.com/free/

### Jenkins
- Official Docs: https://www.jenkins.io/doc/

---

## Summary

| Topic | Status | Your Setup |
|-------|--------|-----------|
| **Docker Images** | ✅ Complete | Using Dockerfiles, docker-compose.yml |
| **Local Development** | ✅ Complete | Docker Compose running locally |
| **CI/CD Pipeline** | ✅ Complete | Jenkins building & testing |
| **DockerHub** | ✅ Complete | Images pushed to DockerHub |
| **GHCR** | ☐ Optional | Can add later for redundancy |
| **AWS/EC2** | ☐ Future | Ready to implement anytime |
| **Terraform** | ☐ Future | Ready to implement anytime |

**You already have a professional CI/CD pipeline! 🎉**

Next is just scaling it to the cloud (AWS + Terraform) - which is optional but recommended for learning!

---

**Last Updated:** January 28, 2026  
**Status:** Complete comprehensive guide covering all discussion points  
**Next Action:** Let me know if you want to implement GHCR or AWS/Terraform!
