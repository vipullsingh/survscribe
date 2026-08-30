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

# 1. Check Android Studio shortcut & installations
$shortcutPath = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Android Studio\Android Studio.lnk"
$studioExePaths = @(
    "C:\Program Files\Android\Android Studio1\bin\studio64.exe",
    "C:\Program Files\Android\Android Studio\bin\studio64.exe",
    "$env:LOCALAPPDATA\Programs\Android Studio\bin\studio64.exe"
)
$studioExe = $studioExePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

function Launch-StudioGUI {
    param([string]$Shortcut, [string]$ExePath, [string]$ProjectPath)
    
    # Kill any hung background process first
    $bgProc = Get-Process studio64 -ErrorAction SilentlyContinue
    if ($bgProc -and $bgProc.MainWindowHandle -eq [IntPtr]::Zero) {
        Write-Host "Clearing background process..." -ForegroundColor Gray
        Stop-Process -Id $bgProc.Id -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }

    if (Test-Path $Shortcut) {
        Write-Host "Launching Android Studio via Start Shortcut..." -ForegroundColor Green
        explorer.exe "$Shortcut"
    } elseif ($ExePath) {
        $binDir = Split-Path -Path $ExePath -Parent
        Write-Host "Starting Android Studio ($ExePath)..." -ForegroundColor Green
        Start-Process -FilePath $ExePath -ArgumentList "`"$ProjectPath`"" -WorkingDirectory $binDir
    } else {
        Write-Host "Warning: Android Studio path not found." -ForegroundColor Yellow
    }
}

if ($OpenStudio -or $Studio) {
    Write-Host "`n[1/1] Launching Android Studio GUI..." -ForegroundColor Yellow
    Launch-StudioGUI -Shortcut $shortcutPath -ExePath $studioExe -ProjectPath $AndroidProjectPath
    Exit 0
}

# 2. Check ADB and Active Android Devices/Emulators
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
    Write-Host "Warning: 'adb' command not found in PATH." -ForegroundColor Yellow
}

# 3. Launch Android Studio GUI
Launch-StudioGUI -Shortcut $shortcutPath -ExePath $studioExe -ProjectPath $AndroidProjectPath

# 4. Build and Launch React Native App on Android
Write-Host "`n[3/3] Building and launching React Native app on Android..." -ForegroundColor Yellow
Push-Location "$ProjectRoot/apps/mobile"
try {
    npx react-native run-android
} finally {
    Pop-Location
}
