[ -z $BASH ] && { exec bash "$0" "$@" || exit; }
#!/bin/bash
# file: PiGearNano.sh
#
# Run this application to interactly configure your PiGear Nano
#

# include utilities script in same directory
my_dir="`dirname \"$0\"`"
my_dir="`( cd \"$my_dir\" && pwd )`"
if [ -z "$my_dir" ] ; then
  exit 1
fi
. "$my_dir/utilities.sh"
. "$my_dir/gpio-util.sh"


realtime_clock()
{
  echo '============================================================'
  echo '|                                                          |'
  echo '|   Realtime Clock                                         |'
  echo '|                                                          |'
  echo '============================================================'

  local running=1
  while [[ $running -eq 1 ]]; do
    # output system time
    local systime='>>> Your system time is: '
    systime+="$(get_sys_time)"
    echo "$systime"

    # output RTC time
    local rtctime='>>> Your RTC time is:    '
    rtctime+="$(get_rtc_time)"
    echo "$rtctime"
  
    echo '  1. Write system time to RTC'
    echo '  2. Write RTC time to system'
    echo '  3. Synchronize with network time'
    local alarm=$(get_alarm_time);
    if [[ $alarm != 'disabled' ]]; then
      alarm=$(get_local_date_time "$alarm")
    fi
    echo "  4. Configure alarm [$alarm]"
    printf '  5. Configure watchdog '
    if [[ -f "$pgnano_home/watchdog.pid" ]]; then
      echo '[on]'
    else
      echo '[off]'
    fi
    echo '  6. Return'
  
    read -p 'Please choose 1~6: ' action
    case $action in
        1 ) system_to_rtc;;
        2 ) rtc_to_system;;
        3 ) net_to_system; system_to_rtc;;
        4 ) set_alarm;;
        5 ) set_watchdog;;
        6 ) running=0;;
        * ) echo 'Please choose from 1 to 6';;
    esac
    echo ''
  done
}


