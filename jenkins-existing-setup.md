# Jenkins Setup for Existing Docker Desktop Instance

Since you already have Jenkins running in Docker Desktop, here's how to configure it to work with your React app pipeline.

## 🔧 Jenkins Configuration Steps

### 1. Access Your Jenkins Instance
- Open your existing Jenkins instance (typically at `http://localhost:8080` or check Docker Desktop)
- Log in with your admin credentials

### 2. Install Required Plugins
Go to **Manage Jenkins** → **Manage Plugins** → **Available** and install:

- ✅ **Docker Pipeline** - For Docker agent support
- ✅ **HTML Publisher** - For test reports and coverage
- ✅ **JUnit** - For test result publishing
- ✅ **Pipeline: Stage View** - Better pipeline visualization
- ✅ **Blue Ocean** (optional) - Modern UI for pipelines
- ✅ **Git** - For source code management

### 3. Configure Docker Access

#### Option A: Docker Socket Access (Recommended)
If your Jenkins container has Docker socket access:

1. Go to **Manage Jenkins** → **Configure System**
2. Scroll to **Docker** section
3. Add Docker Host: `unix:///var/run/docker.sock`
4. Test the connection

#### Option B: Docker-in-Docker
If you need Docker-in-Docker setup, ensure your Jenkins container runs with:
```bash
docker run -d --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --group-add $(getent group docker | cut -d: -f3) \
  jenkins/jenkins:lts
```

### 4. Create Pipeline Job

1. **New Item** → **Pipeline**
2. Name it: `learn-jenkins-app-build`
3. Configure the pipeline:

#### Pipeline Configuration
- **Definition**: Pipeline script from SCM
- **SCM**: Git
- **Repository URL**: Your Git repository URL
- **Branch**: `*/main` (or your default branch)
- **Script Path**: `Jenkinsfile`

OR

- **Definition**: Pipeline script
- Paste the contents of your `Jenkinsfile` directly

### 5. Environment Variables (Optional)
Go to **Configure** → **Build Environment**:
- ☑️ **Delete workspace before build starts** (recommended)
- Add environment variables if needed:
  - `REACT_APP_VERSION` = `${BUILD_NUMBER}`
  - `DOCKER_REGISTRY` = `your-registry` (if using external registry)

### 6. Build Triggers (Optional)
- ☑️ **Poll SCM**: `H/5 * * * *` (check every 5 minutes)
- ☑️ **GitHub hook trigger** (if using GitHub)

## 🚀 Testing Your Setup

### Quick Test Commands
Run these in your Jenkins workspace to verify Docker access:

```bash
# Test Docker access
docker --version
docker ps

# Test Docker Compose
docker-compose --version

# Test Node.js image
docker run --rm node:18-alpine node --version
```

### Build Your App Locally First
Before running in Jenkins, test locally:

```bash
# Start development server
docker-compose up react-app-dev

# Build production version
docker-compose up --build react-app-prod

# Run tests
docker-compose run --rm test-runner
```

## 📊 Pipeline Features You'll Get

### Parallel Stages
- ✅ Docker image building
- ✅ Asset compilation  
- ✅ Unit tests with coverage
- ✅ Security scans

### Test Reports
- 📈 JUnit test results
- 📊 Coverage reports (HTML)
- 🎭 Playwright E2E reports
- 🔍 Build artifacts

### Quality Gates
- 🛡️ Security audits
- 📏 Bundle size checks
- 🧹 Code quality validation
- 🐳 Container health tests

## 🔍 Troubleshooting

### Common Issues

#### "Docker not found"
- Verify Docker socket is mounted: `-v /var/run/docker.sock:/var/run/docker.sock`
- Check Jenkins user permissions for Docker

#### "Permission denied" on Docker socket
```bash
# Fix Docker socket permissions (Linux/Mac)
sudo chmod 666 /var/run/docker.sock

# Or add Jenkins user to docker group
sudo usermod -aG docker jenkins
```

#### Port conflicts
- Jenkins: Usually 8080 (check your setup)
- React Dev: 3000
- React Prod: 8080 (may conflict with Jenkins)
- E2E Tests: 3001

To avoid conflicts, you can modify ports in `docker-compose.yml`:
```yaml
react-app-prod:
  ports:
    - "8090:80"  # Changed from 8080 to 8090
```

#### Windows Docker Desktop Issues
- Ensure "Expose daemon on tcp://localhost:2375 without TLS" is enabled
- Use `tcp://host.docker.internal:2375` as Docker Host URL

### Logs and Debugging
- Jenkins logs: **Manage Jenkins** → **System Log**
- Pipeline logs: Click on build number → **Console Output**
- Docker logs: `docker logs <container-name>`

## 🎯 Next Steps

1. ✅ Configure Jenkins with required plugins
2. ✅ Set up Docker access
3. ✅ Create your pipeline job
4. ✅ Run your first build
5. 📈 Monitor build results and reports

Your pipeline will automatically:
- Build Docker images
- Run all tests
- Generate reports
- Create deployment artifacts
- Clean up resources

Happy building! 🚀
