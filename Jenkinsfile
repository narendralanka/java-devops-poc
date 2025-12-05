pipeline {
    agent any

    environment {
        // Java 17 on your Jenkins node
        JAVA_HOME = '/usr/lib/jvm/java-17-amazon-corretto.x86_64'
        PATH = "${JAVA_HOME}/bin:${env.PATH}"

        // Name of SonarQube server in Jenkins config (Manage Jenkins → Configure System → SonarQube)
        SONARQUBE_SERVER = 'MySonar'

        // SonarQube project key (must match the project in SonarQube)
        SONAR_PROJECT_KEY = 'java-devops-poc'

        // Docker image details (example: Docker Hub)
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_IMAGE = 'narendralanka/java-devops-poc'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Test') {
            steps {
                sh 'mvn clean verify -B'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONARQUBE_SERVER}") {
                    // Uses Jenkins "Secret text" credential with ID 'sonar-token'
                    withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                        sh '''
                            mvn sonar:sonar \
                              -Dsonar.projectKey=$SONAR_PROJECT_KEY \
                              -Dsonar.projectName="Java DevOps POC" \
                              -Dsonar.sources=src \
                              -Dsonar.java.binaries=target/classes \
                              -Dsonar.host.url=$SONAR_HOST_URL \
                              -Dsonar.login=$SONAR_TOKEN
                        '''
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t ${DOCKER_IMAGE}:${env.BUILD_NUMBER} .
                    docker tag ${DOCKER_IMAGE}:${env.BUILD_NUMBER} ${DOCKER_IMAGE}:latest
                """
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub',
                                                 usernameVariable: 'DOCKER_USER',
                                                 passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin ${DOCKER_REGISTRY}
                        docker push ${DOCKER_IMAGE}:${env.BUILD_NUMBER}
                        docker push ${DOCKER_IMAGE}:latest
                        docker logout ${DOCKER_REGISTRY}
                    """
                }
            }
        }
    }
}
