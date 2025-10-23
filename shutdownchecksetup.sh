#!/usr/bin/env bash
# ATX-Raspi installer for Debian/Raspberry Pi OS that use systemd (rc.local is deprecated)
# Provides a simple menu: Install (interrupt-driven) / Uninstall.
set -euo pipefail

# --- Config ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_PY="$SCRIPT_DIR/shutdownirq.py"                  # interrupt-based watcher (preferred)
SRC_SERVICE="$SCRIPT_DIR/atxraspi-shutdown.service"  # systemd unit

DST_PY="/usr/local/sbin/atxraspi-shutdownirq.py"
DST_SERVICE="/etc/systemd/system/atxraspi-shutdown.service"
PYTHON="/usr/bin/python3"

need_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Please run as root: sudo $0"
    exit 1
  fi
}

install_deps() {
  if ! dpkg -s python3-rpi.gpio >/dev/null 2>&1; then
    echo "[INFO] Installing dependency: python3-rpi.gpio"
    apt-get update -y
    apt-get install -y python3-rpi.gpio
  fi
}

do_install() {
  need_root

  # Sanity checks
  [[ -f "$SRC_PY" ]] || { echo "Missing $SRC_PY in repository."; exit 1; }
  [[ -f "$SRC_SERVICE" ]] || { echo "Missing $SRC_SERVICE in repository."; exit 1; }

  install_deps

  echo "[INFO] Installing script -> $DST_PY"
  install -m 0755 "$SRC_PY" "$DST_PY"

  echo "[INFO] Installing systemd unit -> $DST_SERVICE"
  install -m 0644 "$SRC_SERVICE" "$DST_SERVICE"

  echo "[INFO] Reloading systemd"
  systemctl daemon-reload

  echo "[INFO] Enabling and starting service"
  systemctl enable --now atxraspi-shutdown.service

  echo
  systemctl status atxraspi-shutdown.service --no-pager -l || true
  echo
  echo "[OK] ATX-Raspi installed (systemd)."
  echo " - Script:  $DST_PY"
  echo " - Service: $DST_SERVICE"
  echo
  echo "Note: If you previously enabled dtoverlay=gpio-shutdown in /boot/firmware/config.txt,"
  echo "      consider commenting it out to avoid duplicate shutdown events."
  echo "Logs: journalctl -u atxraspi-shutdown.service -f"
}

do_uninstall() {
  need_root

  echo "[INFO] Stopping/Disabling service (if present)"
  systemctl disable --now atxraspi-shutdown.service 2>/dev/null || true

  echo "[INFO] Removing files"
  rm -f "$DST_SERVICE" "$DST_PY"

  echo "[INFO] Reloading systemd"
  systemctl daemon-reload

  echo "[OK] Uninstalled."
}

show_menu() {
  echo "ATX-Raspi setup (systemd)"
  echo "-------------------------"
  echo "1) Install (interrupt-driven)"
  echo "2) Uninstall"
  echo "q) Quit"
  echo -n "Select option: "
}

main() {
  case "${1:-}" in
    install)   do_install ;;
    uninstall) do_uninstall ;;
    *)
      while true; do
        show_menu
        read -r opt
        case "$opt" in
          1) do_install; break ;;
          2) do_uninstall; break ;;
          q|Q) exit 0 ;;
          *) echo "Invalid option";;
        esac
      done
      ;;
  esac
}

main "$@"
