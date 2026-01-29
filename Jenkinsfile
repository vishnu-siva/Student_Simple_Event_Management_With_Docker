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
        AWS_ACCESS_KEY_ID = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
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

        stage('Deploy to AWS with Terraform') {
            when {
                allOf {
                    expression { return params.PUSH_IMAGES }
                    expression { return env.BRANCH_NAME == null || env.BRANCH_NAME == 'main' }
                }
            }
            steps {
                dir('terraform') {
                    sh '''
                        echo "================================"
                        echo "Deploying to AWS with Terraform"
                        echo "================================"

                        # Run Terraform in a container (no local install needed)
                                                docker run --rm \
                                                    --entrypoint sh \
                                                    -e AWS_ACCESS_KEY_ID \
                                                    -e AWS_SECRET_ACCESS_KEY \
                                                    -e AWS_DEFAULT_REGION \
                                                    -v "$PWD":/workspace \
                                                    -w /workspace \
                                                    hashicorp/terraform:1.6.6 \
                                                    -c "terraform init && terraform plan -out=tfplan && terraform apply -auto-approve tfplan"

                        echo "Deployment complete!"
                        echo "App is live at: http://$(docker run --rm -v \"$PWD\":/workspace -w /workspace hashicorp/terraform:1.6.6 output -raw elastic_ip_address):3000"
                    '''
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
