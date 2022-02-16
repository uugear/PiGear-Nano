#!/bin/bash
# file: daemon.sh
#
# This script should be automatically started in the background
# to support PiGear-Nano hardware
#

# get current directory
cur_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# utilities
. "$cur_dir/utilities.sh"
. "$cur_dir/gpio-util.sh"

log 'PiGear Nano daemon (v1.01) is started.'

# log Raspberry Pi model
pi_model=$(tr -d '\0' </proc/device-tree/model)
log "Running on $pi_model"

# configure some GPIO pins' default state
gpio -g mode $BUZZER_PIN out
gpio -g write $BUZZER_PIN 0
gpio -g mode $LED_PIN out
gpio -g write $LED_PIN 0
gpio -g mode $HALT_PIN up
gpio -g mode $HALT_PIN in
gpio -g mode $DO_1_PIN out
gpio -g write $DO_1_PIN 0
gpio -g mode $DO_2_PIN out
gpio -g write $DO_2_PIN 0
gpio -g mode $DO_3_PIN out
gpio -g write $DO_3_PIN 0
gpio -g mode $DO_4_PIN out
gpio -g write $DO_5_PIN 0
gpio -g mode $DATA_INT_PIN up
gpio -g mode $DATA_INT_PIN in

# clear the alarm flag, set CAP_SEL bit, write RTC time to system
is_rtc_connected
has_rtc=$?  # should be 0 if RTC presents
if [ $has_rtc == 0 ] ; then
  log 'Clear the alarm flag'
  clear_alarm_flag
  log 'Set CAP_SEL bit'
  set_capsel_bit
  rtc_to_system
else
  log 'RTC not found or not accessible'
fi

# start watchdog if it is enabled
if [[ -f "$cur_dir/watchdog.pid" ]]; then
  rm "$cur_dir/watchdog.pid"
  watchdog_on
fi

# enable LTE module (if exist)
raspi-gpio set 6 op pn dh
raspi-gpio set 7 op pn dl

# ADC
echo 'mcp3424 0x68' > /sys/bus/i2c/devices/i2c-6/new_device
ln -s /sys/bus/i2c/devices/6-0068/iio:device0/ /dev/i2cadc

# set default I/O mode for DIO pins
set_dio_in_in_in_in

# delay until GPIO pin state gets stable
counter=0
while [ $counter -lt 5 ]; do  # increase this value if it needs more time
  if [ $(gpio -g read $HALT_PIN) == '1' ] ; then
    counter=$(($counter+1))
  else
    counter=0
  fi
  sleep 1
done

# wait for GPIO-4 (BCM naming) falling
gpio -g wfi $HALT_PIN falling

# restore HALT_PIN
gpio -g mode $HALT_PIN in
gpio -g mode $HALT_PIN up

log "Turning off system because GPIO-$HALT_PIN pin is pulled down."

# halt everything and shutdown
shutdown -h now
