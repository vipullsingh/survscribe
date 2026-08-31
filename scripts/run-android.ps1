# SurvScribe Android App Launcher Script (bare React Native)
#
# Default:        boot an emulator if needed, then `npx react-native run-android`.
# -OpenStudio :   open the committed apps/mobile/android project in Android Studio.
#                 There is no prebuild step: the native project is source, not output.
param(
    [switch]$OpenStudio,
    [switch]$Studio
)

$ErrorActionPreference = "Continue"

$ProjectRoot = Resolve-Path "$PSScriptRoot/.."
$MobileAppPath = "$ProjectRoot/apps/mobile"
$AndroidProjectPath = "$MobileAppPath/android"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   SurvScribe Android App Launcher                " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# 0. Node version gate. React Native 0.87.1 requires Node ^22.13.0 || ^24.3.0 || >=26;
#    anything older fails deep inside Metro or Gradle, so check here and say so plainly.
$nodeCmd = Get-Command "node" -ErrorAction SilentlyContinue
if (-not $nodeCmd) {
    Write-Host "Error: 'node' is not installed or not in PATH." -ForegroundColor Red
    Exit 1
}
$nodeRaw = (& node --version).TrimStart("v")
$nodeVer = [Version]$nodeRaw
if ($nodeVer -lt [Version]"22.13.0") {
    Write-Host "Error: Node $nodeRaw detected. React Native 0.87.1 needs Node >= 22.13.0." -ForegroundColor Red
    Write-Host "Install Node 22.13+ or 24 LTS, then re-run this script." -ForegroundColor Yellow
    Exit 1
}
Write-Host "Node $nodeRaw OK." -ForegroundColor Green

# 1. Locate Android Studio (only needed for -OpenStudio)
$shortcutPath = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Android Studio\Android Studio.lnk"
$studioExePaths = @(
    "C:\Program Files\Android\Android Studio1\bin\studio64.exe",
    "C:\Program Files\Android\Android Studio\bin\studio64.exe",
    "$env:LOCALAPPDATA\Programs\Android Studio\bin\studio64.exe"
)
$studioExe = $studioExePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

function Launch-StudioGUI {
    param([string]$Shortcut, [string]$ExePath, [string]$ProjectPath)

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
    if (-not (Test-Path $AndroidProjectPath)) {
        Write-Host "Error: $AndroidProjectPath does not exist." -ForegroundColor Red
        Exit 1
    }
    Write-Host "`nOpening apps/mobile/android in Android Studio..." -ForegroundColor Yellow
    Launch-StudioGUI -Shortcut $shortcutPath -ExePath $studioExe -ProjectPath $AndroidProjectPath
    Exit 0
}

# 2. Check ADB and active Android devices / emulators
Write-Host "`n[1/2] Checking Android Devices & Emulators..." -ForegroundColor Yellow
$adbCmd = Get-Command "adb" -ErrorAction SilentlyContinue

if ($adbCmd) {
    $devices = & adb devices | Select-String -Pattern "\tdevice$"
    if ($devices) {
        Write-Host "Found active Android device / emulator." -ForegroundColor Green
    } else {
        Write-Host "No running Android device or emulator detected." -ForegroundColor Yellow

        $sdkPath = "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe"
        if (Test-Path $sdkPath) {
            $avds = & $sdkPath -list-avds
            if ($avds) {
                $avdName = $avds[0]
                Write-Host "Launching Android Emulator ($avdName)..." -ForegroundColor Cyan
                Start-Process -FilePath $sdkPath -ArgumentList "-avd", $avdName
                Write-Host "Waiting for emulator to complete boot..." -ForegroundColor Gray
                $bootTimeout = 30
                while ($bootTimeout -gt 0) {
                    $onlineDev = & adb devices | Select-String -Pattern "\tdevice$"
                    if ($onlineDev) {
                        Write-Host "Android emulator is online and ready." -ForegroundColor Green
                        break
                    }
                    Start-Sleep -Seconds 3
                    $bootTimeout -= 3
                }
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

# 3. Build and launch the app on Android
Write-Host "`n[2/2] Building and launching on Android (react-native run-android)..." -ForegroundColor Yellow
Push-Location $MobileAppPath
try {
    npx react-native run-android
} finally {
    Pop-Location
}
