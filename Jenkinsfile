/*
 Local-only CI pipeline (no AWS deploy yet, Docker Hub push optional).
 Parameters:
     DOCKERHUB_USERNAME  - Used only if PUSH_IMAGES=true.
     PUSH_IMAGES         - false by default so build + test run entirely local.
 Credentials (only needed when PUSH_IMAGES=true):
     dockerhub-credentials (Username/Password for Docker Hub)
 Stages: Checkout -> Build Backend -> Build Frontend -> Test -> (optional) Push
 Result when PUSH_IMAGES=false:
     - Images exist locally: ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER}, :latest and same for frontend.
     - No external registry interaction.
*/
pipeline {
    agent any

    options {
        // Fail fast on first error, keep build logs concise
        ansiColor('xterm')
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
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/vishnu-siva/Student_Simple_Event_Management_With_Docker.git'
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
                        sh 'docker-compose -f docker-compose.test.yml up -d'
                        sh 'echo Waiting for backend to start...'
                        sh 'sleep 30'
                        sh 'curl -f http://localhost:8080/api/events || exit 1'
                    } finally {
                        sh 'docker-compose -f docker-compose.test.yml down -v'
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
