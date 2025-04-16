#!/bin/bash

echo "[+] Installing Go HTTP-to-SOCKS5 Bridge..."

INSTALL_DIR="/usr/local/bin"
SERVICE_FILE="/etc/systemd/system/go-bridge.service"
BINARY="$INSTALL_DIR/go-bridge"
RAW_GO_URL="https://raw.githubusercontent.com/ProjectV2V/LBasset/main/go-bridge-final.go"

# Save the Go code
curl -sL "$RAW_GO_URL" -o /tmp/go-bridge.go

# Compile
go build -o "$BINARY" /tmp/go-bridge.go
chmod +x "$BINARY"

# Create service
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

# Reload systemd and start the service
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable go-bridge
systemctl restart go-bridge

echo "[✓] go-bridge is installed and running on port 8081"
