#!/bin/bash

echo "[!] Uninstalling go-bridge..."

systemctl stop go-bridge
systemctl disable go-bridge
rm -f /usr/local/bin/go-bridge
rm -f /etc/systemd/system/go-bridge.service
rm -rf /var/log/go-bridge
systemctl daemon-reload

echo "[✓] go-bridge uninstalled successfully."