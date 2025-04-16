#!/bin/bash

echo "[+] Installing go-bridge..."

# دانلود باینری از GitHub شما (لینک نمونه که بعداً باید تغییر کنه)
curl -L -o /usr/local/bin/go-bridge https://raw.githubusercontent.com/YOUR_USERNAME/go-android-bridge/main/go-bridge
chmod +x /usr/local/bin/go-bridge

# ساخت مسیر لاگ
mkdir -p /var/log/go-bridge

# کپی سرویس systemd
curl -L -o /etc/systemd/system/go-bridge.service https://raw.githubusercontent.com/YOUR_USERNAME/go-android-bridge/main/go-bridge.service

# فعال‌سازی سرویس
systemctl daemon-reload
systemctl enable go-bridge
systemctl start go-bridge

echo "[✓] go-bridge is installed and running on port 8081"