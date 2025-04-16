#!/bin/bash

echo "[+] Installing Go HTTP-to-SOCKS5 Bridge..."

INSTALL_DIR="/usr/local/bin"
SERVICE_FILE="/etc/systemd/system/go-bridge.service"
BINARY="$INSTALL_DIR/go-bridge"
RAW_GO_URL="https://raw.githubusercontent.com/ProjectV2V/LBasset/main/go-bridge-final.go"

# دانلود فایل Go
curl -sL "$RAW_GO_URL" -o /tmp/go-bridge.go

# ساختن محیط کاری و تنظیم ماژول Go
mkdir -p /tmp/gobridge
cp /tmp/go-bridge.go /tmp/gobridge/main.go
cd /tmp/gobridge
go mod init gobridge
go get golang.org/x/net/proxy

# کامپایل برنامه
go build -o "$BINARY" main.go
chmod +x "$BINARY"

# ساخت فایل سرویس systemd
cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Go HTTP-to-SOCKS5 Bridge
After=network.target

[Service]
ExecStart=$BINARY
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# راه‌اندازی سرویس
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable go-bridge
systemctl restart go-bridge

echo "[✓] go-bridge is installed and running on port 8081"
