#!/usr/bin/env bash
# ATX-Raspi installer for Debian/Raspberry Pi OS using systemd (rc.local is deprecated)
# One-file entrypoint with a simple menu: Install (interrupt-driven) / Uninstall.
# It ALWAYS fetches the current Python script and systemd unit from the repository
# into /tmp, installs to final locations, and cleans up.

set -euo pipefail

# --- Repository (raw) ---
REPO_RAW_BASE="https://raw.githubusercontent.com/makepinya/ATX-Raspi/master"
RAW_PY="${REPO_RAW_BASE}/shutdownirq.py"
RAW_UNIT="${REPO_RAW_BASE}/atxraspi-shutdown.service"

# --- Final install destinations ---
DST_PY="/usr/local/sbin/atxraspi-shutdownirq.py"
DST_SERVICE="/etc/systemd/system/atxraspi-shutdown.service"
PYTHON="/usr/bin/python3"

# --- Temp workspace ---
TMP_DIR="/tmp/atxraspi"
TMP_PY="${TMP_DIR}/shutdownirq.py"
TMP_UNIT="${TMP_DIR}/atxraspi-shutdown.service"

need_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Please run as root: sudo $0"
    exit 1
  fi
}

fetch() {
  local url="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$dst"
  else
    wget -q "$url" -O "$dst"
  fi
}

install_deps() {
  if ! dpkg -s python3-rpi.gpio >/dev/null 2>&1; then
    echo "[INFO] Installing dependency: python3-rpi.gpio"
    apt-get update -y
    apt-get install -y python3-rpi.gpio
  fi
}

clean_tmp() {
  rm -rf "$TMP_DIR" 2>/dev/null || true
}

do_install() {
  need_root
  install_deps

  echo "[INFO] Fetching latest files to ${TMP_DIR}"
  clean_tmp
  mkdir -p "$TMP_DIR"
  fetch "$RAW_PY"   "$TMP_PY"
  fetch "$RAW_UNIT" "$TMP_UNIT"

  # Sanity
  [[ -s "$TMP_PY"   ]] || { echo "Download failed: $RAW_PY";   clean_tmp; exit 1; }
  [[ -s "$TMP_UNIT" ]] || { echo "Download failed: $RAW_UNIT"; clean_tmp; exit 1; }

  echo "[INFO] Installing script -> $DST_PY"
  install -m 0755 "$TMP_PY" "$DST_PY"

  echo "[INFO] Installing systemd unit -> $DST_SERVICE"
  install -m 0644 "$TMP_UNIT" "$DST_SERVICE"

  echo "[INFO] Reloading systemd"
  systemctl daemon-reload

  echo "[INFO] Enabling and starting service"
  systemctl enable --now atxraspi-shutdown.service

  clean_tmp

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

  clean_tmp
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
          1) do_install;   break ;;
          2) do_uninstall; break ;;
          q|Q) exit 0 ;;
          *) echo "Invalid option";;
        esac
      done
      ;;
  esac
}

main "$@"
