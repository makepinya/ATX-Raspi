# ATXRaspi

[ATXRaspi](https://lowpowerlab.com/guide/atxraspi/) is a smart power controller for Raspberry Pi that allows you to poweroff or reboot your Pi from a switch (with LED status).

## Quick setup steps (Raspberry Pi OS 13 - Debian Trixie):
Log into your Pi an run the setup script (select install or uninstall), then remove it and reboot:
- `sudo wget https://raw.githubusercontent.com/makepinya/ATX-Raspi/master/shutdownchecksetup.sh`
- `sudo bash shutdownchecksetup.sh`
- `sudo rm shutdownchecksetup.sh`
- `sudo reboot`
