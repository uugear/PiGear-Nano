#!/bin/bash
# file: utilities.sh
#
# This script provides some useful utility functions
#

if [ -z ${I2C_RTC_ADDRESS+x} ]; then
  readonly I2C_RTC_ADDRESS=0x51
  
  # used GPIO pins
  readonly BUZZER_PIN=25
  readonly LED_PIN=26
  readonly HALT_PIN=27
  readonly DO_1_PIN=11
  readonly DO_2_PIN=16
  readonly DO_3_PIN=17
  readonly DO_4_PIN=22
  readonly DATA_INT_PIN=23
  
  # watchdog
  readonly WATCHDOG_INTERVAL=30
  readonly WATCHDOG_BUFFER=5
  
  # network accessibility and network time
  readonly INTERNET_SERVER='http://google.com'
fi

pgnano_home="`dirname \"$0\"`"
pgnano_home="`( cd \"$pgnano_home\" && pwd )`"

log2file()
{
  local datetime=$(date +'[%Y-%m-%d %H:%M:%S]')
  local msg="$datetime $1"
  echo $msg >> $pgnano_home/logs/pgnano.log
}

log()
{
  if [ $# -gt 1 ] ; then
    echo $2 "$1"
  else
    echo "$1"
  fi
  log2file "$1"
}

i2c_read()
{
  local retry=0
  if [ $# -gt 3 ] ; then
    retry=$4
  fi
  local result=$(i2cget -y $1 $2 $3)
  if [[ $result =~ ^0x[0-9a-fA-F]{2}$ ]] ; then
    echo $result;
  else
    retry=$(( $retry + 1 ))
    if [ $retry -eq 4 ] ; then
      log "I2C read $1 $2 $3 failed (result=$result), and no more retry."
    else
      sleep 1
      log2file "I2C read $1 $2 $3 failed (result=$result), retrying $retry ..."
      i2c_read $1 $2 $3 $retry
    fi
  fi
}

i2c_write()
{
  local retry=0
  if [ $# -gt 4 ] ; then
    retry=$5
  fi
  i2cset -y $1 $2 $3 $4
  local result=$(i2c_read $1 $2 $3)
  if [ "$result" != $(dec2hex "$4") ] ; then
    retry=$(( $retry + 1 ))
    if [ $retry -eq 4 ] ; then
      log "I2C write $1 $2 $3 $4 failed (result=$result), and no more retry."
    else
      sleep 1
      log2file "I2C write $1 $2 $3 $4 failed (result=$result), retrying $retry ..."
      i2c_write $1 $2 $3 $4 $retry
    fi
  fi
}

calc()
{
  awk "BEGIN { print $*}";
}

bcd2dec()
{
  local result=$(($1/16*10+($1&0xF)))
  echo $result
}

dec2bcd()
{
  local result=$((10#$1/10*16+(10#$1%10)))
  echo $result
}

dec2hex()
{
  printf "0x%02x" $1
}

get_utc_date_time()
{
  local date=$1
  if [ $date == '??' ]; then
    date='01'
  fi
  local hour=$2
  if [ $hour == '??' ]; then
    hour='12'
  fi
  local minute=$3
  if [ $minute == '??' ]; then
    minute='00'
  fi
  local second=$4
  if [ $second == '??' ]; then
    second='00'
  fi
  local datestr=$(date +%Y-)
  local curDate=$(date +%d)
  if [[ "$date" < "$curDate" ]] ; then
    datestr+=$(date --date="$(date +%Y-%m-15) +1 month" +%m-)
  else
    datestr+=$(date +%m-)
  fi
  datestr+="$date $hour:$minute:$second"
  datestr+=$(date +%:z)
  local result=$(date -u -d "$datestr" +"%d %H:%M:%S" 2>/dev/null)
  IFS=' ' read -r date timestr <<< "$result"
  IFS=':' read -r hour minute second <<< "$timestr"
  if [ $1 == '??' ]; then
    date='??'
  fi
  if [ $2 == '??' ]; then
    hour='??'
  fi
  if [ $3 == '??' ]; then
    minute='??'
  fi
  if [ $4 == '??' ]; then
    second='??'
  fi
  echo "$date $hour:$minute:$second"
}

get_local_date_time()
{
  local when=$1
  IFS=' ' read -r date timestr <<< "$when"
  IFS=':' read -r hour minute second <<< "$timestr"
  local bk_date=$date
  local bk_hour=$hour
  local bk_min=$minute
  local bk_sec=$second
  if [ $date == '??' ]; then
    date='01'
  fi
  if [ $hour == '??' ]; then
    hour='12'
  fi
  if [ $minute == '??' ]; then
    minute='00'
  fi
  if [ $second == '??' ]; then
    second='00'
  fi
  local datestr=$(date +%Y-)
  local curDate=$(date +%d)
  if [[ "$date" < "$curDate" ]] ; then
    datestr+=$(date --date="$(date +%Y-%m-15) +1 month" +%m-)
  else
    datestr+=$(date +%m-)
  fi
  datestr+="$date $hour:$minute:$second UTC"
  local result=$(date -d "$datestr" +"%d %H:%M:%S" 2>/dev/null)
  IFS=' ' read -r date timestr <<< "$result"
  IFS=':' read -r hour minute second <<< "$timestr"
  if [ -z ${2+x} ] ; then
    if [ $bk_date == '??' ]; then
      date='??'
    fi
    if [ $bk_hour == '??' ]; then
      hour='??'
    fi
    if [ $bk_min == '??' ]; then
      minute='??'
    fi
    if [ $bk_sec == '??' ]; then
      second='??'
    fi
  fi
  echo "$date $hour:$minute:$second"
}

get_sys_time()
{
  echo $(date +'%a %d %b %Y %H:%M:%S %Z')
}

get_sys_timestamp()
{
	echo $(date -u +%s)
}

is_rtc_connected()
{
  local result=$(i2cdetect -y 1)
  if [[ $result == *"51"* ]] ; then
    return 0
  else
    return 1
  fi
}

get_rtc_timestamp()
{
	sec=$(bcd2dec $(i2c_read 0x01 $I2C_RTC_ADDRESS 0x04))
	min=$(bcd2dec $(i2c_read 0x01 $I2C_RTC_ADDRESS 0x05))
	hour=$(bcd2dec $(i2c_read 0x01 $I2C_RTC_ADDRESS 0x06))
	date=$(bcd2dec $(i2c_read 0x01 $I2C_RTC_ADDRESS 0x07))
	month=$(bcd2dec $(i2c_read 0x01 $I2C_RTC_ADDRESS 0x09))
	year=$(bcd2dec $(i2c_read 0x01 $I2C_RTC_ADDRESS 0x0A))
	echo $(date --date="$year-$month-$date $hour:$min:$sec UTC" +%s)
}

get_rtc_time()
{
  local rtc_ts=$(get_rtc_timestamp)
  if [ "$rtc_ts" == "" ] ; then
    echo 'N/A'
  else
    echo $(date +'%a %d %b %Y %H:%M:%S %Z' -d @$rtc_ts)
  fi
}

get_alarm_time()
{
  local ctrl2=$(i2c_read 0x01 $I2C_RTC_ADDRESS 0x01)
  if [[ -f "$pgnano_home/watchdog.pid" || $(("$ctrl2" & 0x80)) -eq 0 ]]; then
    echo "disabled"
  else
    local sec=$(bcd2dec $(i2c_read 0x01 $I2C_RTC_ADDRESS 0x0B))
    if [[ $(("0x$sec" & 0x80)) -ne 0 ]]; then
      sec='??'
    fi
    local min=$(bcd2dec $(i2c_read 0x01 $I2C_RTC_ADDRESS 0x0C))
    if [[ $(("0x$min" & 0x80)) -ne 0 ]]; then
      min='??'
    fi
    local hour=$(bcd2dec $(i2c_read 0x01 $I2C_RTC_ADDRESS 0x0D))
    if [[ $(("0x$hour" & 0x80)) -ne 0 ]]; then
      hour='??'
    fi
    local date=$(bcd2dec $(i2c_read 0x01 $I2C_RTC_ADDRESS 0x0E))
    if [[ $(("0x$date" & 0x80)) -ne 0 ]]; then
      date='??'
    fi
    echo "$date $hour:$min:$sec"
  fi
}

set_alarm_time()
{
  if [[ $1 == '00' && $2 == '00' && $3 == '00' && $4 == '00' ]]; then
    i2c_write 0x01 $I2C_RTC_ADDRESS 0x01 0x00
  else
    i2c_write 0x01 $I2C_RTC_ADDRESS 0x01 0x80
    if [ $4 == '??' ]; then
      sec='128'
    else
      sec=$(dec2bcd $4)
    fi
    i2c_write 0x01 $I2C_RTC_ADDRESS 0x0B $sec
    if [ $3 == '??' ]; then
      min='128'
    else
      min=$(dec2bcd $3)
    fi
    i2c_write 0x01 $I2C_RTC_ADDRESS 0x0C $min
    if [ $2 == '??' ]; then
      hour='128'
    else
      hour=$(dec2bcd $2)
    fi
    i2c_write 0x01 $I2C_RTC_ADDRESS 0x0D $hour
    if [ $1 == '??' ]; then
      date='128'
    else
      date=$(dec2bcd $1)
    fi
    i2c_write 0x01 $I2C_RTC_ADDRESS 0x0E $date
  fi
}

clear_alarm_flag()
{
  local ctrl2=$(i2c_read 0x01 $I2C_RTC_ADDRESS 0x01)
  ctrl2=$(($ctrl2&0xBF))
  i2c_write 0x01 $I2C_RTC_ADDRESS 0x01 $ctrl2
}

set_capsel_bit()
{
  local ctrl1=$(i2c_read 0x01 $I2C_RTC_ADDRESS 0x00)
  ctrl1=$(($ctrl1|0x01))
  i2c_write 0x01 $I2C_RTC_ADDRESS 0x00 $ctrl1
}

has_internet()
{
  resp=$(curl -s --head $INTERNET_SERVER)
  if [[ ${#resp} -ne 0 ]] ; then
    return 0
  else
    return 1
  fi
}

get_network_timestamp()
{
  if $(has_internet) ; then
    local t=$(curl -s --head $INTERNET_SERVER | grep ^Date: | sed 's/Date: //g')
    if [ ! -z "$t" ]; then
      echo $(date -d "$t" +%s)
    else
      echo -1
    fi
  else
    echo -1
  fi
}

net_to_system()
{
	local net_ts=$(get_network_timestamp)
	if [[ "$net_ts" != "-1" ]]; then
    log '  Applying network time to system...'
    sudo date -u -s @$net_ts >/dev/null
    log '  Done :-)'
  else
    log '  Can not get legit network time.'
  fi
}

system_to_rtc()
{
  log '  Writing system time to RTC...'
  local sys_ts=$(calc $(get_sys_timestamp)+1)
  local sec=$(date -u -d @$sys_ts +%S)
  local min=$(date -u -d @$sys_ts +%M)
  local hour=$(date -u -d @$sys_ts +%H)
  local day=$(date -u -d @$sys_ts +%u)
  local date=$(date -u -d @$sys_ts +%d)
  local month=$(date -u -d @$sys_ts +%m)
  local year=$(date -u -d @$sys_ts +%y)
  i2c_write 0x01 $I2C_RTC_ADDRESS 0x04 $(dec2bcd $sec)
  i2c_write 0x01 $I2C_RTC_ADDRESS 0x05 $(dec2bcd $min)
  i2c_write 0x01 $I2C_RTC_ADDRESS 0x06 $(dec2bcd $hour)
  i2c_write 0x01 $I2C_RTC_ADDRESS 0x07 $(dec2bcd $date)
  i2c_write 0x01 $I2C_RTC_ADDRESS 0x08 $(dec2bcd $day)
  i2c_write 0x01 $I2C_RTC_ADDRESS 0x09 $(dec2bcd $month)
  i2c_write 0x01 $I2C_RTC_ADDRESS 0x0A $(dec2bcd $year)
  log '  Done :-)'
}

rtc_to_system()
{
  log '  Writing RTC time to system...'
	local rtc_ts=$(get_rtc_timestamp)
	sudo date -u -s @$rtc_ts >/dev/null
  log '  Done :-)'
}

watchdog_on()
{
  if [ ! -f "$pgnano_home/watchdog.pid" ]; then
    log 'Turn on watchdog'    
    "$pgnano_home/watchdog.sh" >> "$pgnano_home/logs/watchdog.log" &
  	echo $! > "$pgnano_home/watchdog.pid"
  fi  
}

watchdog_off()
{
  if [[ -f "$pgnano_home/watchdog.pid" ]]; then
    log 'Turn off watchdog'
    set_alarm_time 00 00 00 00
    local pid=$(cat "$pgnano_home/watchdog.pid")
  	sudo kill -9 $pid
    sudo rm "$pgnano_home/watchdog.pid"
  fi
}

get_di_value()
{
  local byte=$2
  if [ -z "$2" ]; then
    byte=$(i2cget -y 1 0x20)
  fi
  if [[ $1 -eq 1 ]]; then
    echo $(($byte&0x01))
  elif [[ $1 -eq 2 ]]; then
    echo $((($byte&0x02)>>1))
  elif [[ $1 -eq 3 ]]; then
    echo $((($byte&0x04)>>2))
  elif [[ $1 -eq 4 ]]; then
    echo $((($byte&0x08)>>3))
  else
    echo 'N/A'
  fi
}

get_do_value()
{
  if [[ $1 -eq 1 ]]; then
    gpio -g read 11
  elif [[ $1 -eq 2 ]]; then
    gpio -g read 16
  elif [[ $1 -eq 3 ]]; then
    gpio -g read 17
  elif [[ $1 -eq 4 ]]; then
    gpio -g read 22
  else
    echo "DO-$1 does not exist"
  fi
}

set_do_value()
{
  if [[ $2 -eq 0 || $2 -eq 1 ]]; then
    local ctrl=$(i2cget -y 6 0x20)
    local byte=$(i2cget -y 1 0x20)
    if [[ $1 -eq 1 ]]; then
      gpio -g write 11 $2
      send_pcf8574_b2_rising $ctrl $byte
    elif [[ $1 -eq 2 ]]; then
      gpio -g write 16 $2
      send_pcf8574_b2_rising $ctrl $byte
    elif [[ $1 -eq 3 ]]; then
      gpio -g write 17 $2
      send_pcf8574_b2_rising $ctrl $byte
    elif [[ $1 -eq 4 ]]; then
      gpio -g write 22 $2
      send_pcf8574_b2_rising $ctrl $byte
    else
      echo "DO-$1 does not exist"
    fi
  else
    echo "DO value must be 0 or 1"
  fi
}

get_dio_mode()
{
  local byte=$2
  if [ -z "$2" ]; then
    byte=$(i2cget -y 6 0x20)
  fi
  local en=$(($byte&0x01))
  if [[ en -eq 1 ]]; then
    echo 'N/A'
  else
    if [[ $1 -eq 1 || $1 -eq 2 ]]; then
      local mode=$(($byte&0x04))
      if [[ $mode -ne 0 ]]; then
        echo 'OUT'
      else
        echo 'IN '
      fi
    elif [[ $1 -eq 3 || $1 -eq 4 ]]; then
      local mode=$(($byte&0x08))
      if [[ $mode -ne 0 ]]; then
        echo 'OUT'
      else
        echo 'IN '
      fi
    else
      echo 'N/A'
    fi
  fi
}

get_dio_value()
{
  local byte=$2
  if [ -z "$2" ]; then
    byte=$(i2cget -y 1 0x20)
  fi
  if [[ $1 -eq 1 ]]; then
    echo $((($byte&0x10)>>4))
  elif [[ $1 -eq 2 ]]; then
    echo $((($byte&0x20)>>5))
  elif [[ $1 -eq 3 ]]; then
    echo $((($byte&0x40)>>6))
  elif [[ $1 -eq 4 ]]; then
    echo $((($byte&0x80)>>7))
  else
    echo 'N/A'
  fi
}

set_dio_in_in_in_in()
{
  i2cset -y 1 0x20 0x0F
  i2cset -y 6 0x20 0xF0
  i2cset -y 1 0x20 0xFF
}

set_dio_in_in_out_out()
{
  i2cset -y 1 0x20 0x0F
  i2cset -y 6 0x20 0xF8
  sleep 0.2
  i2cset -y 6 0x20 0xFA
  i2cset -y 1 0x20 0x3F
}

set_dio_out_out_in_in()
{
  i2cset -y 1 0x20 0x0F
  i2cset -y 6 0x20 0xF4
  sleep 0.2
  i2cset -y 6 0x20 0xF6
  i2cset -y 1 0x20 0xCF
}

set_dio_out_out_out_out()
{
  i2cset -y 1 0x20 0x0F
  i2cset -y 6 0x20 0xFC
  sleep 0.2
  i2cset -y 6 0x20 0xFE
}

send_pcf8574_b2_rising()
{
  local ctrl=$1
  if [ -z "$1" ]; then
    ctrl=$(i2cget -y 6 0x20)
  fi
  local byte=$2
  if [ -z "$2" ]; then
    byte=$(i2cget -y 1 0x20)
  fi
  
  if [[ $ctrl -eq 0xf0 || $ctrl -eq 0xf2 ]]; then
    byte=0x00
  elif [[ $ctrl -eq 0xfa ]]; then
    byte=$(($byte&0xc0))
  elif [[ $ctrl -eq 0xf6 ]]; then
    byte=$(($byte&0x30))
  fi
  i2cset -y 1 0x20 $byte
  
  i2cset -y 6 0x20 $(($ctrl&0xFD))
  sleep 0.001
  i2cset -y 6 0x20 $(($ctrl|0x02))
  
  if [[ $ctrl -eq 0xf0 || $ctrl -eq 0xf2 ]]; then
    byte=0xff
  elif [[ $ctrl -eq 0xfa ]]; then
    byte=$(($byte|0x3f))
  elif [[ $ctrl -eq 0xf6 ]]; then
    byte=$(($byte|0xcf))
  fi
  i2cset -y 1 0x20 $byte
}

set_dio_output_value()
{
  local ctrl=$(i2cget -y 6 0x20)
  local mode=$(get_dio_mode $1 $ctrl)
  if [[ $mode == 'OUT' ]]; then
    local byte=$(i2cget -y 1 0x20)
  	if [[ $1 -eq 1 || $1 -eq 2 || $1 -eq 3 || $1 -eq 4 ]]; then  	  
  	  if [[ $2 -eq 1 ]]; then
  	    byte=$(($byte|(1<<($1+3))))
  		  send_pcf8574_b2_rising $ctrl $byte
  	  elif [[ $2 -eq 0 ]]; then
  	    byte=$(($byte&(~(1<<($1+3)))))
  		  send_pcf8574_b2_rising $ctrl $byte
  	  else
  	    echo "DIO output value must be 0 or 1"
  	  fi
  	else
        echo "DIO index must between 1~4"
  	fi
  else
    echo "DIO-$1 is not in output mode (mode=$mode)"
  fi
}

get_adc_sps()
{
  cat '/dev/i2cadc/in_voltage_sampling_frequency'
}

set_adc_sps()
{
  if [[ $1 == '240' || $1 == '60' || $1 == '15' || $1 == '3' ]]; then
    sudo su -c "echo $1 > /dev/i2cadc/in_voltage_sampling_frequency"
  else
    echo "Unsupported SPS value '$1'"
  fi
}

get_adc_max_code()
{
  local sps=$1
  if [ -z "$1" ]; then
    sps=$(get_adc_sps)
  fi
  if [[ $sps == '240' ]]; then
    echo '2047'
  elif [[ $sps == '60' ]]; then
    echo '8191'
  elif [[ $sps == '15' ]]; then
    echo '32767'
  elif [[ $sps == '3' ]]; then
    echo '131071'
  else
    echo 'N/A'
  fi
}

get_adc_available_scales()
{
  cat '/dev/i2cadc/in_voltage_scale_available'
}

get_adc_pga()
{
  local scale=$(cat "/dev/i2cadc/in_voltage0_scale")
  local scales=($(get_adc_available_scales))
  if [[ $scale == "${scales[0]}" ]]; then
    echo 1
  elif [[ $scale == "${scales[1]}" ]]; then
    echo 2
  elif [[ $scale == "${scales[2]}" ]]; then
    echo 4
  elif [[ $scale == "${scales[3]}" ]]; then
    echo 8
  else
    echo "Unknown PGA (scale=$scale)"
  fi
}

set_adc_pga()
{
  local scales=($(get_adc_available_scales))
  if [[ $1 -eq 1 ]]; then
    set_adc_scale ${scales[0]}
  elif [[ $1 -eq 2 ]]; then
    set_adc_scale ${scales[1]}
  elif [[ $1 -eq 4 ]]; then
    set_adc_scale ${scales[2]}
  elif [[ $1 -eq 8 ]]; then
    set_adc_scale ${scales[3]}
  else
    echo "Unsupported PGA value '$1'"
  fi
}

set_adc_scale()
{
  sudo su -c "echo $1 > /dev/i2cadc/in_voltage0_scale"
}

get_adc_scale()
{
  cat '/dev/i2cadc/in_voltage0_scale'
}

get_adc_raw()
{
  if [[ $1 -ge 1 && $1 -le 4 ]]; then
    local index=$(($1-1))
    cat "/dev/i2cadc/in_voltage${index}_raw"
  fi
}

get_adc_volt_by_raw()
{
  local pga=$1
  local max=$2
  local ratio=$(calc 11.634382/$max/$pga)
  echo $(printf '%.6f' $(calc $ratio*$3))
}

center_text()
{
  local text=$1
  local length=$2
  let leading=($length-${#text})/2
  let trailing=$length-$leading-${#text}
  if [[ $leading -lt 0 ]]; then
  	let leading=0
  	let trailing=0
  fi
  printf "%${leading}s"
  printf $text
  printf "%${trailing}s"
}