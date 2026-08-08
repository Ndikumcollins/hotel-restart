pipeline {
    agent any

    environment {
        AWS_REGION     = 'us-east-1'
        ECR_REGISTRY   = '099720109477.dkr.ecr.us-east-1.amazonaws.com' // Replace with your AWS Account ID
        ECR_REPO       = 'hotel-restart-app'
        APP_NAME       = 'hotel-restart'
        IMAGE_TAG      = "${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"
        CREDENTIALS_ID = 'aws-credentials' // Configured in Jenkins Credentials Store
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 1, unit: 'HOURS')
        timestamps()
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
                sh 'echo "Building commit: ${GIT_COMMIT}"'
            }
        }

        stage('Security & Vulnerability Scan') {
            steps {
                script {
                    echo "Scanning Dockerfile and code structure for security issues..."
                    // Trivy filesystem scan
                    sh 'trivy fs --severity HIGH,CRITICAL .'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building Docker container image version: ${IMAGE_TAG}"
                    sh "docker build -t ${ECR_REPO}:${IMAGE_TAG} ."
                    sh "docker tag ${ECR_REPO}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}"
                    sh "docker tag ${ECR_REPO}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPO}:latest"
                }
            }
        }

        stage('Push Image to Amazon ECR') {
            steps {
                script {
                    echo "Authenticating with AWS ECR and pushing image..."
                    withCredentials([usernamePassword(credentialsId: "${CREDENTIALS_ID}", passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                        sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                        sh "docker push ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}"
                        sh "docker push ${ECR_REGISTRY}/${ECR_REPO}:latest"
                    }
                }
            }
        }

        stage('Deploy to EKS Cluster') {
            steps {
                script {
                    echo "Updating Kubernetes manifests and deploying to EKS..."
                    withCredentials([usernamePassword(credentialsId: "${CREDENTIALS_ID}", passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                        sh "aws eks update-kubeconfig --region ${AWS_REGION} --name hotel-restart-eks"
                        
                        // Update deployment image tag dynamically
                        sh "sed -i 's|image: hotel-restart-app:v1|image: ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}|g' k8s/deployment.yaml"
                        
                        // Apply to Kubernetes
                        sh "kubectl apply -f k8s/deployment.yaml"
                        sh "kubectl apply -f k8s/service.yaml"
                        sh "kubectl rollout status deployment/hotel-restart-deployment --timeout=180s"
                    }
                }
            }
        }
    }

    post {
        always {
            echo "Cleaning up local build artifacts..."
            sh "docker rmi ${ECR_REPO}:${IMAGE_TAG} || true"
        }
        success {
            echo "Pipeline completed successfully! Application is live on EKS."
        }
        failure {
            echo "Pipeline failed. Check build logs for details."
        }
    }
}