set_alarm()
{
  local alarm_time=$(get_alarm_time)
  local size=${#alarm_time}
  if [ $size == '8' ]; then
    echo '  Alarm time is not set yet.'
  else
    alarm_time=$(get_local_date_time "$alarm_time")
    echo "  Alarm time is currently set to \"$alarm_time\""
  fi
  echo '  Note: setting alarm will turn off watchdog.'
  read -p '  Please set alarm time (dd HH:MM:SS, ?? as wildcard, set 0 to disable) ' when
  if [[ $when == "0" || $when == "00 00:00:00" ]]; then
    log 'Disable alarm.'
    set_alarm_time 00 00 00 00
  elif [[ $when =~ ^[0-3\?][0-9\?][[:space:]][0-2\?][0-9\?]:[0-5\?][0-9\?]:[0-5\?][0-9\?]$ ]]; then
    IFS=' ' read -r date timestr <<< "$when"
    IFS=':' read -r hour minute second <<< "$timestr"
    wildcard='??'
    if [ $date != $wildcard ] && ([ $((10#$date>31)) == '1' ] || [ $((10#$date<1)) == '1' ]); then
      echo '  Day value should be 01~31.'
    elif [ $hour != $wildcard ] && [ $((10#$hour>23)) == '1' ]; then
      echo '  Hour value should be 00~23.'
    else
      local updated='0'
      if [ $hour == '??' ] && [ $date != '??' ]; then
        date='??'
        updated='1'
      fi
      if [ $minute == '??' ] && ([ $hour != '??' ] || [ $date != '??' ]); then
        hour='??'
        date='??'
        updated='1'
      fi
      if [ $second == '??' ]; then
        second='00'
        updated='1'
      fi
      if [ $updated == '1' ]; then
        when="$date $hour:$minute:$second"
        echo "  ...not supported pattern, using \"$when\" instead..."
      fi
      log "  Seting alarm time to \"$when\""
      when=$(get_utc_date_time $date $hour $minute $second)
      IFS=' ' read -r date timestr <<< "$when"
      IFS=':' read -r hour minute second <<< "$timestr"
      set_alarm_time $date $hour $minute $second
	  watchdog_off
      log '  Done :-)'
	  sleep 1
    fi
  else
    echo "  Sorry, can not recognize your input :-("
  fi
}


set_watchdog()
{
  echo 'Note: turning on watchdog will disable alarm.'
  local running=1
  while [[ $running -eq 1 ]]; do
    echo '  1. Turn on watchdog'
    echo '  2. Turn off watchdog'
    echo '  3. Return'
    read -p 'Please choose 1~3: ' action
    case $action in
        1 ) watchdog_on;running=0;;
        2 ) watchdog_off;running=0;;
        3 ) running=0;;
        * ) echo 'Please choose from 1 to 3';;
    esac
    echo ''
  done
  sleep 1
}


adc()
{
  echo '============================================================'
  echo '|                                                          |'
  echo '|   Analog Inputs (ADC)                                    |'
  echo '|                                                          |'
  echo '============================================================'
  local running=1
  while [[ $running -eq 1 ]]; do
    local scales=($(get_adc_available_scales))
    local sc=$(get_adc_scale)
    local sps=$(get_adc_sps)
    local scale=$(center_text $(printf '%.6f' $sc) 8)
    local raw_1=$(center_text $(get_adc_raw 1) 8)
    set_adc_scale $sc
    local raw_2=$(center_text $(get_adc_raw 2) 8)
    set_adc_scale $sc
    local raw_3=$(center_text $(get_adc_raw 3) 8)
    set_adc_scale $sc
    local raw_4=$(center_text $(get_adc_raw 4) 8)
    set_adc_scale $sc
    local pga=$(get_adc_pga)
    local max=$(get_adc_max_code $sps)
    local volt_1=$(get_adc_volt_by_raw $pga $max $raw_1)
    local volt_2=$(get_adc_volt_by_raw $pga $max $raw_2)
    local volt_3=$(get_adc_volt_by_raw $pga $max $raw_3)
    local volt_4=$(get_adc_volt_by_raw $pga $max $raw_4)   
    echo '+--------+--------+--------+--------+--------+'
    echo '|        | ADC-1  | ADC-2  | ADC-3  | ADC-4  |'
    echo '+--------+--------+--------+--------+--------+'
    echo "| Scale  |$scale|$scale|$scale|$scale|"
    echo '+--------+--------+--------+--------+--------+'
    echo "|  Code  |$raw_1|$raw_2|$raw_3|$raw_4|"
    echo '+--------+--------+--------+--------+--------+'
    echo "|  Volt  |$volt_1|$volt_2|$volt_3|$volt_4|"
    echo '+--------+--------+--------+--------+--------+'
    if [[ $sps -eq 240 ]]; then sel=" [\xE2\x9C\x93]"; else sel=''; fi
    echo -e "  1. Set data rate to 240 SPS$sel"
    if [[ $sps -eq 60 ]]; then sel=" [\xE2\x9C\x93]"; else sel=''; fi
    echo -e "  2. Set data rate to 60 SPS$sel"
    if [[ $sps -eq 15 ]]; then sel=" [\xE2\x9C\x93]"; else sel=''; fi
    echo -e "  3. Set data rate to 15 SPS$sel"
    if [[ $sps -eq 3 ]]; then sel=" [\xE2\x9C\x93]"; else sel=''; fi
    echo -e "  4. Set data rate to 3 SPS$sel"
    if [[ $pga -eq 1 ]]; then sel=" [\xE2\x9C\x93]"; else sel=''; fi
    echo -e "  5. Set scale to ${scales[0]} (PGA=1)$sel"
    if [[ $pga -eq 2 ]]; then sel=" [\xE2\x9C\x93]"; else sel=''; fi
    echo -e "  6. Set scale to ${scales[1]} (PGA=2)$sel"
    if [[ $pga -eq 4 ]]; then sel=" [\xE2\x9C\x93]"; else sel=''; fi
    echo -e "  7. Set scale to ${scales[2]} (PGA=4)$sel"
    if [[ $pga -eq 8 ]]; then sel=" [\xE2\x9C\x93]"; else sel=''; fi
    echo -e "  8. Set scale to ${scales[3]} (PGA=8)$sel"
    echo '  9. Return'
    read -p 'Please choose 1~9: ' action
    case $action in
        1 ) set_adc_sps 240;;
        2 ) set_adc_sps 60;;
        3 ) set_adc_sps 15;;
        4 ) set_adc_sps 3;;
        5 ) set_adc_pga 1;;
        6 ) set_adc_pga 2;;
        7 ) set_adc_pga 4;;
        8 ) set_adc_pga 8;;
        9 ) running=0;;
        * ) echo 'Please choose from 1 to 9';;
    esac
  done
}


