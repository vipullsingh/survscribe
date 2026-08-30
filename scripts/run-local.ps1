# SurvScribe Local Development Launcher (Backend API + Expo Dev Server)
$ErrorActionPreference = "Continue"

$ProjectRoot = Resolve-Path "$PSScriptRoot/.."
$BackendDir = "$ProjectRoot/apps/backend"
$MobileDir = "$ProjectRoot/apps/mobile"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   SurvScribe Local Development Environment     " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# 1. Detect & Check PostgreSQL (Local Service or Docker)
Write-Host "`n[1/3] Checking PostgreSQL Database..." -ForegroundColor Yellow
$pgPort = 0
$dbUrl = ""

# Check standard local port 5432 first
$test5432 = Test-NetConnection -ComputerName 127.0.0.1 -Port 5432 -WarningAction SilentlyContinue
if ($test5432.TcpTestSucceeded) {
    $pgPort = 5432
    $dbUrl = "postgres://survscribe:devpassword@localhost:5432/survscribe_dev?sslmode=disable"
    Write-Host "Local PostgreSQL is active on port 5432." -ForegroundColor Green
} else {
    # Check Docker compose port 5433
    $test5433 = Test-NetConnection -ComputerName 127.0.0.1 -Port 5433 -WarningAction SilentlyContinue
    if ($test5433.TcpTestSucceeded) {
        $pgPort = 5433
        $dbUrl = "postgres://survscribe:devpassword@localhost:5433/survscribe_dev?sslmode=disable"
        Write-Host "Docker PostgreSQL is active on port 5433." -ForegroundColor Green
    } else {
        # Try starting Docker if installed
        $dockerCmd = Get-Command "docker" -ErrorAction SilentlyContinue
        if ($dockerCmd) {
            Write-Host "Starting Docker PostgreSQL container..." -ForegroundColor Gray
            docker compose -f "$BackendDir/deployments/docker-compose.yml" up -d 2>$null
            Start-Sleep -Seconds 2
            $test5433 = Test-NetConnection -ComputerName 127.0.0.1 -Port 5433 -WarningAction SilentlyContinue
            if ($test5433.TcpTestSucceeded) {
                $pgPort = 5433
                $dbUrl = "postgres://survscribe:devpassword@localhost:5433/survscribe_dev?sslmode=disable"
                Write-Host "PostgreSQL container started on port 5433." -ForegroundColor Green
            }
        }
    }
}

if (-not $dbUrl) {
    $dbUrl = "postgres://survscribe:devpassword@localhost:5432/survscribe_dev?sslmode=disable"
    Write-Host "Note: PostgreSQL is not responding on 5432/5433. Backend will run in offline standalone mode." -ForegroundColor Yellow
}

# 2. Start Go Backend API Server
Write-Host "`n[2/3] Starting Go Backend API Server (http://localhost:8080)..." -ForegroundColor Yellow
$backendRunning = $false
try {
    $health = curl.exe -s --max-time 1 http://localhost:8080/healthz 2>$null
    if ($health -match '"success":true') {
        $backendRunning = $true
        Write-Host "Backend API is already running on http://localhost:8080." -ForegroundColor Green
    }
} catch {}

if (-not $backendRunning) {
    $goCmd = Get-Command "go" -ErrorAction SilentlyContinue
    if ($goCmd) {
        $env:DATABASE_URL = $dbUrl
        $env:SURVSCRIBE_ENV = "development"
        $env:LOG_LEVEL = "debug"
        $env:LOG_FORMAT = "text"
        $env:HTTP_ADDR = ":8080"
        
        $backendProcess = Start-Process -FilePath "go" -ArgumentList "run", "./cmd/api" -WorkingDirectory $BackendDir -PassThru
        Write-Host "Backend process started (PID: $($backendProcess.Id)) on http://localhost:8080" -ForegroundColor Green
        Start-Sleep -Seconds 2
    } else {
        Write-Host "Warning: 'go' is not installed or not in PATH." -ForegroundColor Red
    }
}

# 3. Start Expo Dev Server with QR Code
Write-Host "`n[3/3] Starting Mobile Expo Dev Server..." -ForegroundColor Yellow
Push-Location $MobileDir
try {
    npx expo start
} finally {
    Pop-Location
}
