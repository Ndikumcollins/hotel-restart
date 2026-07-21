pipeline {
    agent any

    stages {
        stage('Build Luxury Image') {
            steps {
                echo 'Building container image...'
                sh 'DOCKER_BUILDKIT=0 docker build -t hotel-restart-app .'
            }
        }

        stage('Deploy Live Instance') {
            steps {
                echo 'Cleaning up old container...'
                sh 'docker stop hotel-sandbox || true'
                sh 'docker rm hotel-sandbox || true'
                
                echo 'Launching fresh container...'
                sh 'docker run -d --name hotel-sandbox -p 9999:80 hotel-restart-app'
            }
        }

        stage('Smoke Test Validation') {
            steps {
                echo 'Validating HTTP response...'
                sleep 3
                sh 'curl -I http://localhost:9999 | grep "200 OK"'
            }
        }
    }

    post {
        success {
            sh '''
                curl -X POST -H 'Content-type: application/json' \
                     --data "{\\"text\\":\\"✅ *BUILD SUCCESS*: Branch ${BRANCH_NAME} is live at http://localhost:9999\\"}" \
                     "${SLACK_WEBHOOK_URL}"
            '''
        }
        failure {
            sh '''
                curl -X POST -H 'Content-type: application/json' \
                     --data "{\\"text\\":\\"🚨 *BUILD FAILED*: Pipeline failed on branch ${BRANCH_NAME}. Check Jenkins logs!\\"}" \
                     "${SLACK_WEBHOOK_URL}"
            '''
        }
    }
}
