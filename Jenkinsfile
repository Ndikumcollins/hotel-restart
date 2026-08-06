pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                sh 'ls -la'
            }
        }
        stage('Terraform Init') {
            steps {
                echo 'Initializing Terraform...'
                sh 'terraform version || echo "Terraform step ready!"'
            }
        }
    }
}
