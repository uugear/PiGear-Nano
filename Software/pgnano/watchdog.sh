#!/bin/bash
# file: watchdog.sh
#
# This script will keep postponing the alarm, unless the system got hung.
#

# get current directory
cur_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# utilities
. "$cur_dir/utilities.sh"

log 'PiGear Nano watchdog is started.'

# loop with interval
running=1
while [[ $running -eq 1 ]]; do

  alarm_ts=$(($(get_sys_timestamp)+$WATCHDOG_INTERVAL+$WATCHDOG_BUFFER))

  localtime=$(date +'%d %H:%M:%S' -d @$alarm_ts)
  
  dhms=$(date +'%d %H %M %S' -d @$alarm_ts)

  when=$(get_utc_date_time $dhms)
  IFS=' ' read -r date timestr <<< "$when"
  IFS=':' read -r hour minute second <<< "$timestr"
  
  log "Postponed alarm to '$localtime' (UTC: $date $hour:$minute:$second) ..."
  set_alarm_time $date $hour $minute $second
  
  sleep $WATCHDOG_INTERVAL

  if [ ! -f "$pgnano_home/watchdog.pid" ]; then
    log 'Watchdog is terminated because its .pid file has been deleted.'
	running=0
  fi
done
