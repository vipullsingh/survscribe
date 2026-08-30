# SurvScribe Android App Launcher Script
param(
    [switch]$OpenStudio,
    [switch]$Studio
)

$ErrorActionPreference = "Continue"

$ProjectRoot = Resolve-Path "$PSScriptRoot/.."
$AndroidProjectPath = "$ProjectRoot/apps/mobile/android"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   SurvScribe Android App Launcher              " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Find Android Studio executable
$studioPaths = @(
    "C:\Program Files\Android\Android Studio\bin\studio64.exe",
    "C:\Program Files\Android\Studio\bin\studio64.exe",
    "$env:LOCALAPPDATA\Programs\Android Studio\bin\studio64.exe"
)
$studioExe = $studioPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($OpenStudio -or $Studio) {
    Write-Host "`n[1/1] Launching Android Studio..." -ForegroundColor Yellow
    if ($studioExe) {
        Write-Host "Opening Android project in Android Studio ($AndroidProjectPath)..." -ForegroundColor Green
        Start-Process -FilePath $studioExe -ArgumentList "`"$AndroidProjectPath`""
        Exit 0
    } else {
        Write-Host "Error: Android Studio executable not found in standard paths." -ForegroundColor Red
        Exit 1
    }
}

# 1. Check ADB and Active Android Devices/Emulators
Write-Host "`n[1/3] Checking Android Devices & Emulators..." -ForegroundColor Yellow
$adbCmd = Get-Command "adb" -ErrorAction SilentlyContinue

if ($adbCmd) {
    $devices = & adb devices | Select-String -Pattern "\tdevice$"
    if ($devices) {
        Write-Host "Found active Android device / emulator." -ForegroundColor Green
    } else {
        Write-Host "No running Android device or emulator detected." -ForegroundColor Yellow
        
        # Check standard Android SDK location for emulator executable
        $sdkPath = "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe"
        if (Test-Path $sdkPath) {
            $avds = & $sdkPath -list-avds
            if ($avds) {
                $avdName = $avds[0]
                Write-Host "Launching Android Emulator ($avdName)..." -ForegroundColor Cyan
                Start-Process -FilePath $sdkPath -ArgumentList "-avd", $avdName
                Write-Host "Waiting 8 seconds for emulator initialization..." -ForegroundColor Gray
                Start-Sleep -Seconds 8
            } else {
                Write-Host "No Android Virtual Devices (AVDs) found. Create one in Android Studio." -ForegroundColor Yellow
            }
        } else {
            Write-Host "Please start an Android Emulator in Android Studio or plug in a USB device." -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "Warning: 'adb' command not found in PATH. Ensure Android SDK platform-tools is installed." -ForegroundColor Yellow
}

# 2. Open Android Studio automatically if present & launch build
if ($studioExe) {
    Write-Host "`nOpening project in Android Studio ($studioExe)..." -ForegroundColor Gray
    Start-Process -FilePath $studioExe -ArgumentList "`"$AndroidProjectPath`""
}

# 3. Build and Launch React Native App on Android
Write-Host "`n[3/3] Building and launching React Native app on Android..." -ForegroundColor Yellow
Push-Location "$ProjectRoot/apps/mobile"
try {
    npx react-native run-android
} finally {
    Pop-Location
}
