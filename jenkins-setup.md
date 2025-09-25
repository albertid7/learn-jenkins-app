# Jenkins Docker Setup Guide

This guide will help you set up Jenkins to build your React app using Docker locally.

## Prerequisites

- Docker and Docker Compose installed
- Jenkins running locally or access to a Jenkins instance
- Git repository with your React app

## Quick Start

### 1. Use Your Existing Jenkins Instance

Since you already have Jenkins running in Docker Desktop:
- Access your existing Jenkins instance (typically at `http://localhost:8080`)
- For detailed configuration steps, see `jenkins-existing-setup.md`

### 2. Configure Jenkins

1. Install required plugins:
   - Docker Pipeline
   - HTML Publisher
   - JUnit
   - Pipeline: Stage View

2. Configure Docker:
   - Go to "Manage Jenkins" > "Configure System"
   - Add Docker Host (if needed)

### 3. Create Pipeline Job

1. Create a new Pipeline job
2. Configure SCM (Git) or paste the Jenkinsfile content
3. Run the build

## Available Services

### Development Server
```bash
# Start development server
docker-compose up react-app-dev

# Access at http://localhost:3000
```

### Production Build
```bash
# Build and run production version
docker-compose up react-app-prod

# Access at http://localhost:8080
```

### Run Tests
```bash
# Unit tests
docker-compose run --rm test-runner

# E2E tests (requires app to be running)
docker-compose up -d react-app-prod
docker-compose run --rm e2e-tests
```

## Pipeline Features

### Parallel Execution
- Docker image building
- Asset compilation
- Unit tests
- Security scans

### Testing
- Unit tests with coverage
- E2E tests with Playwright
- Docker container testing

### Quality & Security
- NPM audit
- Docker image scanning (if Trivy available)
- Build quality checks

### Artifacts
- Build archives
- Docker images
- Test reports
- Coverage reports

## Environment Variables

- `REACT_APP_VERSION`: App version (defaults to build number)
- `DEPLOY_TO_LOCAL`: Force deployment to local environment

## Troubleshooting

### Docker Permission Issues
```bash
# Add jenkins user to docker group (Linux)
sudo usermod -aG docker jenkins

# Or run Jenkins as root (not recommended for production)
```

### Port Conflicts
- Jenkins: 8081
- Dev App: 3000
- Prod App: 8080
- E2E Test App: 3001

### Build Failures
- Check Docker daemon is running
- Verify all Dockerfiles are present
- Check available disk space
- Review Jenkins logs

## Customization

### Adding New Stages
Edit the Jenkinsfile to add custom stages:

```groovy
stage('Custom Stage') {
    steps {
        sh 'your-custom-command'
    }
}
```

### Notifications
Uncomment and configure Slack notifications in the Jenkinsfile post sections.

### Registry Push
Uncomment Docker registry push commands for remote deployment.
