
pipeline {
    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '15'))
        timeout(time: 30, unit: 'MINUTES')
    }

    parameters {
        string(name: 'DOCKERHUB_USERNAME', defaultValue: 'local-user', description: 'Docker Hub username (only used if pushing)')
        booleanParam(name: 'PUSH_IMAGES', defaultValue: false, description: 'Set true to push images to Docker Hub')
    }

    environment {
        DOCKER_IMAGE_BACKEND = "${params.DOCKERHUB_USERNAME}/student-event-backend"
        DOCKER_IMAGE_FRONTEND = "${params.DOCKERHUB_USERNAME}/student-event-frontend"
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
                    echo "Checking curl..."
                    curl --version > /dev/null 2>&1 || { echo "ERROR: curl not found."; exit 1; }
                '''
            }
        }
        stage('Checkout') {
            steps {
               
                checkout scm
            }
        }

        stage('Build Backend') {
            steps {
                dir('Backend/student-event-management/student-event-management') {
                    sh '''
                        set -euo
                        echo "[Backend] Building image ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER}"
                        docker build --progress=plain -t ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER} .
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
                        set -euo
                        echo "[Frontend] Building image ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER}"
                        docker build --progress=plain -t ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER} .
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
                                                sh 'docker-compose -f docker-compose.test.yml up -d || docker compose -f docker-compose.test.yml up -d'
                                                sh '''
                                                        set -e
                                                        echo "Waiting for backend to be ready..."
                                                        READY=""
                                                        for i in $(seq 1 60); do
                                                            if curl -sf http://localhost:8080/api/events > /dev/null; then
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
