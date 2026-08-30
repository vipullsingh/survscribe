# SurvScribe Android App Launcher Script
$ErrorActionPreference = "Continue"

$ProjectRoot = Resolve-Path "$PSScriptRoot/.."

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   SurvScribe Android App Launcher              " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

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

# 2. Build and Launch React Native App on Android
Write-Host "`n[2/3] Building and launching React Native app on Android..." -ForegroundColor Yellow
Push-Location "$ProjectRoot/apps/mobile"
try {
    npx react-native run-android
} finally {
    Pop-Location
}