digital_inputs()
{
  echo '============================================================'
  echo '|                                                          |'
  echo '|   Digital Inputs                                         |'
  echo '|                                                          |'
  echo '============================================================'
  local running=1
  while [[ $running -eq 1 ]]; do
    local byte=$(i2cget -y 0x01 0x20)
    local v1=$(get_di_value 1 $byte)
    local v2=$(get_di_value 2 $byte)
    local v3=$(get_di_value 3 $byte)
    local v4=$(get_di_value 4 $byte)
    echo '+-----+-----+-----+-----+'
    echo '|DI-1 |DI-2 |DI-3 |DI-4 |'
    echo '+-----+-----+-----+-----+'
    echo "|  $v1  |  $v2  |  $v3  |  $v4  |"
    echo '+-----+-----+-----+-----+'
    echo '  1. Refresh'
    echo '  2. Return'
    read -p 'Please choose 1~2: ' action
    case $action in
        2 ) running=0;;
        * ) ;;
    esac
    echo ''
  done
}


digital_outputs()
{
  echo '============================================================'
  echo '|                                                          |'
  echo '|   Digital Outputs                                        |'
  echo '|                                                          |'
  echo '============================================================'
  local running=1
  while [[ $running -eq 1 ]]; do
    local v1=$(get_do_value 1)
    local v2=$(get_do_value 2)
    local v3=$(get_do_value 3)
    local v4=$(get_do_value 4)
    echo '+-----+-----+-----+-----+'
    echo '|DO-1 |DO-2 |DO-3 |DO-4 |'
    echo '+-----+-----+-----+-----+'
    echo "|  $v1  |  $v2  |  $v3  |  $v4  |"
    echo '+-----+-----+-----+-----+'
    echo '  1. Set DO-1 output LOW'
	  echo '  2. Set DO-1 output HIGH'
	  echo '  3. Set DO-2 output LOW'
	  echo '  4. Set DO-2 output HIGH'
  	echo '  5. Set DO-3 output LOW'
	  echo '  6. Set DO-3 output HIGH'
	  echo '  7. Set DO-4 output LOW'
	  echo '  8. Set DO-4 output HIGH'
    echo '  9. Return'
    read -p 'Please choose 1~9: ' action
    case $action in
        1 ) set_do_value 1 0;;
        2 ) set_do_value 1 1;;
	    	3 ) set_do_value 2 0;;
    		4 ) set_do_value 2 1;;
	    	5 ) set_do_value 3 0;;
        6 ) set_do_value 3 1;;
	    	7 ) set_do_value 4 0;;
	    	8 ) set_do_value 4 1;;
        9 ) running=0;;
        * ) echo 'Please choose from 1 to 9';;
    esac
    echo ''
  done
}


configurable_io()
{
  echo '============================================================'
  echo '|                                                          |'
  echo '|   Configurable Digital Inputs/Output                     |'
  echo '|                                                          |'
  echo '============================================================'
  local running=1
  while [[ $running -eq 1 ]]; do
    local mb=$(i2cget -y 0x06 0x20)
    local m1=$(get_dio_mode 1 $mb)
    local m2=$(get_dio_mode 2 $mb)
    local m3=$(get_dio_mode 3 $mb)
    local m4=$(get_dio_mode 4 $mb)
    local vb=$(i2cget -y 0x01 0x20)
    local v1=$(get_dio_value 1 $vb)
    local v2=$(get_dio_value 2 $vb)
    local v3=$(get_dio_value 3 $vb)
    local v4=$(get_dio_value 4 $vb)
    echo '+-----+-----+-----+-----+'
    echo '|DIO-1|DIO-2|DIO-3|DIO-4|'
    echo '+-----+-----+-----+-----+'
    echo "| $m1 | $m2 | $m3 | $m4 |"
    echo '+-----+-----+-----+-----+'
    echo "|  $v1  |  $v2  |  $v3  |  $v4  |"
    echo '+-----+-----+-----+-----+'
    echo ''
    echo '  1. Set to IN-IN-IN-IN'
    echo '  2. Set to IN-IN-OUT-OUT'
	  echo '  3. Set to OUT-OUT-IN-IN'
	  echo '  4. Set to OUT-OUT-OUT-OUT'
	  echo '  5. Set DIO output value...'
    echo '  6. Return'
    read -p 'Please choose 1~6: ' action
    case $action in
        1 ) set_dio_in_in_in_in;;
        2 ) set_dio_in_in_out_out;;
	    	3 ) set_dio_out_out_in_in;;
		    4 ) set_dio_out_out_out_out;;
		    5 ) set_dio_output;;
        6 ) running=0;;
        * ) echo 'Please choose from 1 to 6';;
    esac
    echo ''
  done
}


