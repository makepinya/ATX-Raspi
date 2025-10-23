ATXRaspi
=========

ATXRaspi is a smart power controller for RaspberryPi that allows you to poweroff or reboot your Pi from a momentary switch (with LED status).

For the latest revision and details please see the [official ATXRaspi Guide](https://lowpowerlab.com/guide/atxraspi/).

## Quick setup steps (raspbian):
Log into your Pi an run the setup script, then remove it and reboot:
- `sudo wget https://raw.githubusercontent.com/LowPowerLab/ATX-Raspi/master/shutdownchecksetup.sh`
- `sudo bash shutdownchecksetup.sh`
- `sudo rm shutdownchecksetup.sh`
- `sudo reboot`
