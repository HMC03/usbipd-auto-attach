$Blacklist = "bluetooth|webcam|camera|fingerprint|goodix|audio|speaker|headset|intel.*wireless|realtek|hid|mouse|keyboard|touchpad|hub|root hub|card reader|sd card|smart card|receiver|dongle|usbip shared device"

$logFile = "C:\Users\hayde\Services\usbipd-auto-attach.log"
$maxSize = 20KB

# Start the initial transcript
Start-Transcript -Path $logFile

function Show-List {
    Write-Host "`n=== usbipd list ===" -ForegroundColor Cyan
    usbipd list
    Write-Host "===============================`n" -ForegroundColor Cyan
}

Write-Host "`nStarting USB auto-attach service" -ForegroundColor Green
Write-Host "Unbinding all devices for clean start..." -ForegroundColor Yellow
usbipd unbind --all 2>$null
Start-Sleep -Seconds 3
Show-List

while ($true) {
    # --- Log rotation ---
    if (Test-Path $logFile) {
        $size = (Get-Item $logFile).Length
        if ($size -gt $maxSize) {
            Stop-Transcript
            Remove-Item $logFile -Force
            Start-Transcript -Path $logFile
        }
    }

    $list = usbipd list
    $goodDevices = @()

    # Build list of only good devices
    foreach ($line in $list) {
        if ($line -match '^[0-9]+-[0-9]+') {
	    $parts = $line.Trim() -split '\s+'
	    $busid = $parts[0]
            $vidpid = $parts[1]

	    # --- Detect "Not shared" ---
            if ($parts[-2] + " " + $parts[-1] -match "Not shared") {
                $state = "Not shared"
                $name = ($parts[2..($parts.Length - 3)] -join ' ').Trim()
            } else {
                $state = $parts[-1]
                $name = ($parts[2..($parts.Length - 2)] -join ' ').Trim()
            }

            if ($name -notmatch $Blacklist -and $state -notmatch "Attached") {
                $goodDevices += [PSCustomObject]@{ BusId=$busid; Name=$name; State=$state }
            }
        }
    }

    if ($goodDevices.Count -eq 0) {
        Write-Host "[$(Get-Date -Format HH:mm:ss)] No serial devices to attach..." -ForegroundColor Gray
        Start-Sleep -Seconds 10
        continue
    }

    Write-Host "[$(Get-Date -Format HH:mm:ss)] Found $($goodDevices.Count) serial device(s):" -ForegroundColor Green
    foreach ($dev in $goodDevices) { Write-Host "  $($dev.BusId) $($dev.Name) $($dev.State)" }
    Write-Host "`n"

    # CRITICAL: Bind first, then attach — exactly like your manual command
    foreach ($dev in $goodDevices) {
	# Bind
	if ($dev.State -match "Not shared") {
            Write-Host "  Binding $($dev.BusId)"
            usbipd bind --busid $dev.BusId 2>$null
        }

        # Then Attach
        if ($dev.State -match "Shared") {
            Write-Host "  Attaching $($dev.BusId)"
            usbipd attach  --wsl "Ubuntu-24.04" --busid $dev.BusId 2>$null
        }
    }

    Start-Sleep -Seconds 2
    Show-List
    Write-Host "[$(Get-Date -Format HH:mm:ss)] All devices bound + attached — sleeping 20s`n" -ForegroundColor Green
    Start-Sleep -Seconds 20
}
