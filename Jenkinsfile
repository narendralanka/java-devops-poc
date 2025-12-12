pipeline {
    agent any

    environment {
        // Java 17 on your Jenkins node
        JAVA_HOME = '/usr/lib/jvm/java-17-amazon-corretto.x86_64'
        PATH = "${JAVA_HOME}/bin:${env.PATH}"

        // SonarQube
        SONARQUBE_SERVER = 'MySonar'
        SONAR_PROJECT_KEY = 'java-devops-poc'

        // Docker image details
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_IMAGE    = 'narendralanka/java-devops-poc'

        // Trivy settings
        TRIVY_SEVERITY       = 'HIGH,CRITICAL'
        TRIVY_IGNORE_UNFIXED = 'true'
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

        stage('Dependency Check (OWASP)') {
            steps {
                // Runs OWASP Dependency-Check via Maven plugin
                sh '''
                    mvn \
                      org.owasp:dependency-check-maven:8.4.0:check
                '''
                // Archive reports so you can see them in Jenkins
                archiveArtifacts artifacts: 'target/dependency-check-report.*',
                                 allowEmptyArchive: true
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONARQUBE_SERVER}") {
                    withCredentials([string(credentialsId: 'Sonar-Java-Poc', variable: 'SONAR_TOKEN')]) {
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

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t ${DOCKER_IMAGE}:${env.BUILD_NUMBER} .
                    docker tag ${DOCKER_IMAGE}:${env.BUILD_NUMBER} ${DOCKER_IMAGE}:latest
                """
            }
        }

        stage('Trivy Image Scan') {
            steps {
                // Fails the build if HIGH/CRITICAL vulns are found
                sh """
                    trivy image \
                      --severity ${TRIVY_SEVERITY} \
                      --exit-code 1 \
                      --ignore-unfixed=${TRIVY_IGNORE_UNFIXED} \
                      --no-progress \
                      ${DOCKER_IMAGE}:${env.BUILD_NUMBER}
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
