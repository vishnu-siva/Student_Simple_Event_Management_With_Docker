                                                sh '''
                                                        set -e
                                                        echo "Waiting for backend to be ready..."
                                                        READY=""
                                                        for i in $(seq 1 60); do
                                                            if docker-compose -f docker-compose.test.yml exec -T backend curl -sf http://localhost:8080/api/events > /dev/null 2>&1; then
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
                                if docker-compose -f docker-compose.test.yml exec -T backend curl -sf http://localhost:8080/api/events > /dev/null 2>&1; then
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
                                    if docker-compose -f docker-compose.test.yml exec -T backend curl -sf http://localhost:8080/api/events > /dev/null 2>&1; then
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
