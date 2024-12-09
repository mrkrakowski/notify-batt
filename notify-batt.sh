#!/bin/bash

NOTIFY_BATT_CONFIG=~/.config/notify-batt
NOTIFY_BATT_SERVICE=~/etc/systemd/system/ # notify-batt.service
TMP_WARNING=/tmp/battnotificationwarning
TMP_CRITICAL=/tmp/battnotificationcritical

help() {
cat <<EOF
-h, --help                                  Show help message
-i, --init                                  Initialize files
-ic, --init-clean                           Same as init, but removes old files
-wp=NUM, --warning-percentage=NUM           Set warning percentage (for debugging)
-dwp=NUM, --default-warning-percentage=NUM  Set default warning percentage
-cp=NUM, --critical-percentage=NUM          Set critical precentage (for debugging)
-dcp=NUM, --default-critical-percentage=NUM Set critical percentage (lower than warning)
-dwm=NUM, --default-warning-minutes=NUM     Set warning for minutes left
-d, --dump                                  Dump all info
EOF
}

get-pids() {
  notify-send.sh -R $TMP_WARNING foo
  WARNING_PID=$(cat $TMP_WARNING | xargs)
  notify-send.sh -s $WARNING_PID

  notify-send.sh -R $TMP_CRITICAL foo
  CRITICAL_PID=$(cat $TMP_CRITICAL | xargs)
  notify-send.sh -s $CRITICAL_PID
}

init() {
  mkdir -p $NOTIFY_BATT_CONFIG
  mkdir -p $NOTIFY_BATT_SERVICE

  WARNING_TRIGGER_PERCENTAGE=20
  CRITICAL_TRIGGER_PERCENTAGE=10
  WARNING_TRIGGER_MINUTES=60
  CRITICAL_TRIGGER_MINUTES=30
  echo "WARNING_TRIGGER_PERCENTAGE=$WARNING_TRIGGER_PERCENTAGE" > $NOTIFY_BATT_CONFIG/config.conf
  echo "CRITICAL_TRIGGER_PERCENTAGE=$CRITICAL_TRIGGER_PERCENTAGE" >> $NOTIFY_BATT_CONFIG/config.conf
  echo "WARNING_TRIGGER_MINUTES=$WARNING_TRIGGER_MINUTES" >> $NOTIFY_BATT_CONFIG/config.conf
  echo "CRITICAL_TRIGGER_MINUTES=$CRITICAL_TRIGGER_MINUTES" >> $NOTIFY_BATT_CONFIG/config.conf

  get-pids

  echo "Config file location: $NOTIFY_BATT_CONFIG/config.conf"
  echo "Notification ID locations: $TMP_WARNING"
  echo "                           $TMP_CRITICAL"
}

init-clean() {
  rm -rf $NOTIFY_BATT_CONFIG
  if [[ $TMP_WARNING ]]; then
    rm $TMP_WARNING
  fi
  if [[ $TMP_CRITICAL ]]; then
    rm $TMP_CRITICAL
  fi
  init
}

startup() {
  setup-pids
}

get() {
  # You can remove the "> /dev/null" from the end of the echo statements to debug the variables if needed.
  . $NOTIFY_BATT_CONFIG/config.conf
  if [[ "$IS_TEMP_WARNING_PERCENTAGE" == "YES" ]]; then
    WARNING_TRIGGER_PERCENTAGE=TEMP_WARNING_PERCENTAGE
  fi
  if [[ "$IS_TEMP_CRITICAL_PERCENTAGE" == "YES" ]]; then
    CRITICAL_TRIGGER_PERCENTAGE=TEMP_CRITICAL_PERCENTAGE
  fi
  OUT="$(batt)"

  # percentage (number)
  PERCENTAGE=${OUT%'%'*}
  PERCENTAGE=${PERCENTAGE##* }
  echo "percent: $PERCENTAGE" > /dev/null

  # string (either "full" or "empty")
  STR="${OUT%:*}"
  STR="${STR##*'to '}"
  echo "full or empty: $STR" > /dev/null

  case $STR in
    "empty") CHARGING=NO ;;
    *) CHARGING=YES ;;
  esac

  # time until empty (string)
  TIME_UNTIL="${OUT##*:}"
  TIME_UNTIL="$(echo $TIME_UNTIL)"
  echo "time until: $TIME_UNTIL" > /dev/null
  TIME_UNTIL_INT="${TIME_UNTIL%\.*}"
  TIME_UNTIL_STR="${TIME_UNTIL##* }"

  PID_WARNING=$(cat $TMP_WARNING | xargs)
  PID_CRITICAL=$(cat $TMP_CRITICAL | xargs)
}

