$output = "`n===== [Manual Test] =====`nТова е ръчно добавен текст.`n"

Write-Host "DEBUG OUTPUT:"
Write-Host $output

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
