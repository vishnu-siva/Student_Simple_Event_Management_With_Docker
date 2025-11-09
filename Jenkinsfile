
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
                    sh 'docker build -t ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER} .'
                    sh 'docker tag ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER} ${DOCKER_IMAGE_BACKEND}:latest'
                }
            }
        }

        stage('Build Frontend') {
            steps {
                dir('Frontend/studenteventsimplemanagement') {
                    sh 'docker build -t ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER} .'
                    sh 'docker tag ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER} ${DOCKER_IMAGE_FRONTEND}:latest'
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    try {
                        sh 'docker-compose -f docker-compose.test.yml up -d || docker compose -f docker-compose.test.yml up -d'
                        sh 'echo Waiting for backend to start...'
                        sh 'sleep 30'
                        sh 'curl -f http://localhost:8080/api/events || exit 1'
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