dump() {
  get
  cat <<EOF
Output for command batt:
$OUT

---------------------------------

Current battery percentage:            $PERCENTAGE
Minutes or hours:                      $MINSORHOURS
Low percentage trigger :               $WARNING_TRIGGER_PERCENTAGE
Critical percentage trigger:           $CRITICAL_TRIGGER_PERCENTAGE
Low minutes left trigger :             $WARNING_TRIGGER_PERCENTAGE
Critical minutes left trigger:         $CRITICAL_TRIGGER_PERCENTAGE
Is currently charging:                 $CHARGING
Time until full/empty:                 $TIME_UNTIL
Time left (int):                       $TIME_UNTIL_INT
Time left (string:                     $TIME_UNTIL_STR
Warning notification PID (if exists):  $PID_WARNING
Critical notification PID (if exists): $PID_CRITICAL
EOF
}

process_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      -i|--init)
        init;
        exit 0;
        ;;
      -ic|--init-clean)
        init-clean;
        exit 0;
        ;;
      -wp=*|--warning-percentage=*)
        TEMP_WARNING_PERCENTAGE="${1#*=}"
        IS_TEMP_WARNING_PERCENTAGE=YES
        echo "Temporary warning percentage set to $TEMP_WARNING_PERCENTAGE"
        shift
        ;;
      -dwp=*|--default-warning-percentage=*)
        WARNING_TRIGGER_PERCENTAGE="${1#*=}"
        sed -i "s/\(WARNING_TRIGGER_PERCENTAGE*=\).*/\1$WARNING_TRIGGER_PERCENTAGE/" $NOTIFY_BATT_CONFIG/config.conf
        echo "Default warning percentage set to $WARNING_TRIGGER_PERCENTAGE"
        shift
        ;;
      -cp=*|--critical-percentage=*)
        TEMP_CRITICAL_PERCENTAGE="${1#*=}"
        IS_TEMP_CRITICAL_PERCENTAGE=YES
        echo "Temporary critical percentage set to $TEMP_CRITICAL_PERCENTAGE"
        shift
        ;;
      -dcp=*|--default-critical-percentage=*)
        CRITICAL_TRIGGER_PERCENTAGE="${1#*=}"
        sed -i "s/\(CRITICAL_TRIGGER_PERCENTAGE*=\).*/\1$CRITICAL_TRIGGER_PERCENTAGE/" $NOTIFY_BATT_CONFIG/config.conf
        echo "Default critical percentage set to $CRITICAL_TRIGGER_PERCENTAGE"
        shift
        ;;
      -dwm=*|--default-warning-minutes=*)

        shift
        ;;
      --startup)
        startup
        exit 0
        ;;
      -d|--dump)
        dump
        exit 0;
        ;;
      -h|--help)
        help
        exit 0;
        ;;
      *)
        echo "Unknown option or misplaced argument $1"
        exit 1
        ;;
    esac
  done
}

main() {
  get
  if [[ "$STR" != "empty" ]]; then
    exit 0
  elif [[ $PERCENTAGE -le $CRITICAL_TRIGGER_PERCENTAGE ]]; then
    notify-send.sh -R $TMP_CRITICAL -t 0 -o "Dismiss:notify-send.sh -s $PID_CRITICAL" --app-name="Battery critical: $PERCENTAGE%" "Battery empty in $TIME_UNTIL."
    exit 1
  elif [[ $PERCENTAGE -le $WARNING_TRIGGER_PERCENTAGE ]]; then
    notify-send.sh -R $TMP_WARNING -t 0 -o "Dismiss:notify-send.sh -s $PID_WARNING" --app-name="Battery Level: $PERCENTAGE%" "Battery empty in $TIME_UNTIL."
    exit 2
  fi
}

process_args $*
main

