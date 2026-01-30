pipeline {
    agent any

    options {
        timeout(time: 30, unit: 'MINUTES')
    }

    parameters {
        booleanParam(name: 'PUSH_IMAGES', defaultValue: false, description: 'Push built images to Docker Hub')
    }

    environment {
        DOCKER_IMAGE_BACKEND = 'vishnuha/student-event-backend'
        DOCKER_IMAGE_FRONTEND = 'vishnuha/student-event-frontend'
        AWS_DEFAULT_REGION = 'us-east-1'
    }

    stages {
        stage('Verify Agent Tools') {
            steps {
                sh '''
                    set -e
                    echo "User: $(whoami)"
                    echo "Checking Docker CLI..."
                    docker --version || { echo "ERROR: Docker CLI not found."; exit 1; }
                    echo "Checking Docker daemon..."
                    docker info > /dev/null 2>&1 || { echo "ERROR: Docker daemon not reachable. Add Jenkins user to docker group and restart Jenkins."; exit 1; }
                    echo "Checking Docker Compose..."
                    (docker-compose --version || docker compose version) > /dev/null 2>&1 || { echo "ERROR: Docker Compose not found."; exit 1; }
                    echo "Checking Git..."
                    git --version > /dev/null 2>&1 || { echo "ERROR: Git not found."; exit 1; }
                    echo "Checking curl..."
                    curl --version > /dev/null 2>&1 || { echo "ERROR: curl not found."; exit 1; }
                '''
            }
        }

        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/vishnu-siva/Student_Simple_Event_Management_With_Docker.git',
                        credentialsId: 'github-credentials'
                    ]]
                ])
            }
        }

        stage('Build Backend') {
            steps {
                dir('Backend/student-event-management/student-event-management') {
                    sh '''
                        set -euo pipefail
                        echo "[Backend] Building image ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER}"
                        docker build -t ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER} .
                        echo "[Backend] Tagging latest"
                        docker tag ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER} ${DOCKER_IMAGE_BACKEND}:latest
                        echo "[Backend] Inspect built image"
                        docker image inspect ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER} > /dev/null
                        echo "[Backend] Images present:"
                        docker images | grep student-event-backend || true
                    '''
                }
            }
        }

        stage('Build Frontend') {
            steps {
                dir('Frontend/studenteventsimplemanagement') {
                    sh '''
                        set -euo pipefail
                        echo "[Frontend] Building image ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER}"
                        docker build -t ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER} .
                        echo "[Frontend] Inspect built image"
                        docker image inspect ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER} > /dev/null
                        echo "[Frontend] Tagging latest"
                        docker tag ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER} ${DOCKER_IMAGE_FRONTEND}:latest
                        echo "[Frontend] Images present:"
                        docker images | grep student-event-frontend || true
                    '''
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    try {
                        sh '''
                            echo "Stopping any conflicting containers on test ports..."
                            docker ps -q --filter "name=student-event-mysql" | xargs -r docker stop || true
                            docker ps -q --filter "name=student-event-backend" --filter "publish=8080" | xargs -r docker stop || true
                            docker ps -q --filter "name=student-event-frontend" --filter "publish=3000" | xargs -r docker stop || true
                        '''
                        sh 'docker-compose -f docker-compose.test.yml up -d || docker compose -f docker-compose.test.yml up -d'
                        sh '''
                            set -e
                            echo "Waiting for backend to be ready (via curl container)..."
                            # Determine the Compose network name the backend is attached to
                            BACKEND_CONTAINER_ID=$(docker compose -f docker-compose.test.yml ps -q backend)
                            echo "Backend container ID: ${BACKEND_CONTAINER_ID}"
                            NETWORK_NAME=$(docker inspect "${BACKEND_CONTAINER_ID}" --format '{{range $k,$v := .NetworkSettings.Networks}}{{printf "%s" $k}}{{end}}')
                            echo "Detected network: ${NETWORK_NAME}"
                            # Ensure we have a curl image available
                            docker pull curlimages/curl:8.5.0 > /dev/null 2>&1 || true
                            READY=""
                            for i in $(seq 1 60); do
                                if docker run --rm --network "${NETWORK_NAME}" curlimages/curl:8.5.0 -sSf http://backend:8080/api/events > /dev/null 2>&1; then
                                    echo "Backend is up."
                                    READY=1
                                    break
                                fi
                                sleep 2
                            done
                            if [ -z "${READY}" ]; then
                                echo "Backend not ready in time. Showing service status and logs:"
                                (docker-compose -f docker-compose.test.yml ps || docker compose -f docker-compose.test.yml ps) || true
                                (docker-compose -f docker-compose.test.yml logs backend || docker compose -f docker-compose.test.yml logs backend) || true
                                exit 1
                            fi
                        '''
                    } finally {
                        sh 'docker-compose -f docker-compose.test.yml down -v || docker compose -f docker-compose.test.yml down -v'
                    }
                }
            }
        }

        stage('Push Images') {
            when { expression { return params.PUSH_IMAGES } }
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASS')]) {
                    sh 'echo ${DOCKERHUB_PASS} | docker login -u ${DOCKERHUB_USER} --password-stdin'
                    sh 'docker push ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER}'
                    sh 'docker push ${DOCKER_IMAGE_BACKEND}:latest'
                    sh 'docker push ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER}'
                    sh 'docker push ${DOCKER_IMAGE_FRONTEND}:latest'
                }
            }
        }

        stage('Deploy to EC2') {
            when { expression { return params.PUSH_IMAGES } }
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    script {
                        echo '🚀 Triggering deployment on EC2 instance...'
                        
                        // Your EC2 instance ID (permanent - never changes)
                        def instanceId = env.EC2_INSTANCE_ID ?: 'i-0230831a6bf5c2650'
                        
                        // Option 1: Use SSM to run deployment script
                        sh """
                            echo "Deploying via AWS SSM to instance: ${instanceId}"
                            echo "AWS Account: \$(aws sts get-caller-identity --query 'Account' --output text)"
                            echo "AWS Region: ${AWS_DEFAULT_REGION}"
                            
                            # Check if instance is running
                            INSTANCE_STATE=\$(aws ec2 describe-instances --instance-ids ${instanceId} --region ${AWS_DEFAULT_REGION} --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null || echo 'not-found')
                            
                            if [ "\$INSTANCE_STATE" = "running" ]; then
                                echo "✅ Instance is running, deploying..."
                                
                                # Execute deployment script via SSM
                                aws ssm send-command \\
                                    --instance-ids ${instanceId} \\
                                    --region ${AWS_DEFAULT_REGION} \\
                                    --document-name "AWS-RunShellScript" \\
                                    --parameters 'commands=[
                                        "sudo -u ubuntu bash /home/ubuntu/deploy.sh"
                                    ]' \\
                                    --comment "Jenkins triggered deployment - Build #${BUILD_NUMBER}" \\
                                    --output text
                                
                                echo "✅ Deployment triggered successfully!"
                            else
                                echo "⚠️  Instance not running (state: \$INSTANCE_STATE), skipping deployment"
                                echo "You can manually deploy later using Terraform"
                            fi
                        """
                        
                        // Option 2: Use SSH if SSM is not available
                        // Uncomment this if you prefer SSH
                        /*
                        withCredentials([sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                            sh """
                                # Get EC2 public IP
                                EC2_IP=\$(aws ec2 describe-instances --instance-ids ${instanceId} --region ${AWS_DEFAULT_REGION} --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
                                
                                echo "Deploying to EC2 at \$EC2_IP"
                            
                            # Copy deployment script
                            scp -i \${SSH_KEY} -o StrictHostKeyChecking=no deploy.sh \${SSH_USER}@\${EC2_IP}:/home/ubuntu/
                            
                            # Execute deployment
                            ssh -i \${SSH_KEY} -o StrictHostKeyChecking=no \${SSH_USER}@\${EC2_IP} 'sudo bash /home/ubuntu/deploy.sh'
                            
                            echo "✅ Deployment completed!"
                        """
                    }
                    */
                    }
                }
            }
        }

        stage('Deploy to AWS with Terraform') {
            when {
                allOf {
                    expression { return params.PUSH_IMAGES }
                    expression { return env.BRANCH_NAME == null || env.BRANCH_NAME == 'main' }
                }
            }
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir('terraform') {
                        sh '''
                            echo "================================"
                            echo "Deploying to AWS with Terraform"
                            echo "================================"
                            
                            # Install Terraform if not present
                            if ! command -v terraform &> /dev/null; then
                                echo "Installing Terraform..."
                                curl -sSL https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip -o /tmp/terraform.zip
                                unzip -o /tmp/terraform.zip -d /usr/local/bin/
                                rm /tmp/terraform.zip
                            fi
                            
                            terraform version
                            
                            # Initialize with remote backend (S3)
                            # This preserves state across Jenkins runs
                            terraform init -reconfigure
                            
                            # Plan to check what changes are needed
                            terraform plan -out=tfplan
                            
                            # Apply only if changes detected
                            # This reuses existing instances instead of recreating
                            terraform apply -auto-approve tfplan

                            echo "Deployment complete!"
                            echo ""
                            echo "Application URLs:"
                            terraform output application_urls
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'
            cleanWs()
        }
        success {
            echo 'Local CI pipeline completed successfully.'
        }
        failure {
            echo 'Local CI pipeline failed.'
        }
    }
}
