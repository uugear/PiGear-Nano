[ -z $BASH ] && { exec bash "$0" "$@" || exit; }
#!/bin/bash
# file: installPiGearNano.sh
#
# This script will install required software and make
# necessary configuration for PiGear Nano.
#
# It is recommended to run it in your home directory.
#

# check if sudo is used
if [ "$(id -u)" != 0 ]; then
  echo 'Sorry, you need to run this script with sudo'
  exit 1
fi

# add parameter to config.txt
add_to_config()
{
  local param=$(grep "$1" /boot/config.txt)
  param=$(echo -e "$param" | sed -e 's/^[[:space:]]*//')
  if [[ -z "$param" || "$param" == "#"* ]]; then
    echo "$1" >> /boot/config.txt
  else
    echo "Seems '$1' already exists in config.txt, skip this step."
  fi
}

# target directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/pgnano"

# error counter
ERR=0

echo '================================================================================'
echo '|                                                                              |'
echo '|                   PiGear Nano Software Installation Script                   |'
echo '|                                                                              |'
echo '================================================================================'

# backup config.txt and cmdline.txt files
mkdir -p "$DIR/backups"
timestr=$(date +%Y%m%d%H%M%S)
echo "/boot/config.txt is backed up to $DIR/backups/config.txt.$timestr"
cp /boot/config.txt "$DIR/backups/config.txt.$timestr"
echo "/boot/cmdline.txt is backed up to $DIR/backups/cmdline.txt.$timestr"
cp /boot/cmdline.txt "$DIR/backups/cmdline.txt.$timestr"

echo '>>> Modify config.txt and cmdline.txt'

echo -e "\n\n#=== PiGear Nano Installation at $timestr ===#" >> /boot/config.txt

# i2c related configuration
echo -e '\n# I2C related' >> /boot/config.txt
add_to_config 'dtparam=i2c_arm=on'
add_to_config 'dtoverlay=i2c1,pins_2_3'
add_to_config 'dtoverlay=i2c6,pins_0_1'

# serial port related configuration
echo -e '\n# Serial port related' >> /boot/config.txt
add_to_config 'dtoverlay=pi3-miniuart-bt'
add_to_config 'enable_uart=1' 
add_to_config 'dtoverlay=uart3'
add_to_config 'dtoverlay=uart4'
add_to_config 'dtoverlay=uart5'
sed -i 's/console=serial0,[[:space:]]*[[:digit:]]\+[[:space:]]*console=tty1[[:space:]]*//' /boot/cmdline.txt

# SPI related configuration
echo -e '\n# SPI related' >> /boot/config.txt
add_to_config 'dtoverlay=spi1-1cs'
add_to_config 'dtoverlay=mcp2515-can2,oscillator=16000000,interrupt=10'

# ADC related configuration
echo -e '\n# ADC related' >> /boot/config.txt
add_to_config 'dtoverlay=mcp342x,mcp3424'

# camera and display related configuration
echo -e '\n# Camera/Display related' >> /boot/config.txt
add_to_config 'start_x=1'
add_to_config 'gpu_mem=128'

# comment out RTC driver if exists
sed -i 's/^.*pcf85063.*$/#&/' /boot/config.txt

# install pgnano
if [ $ERR -eq 0 ]; then
  echo '>>> Install pgnano'
  if [ -f 'pgnano/PiGearNanao.sh' ]; then
    echo 'Seems pgnano is installed already, skip this step.'
  else
    wget https://www.uugear.com/repo/PiGearNano/LATEST -O pgnano.zip || ((ERR++))
    unzip pgnano.zip -d pgnano || ((ERR++))
    cd pgnano
    chmod +x PiGearNano.sh
    chmod +x daemon.sh
    chmod +x watchdog.sh
    
    sed -e "s#/home/pi/pgnano#$DIR#g" init.sh >/etc/init.d/pgnano
    chmod +x /etc/init.d/pgnano
    update-rc.d pgnano defaults || ((ERR++))
	  
	  mkdir -p 'logs'
    touch 'logs/pgnano.log'
    touch 'logs/watchdog.log'
    
    # Restore these 3 lines only when you have DSI display connected
    #cp bin/dt-blob.bin /boot/dt-blob.bin
    #chown root:root /boot/dt-blob.bin
    #chmod 755 /boot/dt-blob.bin
    
    cp bin/mcp2515-can2.dtbo /boot/overlays/mcp2515-can2.dtbo
    chown root:root /boot/overlays/mcp2515-can2.dtbo
    chmod 755 /boot/overlays/mcp2515-can2.dtbo
    
    cd ..
    if [ $SUDO_USER ]; then
      chown -R $SUDO_USER:$(id -g -n $SUDO_USER) pgnano || ((ERR++))
    else
	  chown -R $USER:$(id -g -n $USER) pgnano || ((ERR++))
    fi
    sleep 2
    rm pgnano.zip
  fi
fi

# install UUGear Web Interface
curl https://www.uugear.com/repo/UWI/installUWI.sh | bash

echo
if [ $ERR -eq 0 ]; then
  echo '>>> All done. Please reboot your Pi :-)'
else
  echo '>>> Something went wrong. Please check the messages above :-('
fi
