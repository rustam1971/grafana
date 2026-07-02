#!/bin/bash
# 
# Usage: wget -qO /tmp/install.sh https://raw.githubusercontent.com/rustam1971/grafana/grafana bash

apt update && apt install -y apt-transport-https software-properties-common wget
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | tee /usr/share/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list
apt update
apt install -y grafana
systemctl enable --now grafana-server

echo "default user: admin/admin"
