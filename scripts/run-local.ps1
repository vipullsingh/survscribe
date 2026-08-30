# SurvScribe One-Click Local Development Launcher
$ErrorActionPreference = "Continue"

$ProjectRoot = Resolve-Path "$PSScriptRoot/.."

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   SurvScribe Local Development Environment     " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# 1. Start Postgres Docker Container if Docker is installed
Write-Host "`n[1/4] Checking Docker & PostgreSQL..." -ForegroundColor Yellow
$dockerCmd = Get-Command "docker" -ErrorAction SilentlyContinue
$dockerStarted = $false

if ($dockerCmd) {
    try {
        docker compose -f "$ProjectRoot/apps/backend/deployments/docker-compose.yml" up -d 2>$null
        if ($LASTEXITCODE -eq 0) {
            $dockerStarted = $true
            Write-Host "PostgreSQL container is running on port 5433." -ForegroundColor Green
        } else {
            Write-Host "Warning: Docker is installed but daemon is not running (Start Docker Desktop)." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Warning: Could not start Docker container." -ForegroundColor Yellow
    }
} else {
    Write-Host "Note: Docker is not installed in PATH. Skipping PostgreSQL container." -ForegroundColor Yellow
}

# 2. Set Environment Variables
$env:DATABASE_URL = "postgres://survscribe:devpassword@localhost:5433/survscribe_dev?sslmode=disable"
$env:SURVSCRIBE_ENV = "development"
$env:LOG_LEVEL = "debug"
$env:HTTP_ADDR = ":8080"

# 3. Apply Migrations inside Postgres Container if running
Write-Host "`n[2/4] Checking Database & Migrations..." -ForegroundColor Yellow
if ($dockerStarted) {
    Write-Host "Waiting for database readiness..." -ForegroundColor Gray
    Start-Sleep -Seconds 3
    Get-ChildItem -Path "$ProjectRoot/apps/backend/migrations" -Filter "*.up.sql" | Sort-Object Name | ForEach-Object {
        Write-Host "  Applying $($_.Name)..." -ForegroundColor Gray
        Get-Content $_.FullName | docker exec -i survscribe-postgres-dev psql -U survscribe -d survscribe_dev -q -v ON_ERROR_STOP=1 2>$null
    }
    Write-Host "Database migrations verified/applied." -ForegroundColor Green
} else {
    Write-Host "Skipping auto-migrations (PostgreSQL container is not active)." -ForegroundColor Yellow
}

# 4. Start Backend API in background process
Write-Host "`n[3/4] Starting Go Backend API Server (http://localhost:8080)..." -ForegroundColor Yellow
$goCmd = Get-Command "go" -ErrorAction SilentlyContinue
if ($goCmd) {
    $backendProcess = Start-Process -FilePath "go" -ArgumentList "run", "./cmd/api" -WorkingDirectory "$ProjectRoot/apps/backend" -PassThru
    Write-Host "Backend process running (PID: $($backendProcess.Id))." -ForegroundColor Green
} else {
    Write-Host "Warning: 'go' is not installed or not in PATH." -ForegroundColor Red
}

# 5. Start Mobile Metro Bundler
Write-Host "`n[4/4] Starting Mobile React Native Metro Bundler..." -ForegroundColor Yellow
Push-Location "$ProjectRoot/apps/mobile"
try {
    npx react-native start
} finally {
    Pop-Location
}
