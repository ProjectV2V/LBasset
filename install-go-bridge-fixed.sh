#!/bin/bash

echo "[+] Installing Go HTTP-to-SOCKS5 Bridge..."

# نصب Go اگر نبود
if ! command -v go &> /dev/null; then
  apt update
  apt install -y golang
fi

# دانلود سورس از GitHub کاربر
curl -sLo /usr/local/bin/go-bridge-final.go https://raw.githubusercontent.com/projectv2/LBasset/main/go-bridge/go-bridge-final.go

# ساخت فایل اجرایی
cd /usr/local/bin/
go build -o go-bridge go-bridge-final.go
chmod +x /usr/local/bin/go-bridge

# ساخت فایل systemd
cat <<EOF > /etc/systemd/system/go-bridge.service
[Unit]
Description=Go HTTP-to-SOCKS5 Bridge
After=network.target

[Service]
ExecStart=/usr/local/bin/go-bridge
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# اجرای سرویس
systemctl daemon-reexec
systemctl enable go-bridge
systemctl restart go-bridge

echo "[✓] go-bridge is installed and running on port 8081"
