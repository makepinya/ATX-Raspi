#!/usr/bin/env bash
# ATX-Raspi installer for Debian Bookworm/Raspberry Pi OS (systemd; no rc.local)
# Installs the interrupt-driven watcher (shutdownirq.py) as a systemd service.
set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_PY="$SCRIPT_DIR/shutdownirq.py"                  # interrupt-based watcher (preferred)
SRC_SERVICE="$SCRIPT_DIR/atxraspi-shutdown.service"  # systemd unit (Bookworm-ready)
DST_PY="/usr/local/sbin/atxraspi-shutdownirq.py"
DST_SERVICE="/etc/systemd/system/atxraspi-shutdown.service"
PYTHON="/usr/bin/python3"

# --- Sanity checks ---
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo $0"
  exit 1
fi

if [[ ! -f "$SRC_PY" ]]; then
  echo "Missing $SRC_PY. Make sure the file exists in the repository."
  exit 1
fi

if [[ ! -f "$SRC_SERVICE" ]]; then
  echo "Missing $SRC_SERVICE. Make sure the systemd unit exists in the repository."
  exit 1
fi

# --- Dependencies ---
if ! dpkg -s python3-rpi.gpio >/dev/null 2>&1; then
  echo "[INFO] Installing dependency: python3-rpi.gpio"
  apt-get update -y
  apt-get install -y python3-rpi.gpio
fi

# --- Install files ---
echo "[INFO] Installing $DST_PY"
install -m 0755 "$SRC_PY" "$DST_PY"

echo "[INFO] Installing $DST_SERVICE"
install -m 0644 "$SRC_SERVICE" "$DST_SERVICE"

# --- Register and start service ---
echo "[INFO] Reloading systemd"
systemctl daemon-reload

echo "[INFO] Enabling and starting service"
systemctl enable --now atxraspi-shutdown.service

echo
systemctl status atxraspi-shutdown.service --no-pager -l || true
echo
echo "[OK] ATX-Raspi installed for Bookworm (systemd)."
echo " - Script:   $DST_PY"
echo " - Service:  $DST_SERVICE"
echo
echo "Note: If you previously enabled dtoverlay=gpio-shutdown in /boot/firmware/config.txt,"
echo "      consider commenting it out to avoid duplicate shutdown events."
echo
echo "Live logs:  journalctl -u atxraspi-shutdown.service -f"
