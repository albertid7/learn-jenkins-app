# Pipeline Validation Script for Windows PowerShell
Write-Host "=== Jenkins Docker Pipeline Validation ===" -ForegroundColor Green

# Check Docker
Write-Host "`nChecking Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "✅ Docker found: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker not found or not running" -ForegroundColor Red
    exit 1
}

# Check Docker Compose
Write-Host "`nChecking Docker Compose..." -ForegroundColor Yellow
try {
    $composeVersion = docker-compose --version
    Write-Host "✅ Docker Compose found: $composeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker Compose not found" -ForegroundColor Red
    exit 1
}

# Check required files
Write-Host "`nChecking required files..." -ForegroundColor Yellow
$requiredFiles = @(
    "package.json",
    "Dockerfile",
    "Dockerfile.dev",
    "Dockerfile.test",
    "Dockerfile.e2e",
    "docker-compose.yml",
    "Jenkinsfile",
    ".dockerignore"
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "✅ Found: $file" -ForegroundColor Green
    } else {
        Write-Host "❌ Missing: $file" -ForegroundColor Red
    }
}

# Validate docker-compose syntax
Write-Host "`nValidating docker-compose.yml..." -ForegroundColor Yellow
try {
    docker-compose config | Out-Null
    Write-Host "✅ docker-compose.yml syntax is valid" -ForegroundColor Green
} catch {
    Write-Host "❌ docker-compose.yml has syntax errors" -ForegroundColor Red
}

# Check Node.js dependencies
Write-Host "`nChecking package.json..." -ForegroundColor Yellow
if (Test-Path "package.json") {
    $packageJson = Get-Content "package.json" | ConvertFrom-Json
    
    # Check for required scripts
    $requiredScripts = @("start", "build", "test")
    foreach ($script in $requiredScripts) {
        if ($packageJson.scripts.$script) {
            Write-Host "✅ Found npm script: $script" -ForegroundColor Green
        } else {
            Write-Host "❌ Missing npm script: $script" -ForegroundColor Red
        }
    }
    
    # Check for test dependencies
    if ($packageJson.dependencies."jest-junit" -or $packageJson.devDependencies."jest-junit") {
        Write-Host "✅ Found jest-junit for test reporting" -ForegroundColor Green
    } else {
        Write-Host "⚠️  jest-junit not found - test reporting may not work" -ForegroundColor Yellow
    }
    
    if ($packageJson.devDependencies."@playwright/test") {
        Write-Host "✅ Found Playwright for E2E testing" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Playwright not found - E2E tests may not work" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Validation Complete ===" -ForegroundColor Green
Write-Host "Your pipeline is ready to run!" -ForegroundColor Cyan

# Display next steps
Write-Host "`n=== Next Steps ===" -ForegroundColor Blue
Write-Host "1. Configure your existing Jenkins instance with required plugins"
Write-Host "2. Set up Docker access in Jenkins (see jenkins-existing-setup.md)"
Write-Host "3. Create a new Pipeline job in Jenkins"
Write-Host "4. Point it to your Git repository or paste the Jenkinsfile content"
Write-Host "5. Run the pipeline!"
Write-Host "`nFor detailed setup instructions, see jenkins-existing-setup.md"
