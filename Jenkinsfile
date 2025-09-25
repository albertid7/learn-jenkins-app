pipeline {
    agent any

    environment {
        CI = 'true'
        GENERATE_SOURCEMAP = 'false'
    }

    stages {
        stage('Build') {
            agent {
                docker {
                    image 'node:18-alpine'
                    reuseNode true
                    args '-m 2g'
                }
            }
            steps {
                sh '''
                    ls -la
                    node --version
                    npm --version
                    npm cache clean --force
                    npm install --verbose
                    npm run build
                    ls -la build/
                '''
            }
        }
        stage('Test') {
            agent {
                docker {
                    image 'node:18-alpine'
                    reuseNode true
                    args '-m 2g'
                }
            }
            steps {
                sh '''
                    ls -la
                    node --version
                    npm --version
                    npm install --verbose
                    test -f build/index.html && echo "Build artifact exists" || echo "Build artifact missing"
                    npm test -- --watchAll=false --verbose
                '''
            }
        }
    }
}
