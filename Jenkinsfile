pipeline {

    agent any



    stages {

        stage('Build') {

            agent {

                docker {

                    image 'node:18-alpine'

                    reuseNode true

                }

            }

            steps {

                sh '''

                ls -la

                node --version

                npm --version

                npm ci

                npm run build

                ls -la

                '''

            }

        }



        stage('Test') {

            agent {

                docker {

                    image 'node:18-alpine'

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



        stage('Deploy') {

            agent {

                docker {

                    image 'node:18-alpine'

                    args '--user root'   // ✅ Runs container as root

                    reuseNode true

                }

            }

            steps {

                sh '''

                    echo "Installing zip..."

                    apk add --no-cache zip  // ✅ Corrected installation command

                    npm install netlify-cli

                    node_modules/.bin/netlify --version

                    zip -r build.zip build

                '''

                archiveArtifacts artifacts: 'build.zip', fingerprint: true

            }

        }

    }

}