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
                echo 'Initializing Terraform configuration...'
                sh 'terraform init -backend=false'
            }
        }
        stage('Terraform Validate') {
            steps {
                echo 'Validating Terraform syntax...'
                sh 'terraform validate'
            }
        }
    }
}
