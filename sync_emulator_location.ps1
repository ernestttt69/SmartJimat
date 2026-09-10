Add-Type -AssemblyName System.Runtime.WindowsRuntime

$null = [Windows.Devices.Geolocation.Geolocator, Windows.Devices.Geolocation, ContentType = WindowsRuntime]

# ============================================================
# Settings
# ============================================================

$adb = "C:\Users\tansh\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$emulator = "emulator-5554"
$updateSeconds = 10

# ============================================================
# WinRT async helper
# ============================================================

function Await-WinRTTask {
    param(
        $AsyncOperation,
        [Type]$ResultType
    )

    $asTaskMethod = [System.WindowsRuntimeSystemExtensions].GetMethods() |
        Where-Object {
            $_.Name -eq "AsTask" -and
            $_.IsGenericMethod -and
            $_.GetParameters().Count -eq 1
        } |
        Select-Object -First 1

    $genericMethod = $asTaskMethod.MakeGenericMethod($ResultType)

    $task = $genericMethod.Invoke(
        $null,
        @($AsyncOperation)
    )

    $task.Wait()

    return $task.Result
}

# ============================================================
# Header
# ============================================================

Write-Host ""
Write-Host "============================================"
Write-Host " SmartJimat Emulator Location Sync"
Write-Host " Windows Location -> Android Emulator"
Write-Host "============================================"
Write-Host ""

# ============================================================
# Check ADB path
# ============================================================

if (-not (Test-Path $adb)) {
    Write-Host "ERROR: adb.exe not found:"
    Write-Host $adb
    exit
}

Write-Host "ADB found."
Write-Host ""

# ============================================================
# Check emulator connection
# ============================================================

$deviceLines = & $adb devices

$emulatorFound = $false

foreach ($line in $deviceLines) {
    if ($line -match "^$([regex]::Escape($emulator))\s+device$") {
        $emulatorFound = $true
        break
    }
}

if (-not $emulatorFound) {

    Write-Host "ERROR: Emulator not found."
    Write-Host ""
    Write-Host "Expected:"
    Write-Host "$emulator    device"
    Write-Host ""
    Write-Host "Current devices:"

    foreach ($line in $deviceLines) {
        Write-Host $line
    }

    exit
}

Write-Host "Emulator connected: $emulator"
Write-Host ""

# ============================================================
# Create Windows Geolocator
# ============================================================

Write-Host "Getting Windows location..."
Write-Host ""

$locator = New-Object Windows.Devices.Geolocation.Geolocator

$locator.DesiredAccuracyInMeters = 10

# ============================================================
# Sync loop
# ============================================================

while ($true) {

    try {

        $operation = $locator.GetGeopositionAsync()

        $position = Await-WinRTTask `
            -AsyncOperation $operation `
            -ResultType ([Windows.Devices.Geolocation.Geoposition])

        $latitude =
            $position.Coordinate.Point.Position.Latitude

        $longitude =
            $position.Coordinate.Point.Position.Longitude

        $accuracy =
            $position.Coordinate.Accuracy

        Write-Host "--------------------------------------------"
        Write-Host "Windows Location"
        Write-Host "Latitude : $latitude"
        Write-Host "Longitude: $longitude"
        Write-Host "Accuracy : $accuracy meters"
        Write-Host ""

        # Android Emulator syntax:
        # geo fix LONGITUDE LATITUDE

        $adbResult = & $adb `
            -s $emulator `
            emu geo fix `
            $longitude `
            $latitude 2>&1

        foreach ($line in $adbResult) {
            Write-Host $line
        }

        if ($LASTEXITCODE -eq 0) {

            Write-Host ""
            Write-Host "SUCCESS"
            Write-Host "Location sent to $emulator"
            Write-Host ""
            Write-Host "Sent coordinates:"
            Write-Host "Latitude : $latitude"
            Write-Host "Longitude: $longitude"

        }
        else {

            Write-Host ""
            Write-Host "ERROR"
            Write-Host "Failed to send location to emulator."

        }

        Write-Host ""
        Write-Host "Next update in $updateSeconds seconds..."
        Write-Host ""

    }
    catch {

        Write-Host "--------------------------------------------"
        Write-Host "LOCATION ERROR"
        Write-Host $_.Exception.Message
        Write-Host ""
        Write-Host "Retrying in $updateSeconds seconds..."
        Write-Host ""

    }

    Start-Sleep -Seconds $updateSeconds
}