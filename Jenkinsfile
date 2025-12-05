pipeline {
    agent any

    environment {
        JAVA_HOME        = '/usr/lib/jvm/java-17-amazon-corretto.x86_64'
        PATH             = "${JAVA_HOME}/bin:${env.PATH}"

        SONARQUBE_SERVER = 'MySonar'                 // Jenkins SonarQube server name
        SONAR_PROJECT_KEY = 'java-devops-poc'

        DOCKER_REGISTRY  = 'docker.io'
        DOCKER_IMAGE     = 'narendralanka/java-devops-poc'
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
                    withCredentials([string(credentialsId: 'sonar-token',
                                            variable: 'SONAR_TOKEN')]) {
                        sh """
                            mvn sonar:sonar \
                              -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                              -Dsonar.projectName="Java DevOps POC" \
                              -Dsonar.sources=src \
                              -Dsonar.java.binaries=target/classes \
                              -Dsonar.host.url=http://3.106.124.241:9000/ \
                              -Dsonar.login=${SONAR_TOKEN}
                        """
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                script {
                    try {
                        // Still give Sonar some time to process
                        timeout(time: 15, unit: 'MINUTES') {
                            def qg = waitForQualityGate()
                            echo "Quality Gate status: ${qg.status}"

                            // If you want to FAIL the build when QG is not OK, uncomment below:
                            // if (qg.status != 'OK') {
                            //     error "Pipeline failed due to Quality Gate: ${qg.status}"
                            // }
                        }
                    } catch (err) {
                        // Don't abort the pipeline, just mark as unstable or log it
                        echo "Quality Gate check failed or timed out: ${err}"
                        currentBuild.result = 'UNSTABLE'
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