set_dio_output()
{
  local running=1
  while [[ $running -eq 1 ]]; do
    echo '  1. Set DIO-1 output LOW'
	  echo '  2. Set DIO-1 output HIGH'
	  echo '  3. Set DIO-2 output LOW'
	  echo '  4. Set DIO-2 output HIGH'
  	echo '  5. Set DIO-3 output LOW'
	  echo '  6. Set DIO-3 output HIGH'
	  echo '  7. Set DIO-4 output LOW'
	  echo '  8. Set DIO-4 output HIGH'
  	echo '  9. Return'
    read -p 'Please choose 1~9: ' action
    case $action in
        1 ) set_dio_output_value 1 0;running=0;;
        2 ) set_dio_output_value 1 1;running=0;;
	    	3 ) set_dio_output_value 2 0;running=0;;
    		4 ) set_dio_output_value 2 1;running=0;;
	    	5 ) set_dio_output_value 3 0;running=0;;
        6 ) set_dio_output_value 3 1;running=0;;
	    	7 ) set_dio_output_value 4 0;running=0;;
	    	8 ) set_dio_output_value 4 1;running=0;;
        9 ) running=0;;
        * ) echo 'Please choose from 1 to 9';;
    esac
    echo ''
  done
}


led_test()
{
  echo '============================================================'
  echo '|                                                          |'
  echo '|   Programmable LED Test                                  |'
  echo '|                                                          |'
  echo '============================================================'
  echo 'Red LED lights up for 1 second while yellow LED is off'
  gpio -g mode 26 out
  gpio -g write 26 1
  sleep 1
  gpio -g write 26 0
}


buzzer_test()
{
  echo '============================================================'
  echo '|                                                          |'
  echo '|   Buzzer Test                                            |'
  echo '|                                                          |'
  echo '============================================================'
  echo 'Buzzer turns on for 1 second'
  gpio -g mode 25 out
  gpio -g write 25 1
  sleep 1
  gpio -g write 25 0
}


# main menu
is_rtc_connected
has_rtc=$?
while true; do
  echo '================================================================================'
  echo '|                                                                              |'
  echo '|   PiGear Nano - Nano-ITX Raspberry Pi Compute Module 4 Carrier Board         |'
  echo '|                                                                              |'
  echo '|                   < Version 1.01 >  by  Dun Cat B.V.                         |'
  echo '|                                                                              |'
  echo '================================================================================'
  if [ $has_rtc == 0 ] ; then
    rtctime=$(get_rtc_time)
  else
    rtctime='-- cannot access RTC --'
  fi
  echo "1. Realtime Clock [$rtctime]"
  echo '2. Analog Inputs (ADC)'
  echo '3. Digital Inputs'
  echo '4. Digital Outputs'
  echo '5. Configurable Digital Inputs/Outputs'
  echo '6. Programmable LED Test'
  echo '7. Buzzer Test'
  echo '8. Exit'
  read -p 'Please choose 1~8: ' action
  case $action in
      1 ) if [ $has_rtc == 0 ]; then realtime_clock; else echo $rtctime; fi;;
	    2 ) adc;;
	    3 ) digital_inputs;;
	    4 ) digital_outputs;;
      5 ) configurable_io;;
      6 ) led_test;;
      7 ) buzzer_test;;
      8 ) exit;;
      * ) echo 'Please choose from 1 to 8';;
  esac
  echo ''
  sleep 0.5
done