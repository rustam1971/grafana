#!/bin/bash
#===============================================================
# install-grafana.sh
# Install Grafana OSS (stable) untuk Ubuntu/Debian
#
# Interactive (ada konfirmasi jika Grafana sudah terinstall):
#   wget -qO- https://raw.githubusercontent.com/rustam1971/grafana-install/main/install-grafana.sh | bash
#
# Non-interactive (auto-yes, cocok untuk Ansible/automation):
#   wget -qO- https://raw.githubusercontent.com/rustam1971/grafana-install/main/install-grafana.sh | bash -s -- --force
#   atau:
#   FORCE=1 bash install-grafana.sh
#===============================================================
set -euo pipefail

# --- Parse argumen ---
FORCE="${FORCE:-0}"
for arg in "$@"; do
    case "$arg" in
        -f|--force|-y|--yes) FORCE=1 ;;
        -h|--help)
            echo "Usage: $0 [--force]"
            echo "  --force, -f, -y   Non-interactive, langsung install/upgrade tanpa konfirmasi"
            exit 0
            ;;
    esac
done

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- Cek root ---
[ "$(id -u)" -eq 0 ] || err "Script harus dijalankan sebagai root"

# --- Cek OS ---
command -v apt-get >/dev/null 2>&1 || err "Hanya support Ubuntu/Debian (apt)"

# --- Cek apakah Grafana sudah terinstall ---
if command -v grafana-server >/dev/null 2>&1; then
    warn "Grafana sudah terinstall: $(grafana-server -v 2>/dev/null | head -1)"
    if [ "$FORCE" = "1" ]; then
        log "Mode --force: lanjut upgrade/reinstall tanpa konfirmasi"
    elif [ -e /dev/tty ] && [ -r /dev/tty ]; then
        read -rp "Lanjut upgrade/reinstall? (y/N): " CONFIRM </dev/tty
        [[ "${CONFIRM,,}" == "y" ]] || { warn "Dibatalkan."; exit 0; }
    else
        err "Tidak ada TTY untuk konfirmasi. Jalankan ulang dengan --force untuk non-interactive"
    fi
fi

# --- Install dependencies ---
log "Update apt & install dependencies..."
apt-get update -qq
apt-get install -y -qq apt-transport-https software-properties-common wget gnupg

# --- Tambah GPG key & repo Grafana ---
log "Menambahkan GPG key Grafana..."
mkdir -p /usr/share/keyrings
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor > /usr/share/keyrings/grafana.gpg

log "Menambahkan repository Grafana..."
echo "deb [signed-by=/usr/share/keyrings/grafana.gpg] https://apt.grafana.com stable main" \
    > /etc/apt/sources.list.d/grafana.list

# --- Install Grafana ---
log "Install Grafana..."
apt-get update -qq
apt-get install -y grafana

# --- Enable & start service ---
log "Enable & start grafana-server..."
systemctl daemon-reload
systemctl enable --now grafana-server

# --- Verifikasi ---
sleep 2
if systemctl is-active --quiet grafana-server; then
    IP=$(hostname -I | awk '{print $1}')
    VERSION=$(grafana-server -v 2>/dev/null | head -1 || echo "unknown")
    echo ""
    echo "==============================================="
    log "Grafana berhasil terinstall!"
    echo "  Versi   : ${VERSION}"
    echo "  URL     : http://${IP}:3000"
    echo "  Login   : admin / admin (wajib ganti saat login pertama)"
    echo "==============================================="
else
    err "grafana-server gagal start. Cek: journalctl -u grafana-server -n 50"
fi
