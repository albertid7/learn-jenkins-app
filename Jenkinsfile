pipeline {
    agent any

    stages {
        stage('Build') {
            agent {
                docker {
                    image 'node:22.20-alpine3.21'
                    reuseNode true
                }
            }
            steps {
                sh '''
                    set -ex
                    export NPM_CONFIG_CACHE=$(pwd)/.npm-cache
                    ls -la
                    node --version
                    npm --version
                    npm run build
                    ls -la
                '''
            }
        }
        stage('Test') {
            agent {
                docker {
                    image 'node:22.20-alpine3.21'
                    reuseNode true
                }
            }
            steps {
                sh '''
                    test -f build/index.html
                    npm test
                '''
            }
        }
    }   
}
