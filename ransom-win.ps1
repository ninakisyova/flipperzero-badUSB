$logFile = "$env:TEMP\wallpaper-test-log.txt"
$wallpaperUrl = "https://raw.githubusercontent.com/ninakisyova/flipperzero-badUSB/main/hacked-wallpaper.png"
$localPath = "$env:TEMP\wallpaper-test.png"

Add-Content $logFile "`n== Starting wallpaper test: $(Get-Date) =="

try {
    Invoke-WebRequest -Uri $wallpaperUrl -OutFile $localPath
    Add-Content $logFile "SUCCESS: Wallpaper downloaded to $localPath"
} catch {
    Add-Content $logFile "FAIL: Wallpaper download failed — $_"
}
