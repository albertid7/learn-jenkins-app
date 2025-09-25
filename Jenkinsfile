pipeline {
    agent any
    
    environment {
        // Docker image names
        APP_IMAGE = "learn-jenkins-app"
        BUILD_NUMBER_TAG = "${env.BUILD_NUMBER}"
        LATEST_TAG = "latest"
        
        // Application version from package.json or build number
        REACT_APP_VERSION = "${env.BUILD_NUMBER}"
        
        // Docker registry (for future use)
        DOCKER_REGISTRY = "localhost:5000"
    }
    
    options {
        // Keep builds for 30 days or last 10 builds
        buildDiscarder(logRotator(daysToKeepStr: '30', numToKeepStr: '10'))
        
        // Timeout after 30 minutes
        timeout(time: 30, unit: 'MINUTES')
        
        // Disable concurrent builds
        disableConcurrentBuilds()
    }
    
    stages {
        stage('Checkout & Preparation') {
            steps {
                script {
                    // Clean workspace
                    cleanWs()
                    
                    // Checkout code (if running from SCM)
                    checkout scm
                    
                    // Display environment info
                    echo "Building React App - Build #${env.BUILD_NUMBER}"
                    echo "Node.js version check..."
                    echo "Docker version check..."
                    
                    sh '''
                        echo "=== Environment Information ==="
                        echo "Build Number: ${BUILD_NUMBER}"
                        echo "Build URL: ${BUILD_URL}"
                        echo "Workspace: ${WORKSPACE}"
                        
                        echo "=== Docker Information ==="
                        docker --version
                        docker-compose --version
                        
                        echo "=== Project Files ==="
                        ls -la
                    '''
                }
            }
        }
        
        stage('Build Application') {
            parallel {
                stage('Docker Build - Production') {
                    steps {
                        script {
                            echo "Building production Docker image..."
                            
                            sh '''
                                # Build production image
                                docker build -t ${APP_IMAGE}:${BUILD_NUMBER_TAG} .
                                docker tag ${APP_IMAGE}:${BUILD_NUMBER_TAG} ${APP_IMAGE}:${LATEST_TAG}
                                
                                # Display image info
                                docker images | grep ${APP_IMAGE}
                            '''
                        }
                    }
                }
                
                stage('Build Assets') {
                    agent {
                        docker {
                            image 'node:18-alpine'
                            args '-v ${WORKSPACE}:/workspace -w /workspace'
                            reuseNode true
                        }
                    }
                    steps {
                        sh '''
                            echo "=== Node.js Build Environment ==="
                            node --version
                            npm --version
                            
                            echo "=== Installing Dependencies ==="
                            npm ci
                            
                            echo "=== Building Application ==="
                            REACT_APP_VERSION=${BUILD_NUMBER} npm run build
                            
                            echo "=== Build Output ==="
                            ls -la build/
                            
                            echo "=== Verifying Build ==="
                            test -f build/index.html && echo "✅ Build successful" || echo "❌ Build failed"
                        '''
                        
                        // Archive build artifacts
                        archiveArtifacts artifacts: 'build/**/*', fingerprint: true, allowEmptyArchive: false
                    }
                }
            }
        }
        
        stage('Test Suite') {
            parallel {
                stage('Unit Tests') {
                    agent {
                        docker {
                            image 'node:18-alpine'
                            args '-v ${WORKSPACE}:/workspace -w /workspace'
                            reuseNode true
                        }
                    }
                    steps {
                        sh '''
                            echo "=== Running Unit Tests ==="
                            npm test -- --coverage --watchAll=false --testResultsProcessor=jest-junit
                            
                            echo "=== Test Results ==="
                            ls -la test-results/ || echo "No test results directory found"
                        '''
                    }
                    post {
                        always {
                            // Publish test results
                            publishTestResults testResultsPattern: 'test-results/junit.xml'
                            
                            // Publish coverage report
                            publishHTML([
                                allowMissing: false,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'coverage/lcov-report',
                                reportFiles: 'index.html',
                                reportName: 'Coverage Report'
                            ])
                        }
                    }
                }
                
                stage('Docker Container Test') {
                    steps {
                        script {
                            echo "Testing Docker container..."
                            
                            sh '''
                                # Start container in detached mode
                                docker run -d --name test-container-${BUILD_NUMBER} -p 8080:80 ${APP_IMAGE}:${BUILD_NUMBER_TAG}
                                
                                # Wait for container to be ready
                                sleep 10
                                
                                # Test if application is accessible
                                curl -f http://localhost:8080 || exit 1
                                echo "✅ Container test passed"
                                
                                # Stop and remove test container
                                docker stop test-container-${BUILD_NUMBER}
                                docker rm test-container-${BUILD_NUMBER}
                            '''
                        }
                    }
                }
                
                stage('E2E Tests') {
                    when {
                        anyOf {
                            branch 'main'
                            branch 'develop'
                            changeRequest()
                        }
                    }
                    steps {
                        script {
                            echo "Running E2E tests..."
                            
                            sh '''
                                # Start application container for E2E testing
                                docker run -d --name e2e-app-${BUILD_NUMBER} -p 3001:80 ${APP_IMAGE}:${BUILD_NUMBER_TAG}
                                
                                # Wait for application to be ready
                                sleep 15
                                
                                # Run E2E tests using docker-compose
                                export CI_ENVIRONMENT_URL=http://localhost:3001
                                export REACT_APP_VERSION=${BUILD_NUMBER}
                                
                                docker-compose -f docker-compose.yml run --rm e2e-tests
                                
                                # Cleanup
                                docker stop e2e-app-${BUILD_NUMBER}
                                docker rm e2e-app-${BUILD_NUMBER}
                            '''
                        }
                    }
                    post {
                        always {
                            // Publish E2E test results
                            publishHTML([
                                allowMissing: true,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'playwright-report',
                                reportFiles: 'index.html',
                                reportName: 'E2E Test Report'
                            ])
                        }
                    }
                }
            }
        }
        
        stage('Security & Quality') {
            parallel {
                stage('Security Scan') {
                    steps {
                        script {
                            echo "Running security scans..."
                            
                            sh '''
                                # Audit npm packages
                                docker run --rm -v ${WORKSPACE}:/workspace -w /workspace node:18-alpine npm audit --audit-level moderate
                                
                                # Docker image security scan (if trivy is available)
                                if command -v trivy &> /dev/null; then
                                    trivy image ${APP_IMAGE}:${BUILD_NUMBER_TAG}
                                else
                                    echo "Trivy not available, skipping image scan"
                                fi
                            '''
                        }
                    }
                }
                
                stage('Quality Check') {
                    agent {
                        docker {
                            image 'node:18-alpine'
                            args '-v ${WORKSPACE}:/workspace -w /workspace'
                            reuseNode true
                        }
                    }
                    steps {
                        sh '''
                            echo "=== Code Quality Checks ==="
                            
                            # Check for linting issues
                            npm run build 2>&1 | grep -i "warning\|error" || echo "No build warnings/errors found"
                            
                            # Check bundle size (basic check)
                            BUILD_SIZE=$(du -sh build/ | cut -f1)
                            echo "Build size: $BUILD_SIZE"
                            
                            # Check for source maps
                            find build/static/js -name "*.map" | wc -l | xargs echo "Source maps found:"
                        '''
                    }
                }
            }
        }
        
        stage('Package & Archive') {
            steps {
                script {
                    echo "Creating deployment packages..."
                    
                    sh '''
                        # Create build archive
                        tar -czf build-${BUILD_NUMBER}.tar.gz build/
                        
                        # Save Docker image
                        docker save ${APP_IMAGE}:${BUILD_NUMBER_TAG} | gzip > ${APP_IMAGE}-${BUILD_NUMBER}.tar.gz
                        
                        # Create deployment manifest
                        cat > deployment-manifest.json << EOF
{
  "buildNumber": "${BUILD_NUMBER}",
  "buildUrl": "${BUILD_URL}",
  "gitCommit": "${GIT_COMMIT}",
  "gitBranch": "${GIT_BRANCH}",
  "buildTimestamp": "$(date -Iseconds)",
  "dockerImage": "${APP_IMAGE}:${BUILD_NUMBER_TAG}",
  "appVersion": "${REACT_APP_VERSION}"
}
EOF
                        
                        echo "=== Deployment Manifest ==="
                        cat deployment-manifest.json
                    '''
                    
                    // Archive all build artifacts
                    archiveArtifacts artifacts: '''
                        build-${BUILD_NUMBER}.tar.gz,
                        ${APP_IMAGE}-${BUILD_NUMBER}.tar.gz,
                        deployment-manifest.json
                    ''', fingerprint: true
                }
            }
        }
        
        stage('Deploy to Local') {
            when {
                anyOf {
                    branch 'main'
                    expression { params.DEPLOY_TO_LOCAL == true }
                }
            }
            steps {
                script {
                    echo "Deploying to local environment..."
                    
                    sh '''
                        # Stop existing containers
                        docker-compose down || true
                        
                        # Deploy using docker-compose
                        export REACT_APP_VERSION=${BUILD_NUMBER}
                        docker-compose up -d react-app-prod
                        
                        # Wait for deployment
                        sleep 10
                        
                        # Verify deployment
                        curl -f http://localhost:8080 && echo "✅ Local deployment successful"
                    '''
                }
            }
        }
    }
    
    post {
        always {
            script {
                echo "=== Build Summary ==="
                echo "Build Number: ${env.BUILD_NUMBER}"
                echo "Build Status: ${currentBuild.currentResult}"
                echo "Build Duration: ${currentBuild.durationString}"
            }
            
            // Clean up Docker resources
            sh '''
                # Remove old images (keep last 5)
                docker images ${APP_IMAGE} --format "table {{.Repository}}:{{.Tag}}\\t{{.CreatedAt}}" | tail -n +6 | awk '{print $1}' | xargs -r docker rmi || true
                
                # Clean up dangling images
                docker image prune -f || true
                
                # Clean up unused containers
                docker container prune -f || true
            '''
        }
        
        success {
            echo "✅ Build completed successfully!"
            
            // Send success notification (if configured)
            // slackSend channel: '#builds', color: 'good', message: "✅ Build #${env.BUILD_NUMBER} succeeded"
        }
        
        failure {
            echo "❌ Build failed!"
            
            // Send failure notification (if configured)
            // slackSend channel: '#builds', color: 'danger', message: "❌ Build #${env.BUILD_NUMBER} failed"
        }
        
        unstable {
            echo "⚠️ Build is unstable"
        }
        
        cleanup {
            // Clean workspace after build
            cleanWs()
        }
    }
}
