pipeline {
    agent any

    stages {
        stage('Build Luxury Image') {
            steps {
                echo 'Building container image using legacy daemon engine...'
                // Disabling BuildKit inside Jenkins to avoid missing buildx errors
                sh 'DOCKER_BUILDKIT=0 docker build -t hotel-restart-app .'
            }
        }

        stage('Deploy Live Instance') {
            steps {
                echo 'Cleaning up old sandbox environments...'
                sh 'docker stop hotel-sandbox || true'
                sh 'docker rm hotel-sandbox || true'
                
                echo 'Launching fresh container on port 9999...'
                sh 'docker run -d --name hotel-sandbox -p 9999:80 hotel-restart-app'
            }
        }

        stage('Smoke Test Validation') {
            steps {
                echo 'Pausing for web server initialization...'
                sleep 3
                
                echo 'Verifying HTTP handshake response status...'
                sh 'curl -I http://localhost:9999 | grep "200 OK"'
            }
        }
    }
}
