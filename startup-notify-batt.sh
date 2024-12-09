#!/bin/bash

NOTIFY_BATT_CONFIG=~/.config/notify-batt
NOTIFY_BATT_SERVICE=~/etc/systemd/system/notify-batt.service
NOTIFY_BATT_PATH=/usr/local/bin/notify-batt

notify-batt.sh --startup

while true; do

  notify-batt.sh
  sleep 2
done
