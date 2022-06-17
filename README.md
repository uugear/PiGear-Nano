# PiGear-Nano

PiGear Nano is a high performance Nano–ITX (12x12cm) carrier board for Raspberry Pi Compute Module 4.

![PiGear Nano](https://www.uugear.com/wordpress/wp-content/uploads/2021/11/01-600x600.jpg)

## Specification

<table><tbody><tr><td><strong>Network</strong></td><td>Gigabit-Ethernet RJ45 socket x 1<br>MINI PCIE LTE/4G/GPRS interface x 1<br>On-board SIM card slot x 1</td></tr><tr><td><strong>USB</strong></td><td>USB 3.0 Type-A connector x 8<br>USB 2.0 Type-C connector x 1 (for flashing CM4 or powering the board)</td></tr><tr><td><strong>Analog &amp; Digital I/O</strong></td><td>18-bit ADC input x 4<br>Digital input x 4<br>Digital output x 4<br>Configurable digital I/O x 4</td></tr><tr><td><strong>Signal Interface</strong></td><td>RS232 x 2<br>RS485 x 2<br>CAN x 1<br>Wire interface x 1</td></tr><tr><td><strong>Storage</strong></td><td>NVME SSD M.2 interface x 1<br>Micro SD card slot x 1 (for Compute Module 4 Lite only)</td></tr><tr><td><strong>Display</strong></td><td>HDMI Type-A connector x 1<br>MIPI DSI interface x 1</td></tr><tr><td><strong>Camera</strong></td><td>MIPI CSI interface x 1</td></tr><tr><td><strong>Other</strong></td><td>Real-time clock x 1 (with supper capacitor for off-power time keeping)<br>Buzzer x 1<br>Power Indicator x 1<br>Programmable LED indicator x 1<br>5V fan interface (PH2.0 connector)<br>Power button x 1 (with extension connector)<br>Reset button x 1 (with extension connector)</td></tr><tr><td><strong>Power Supply</strong></td><td>DC 7V~30V (with reverse polarity protection)<br>or&nbsp; DC 5V (via USB Type-C connector)</td></tr><tr><td><strong>Quiescent Current</strong></td><td>~1mA</td></tr><tr><td><strong>Board Size and Weight</strong></td><td>NANO-ITX 12 x 12 cm,&nbsp; 150g</td></tr><tr><td><strong>Operating Environment</strong></td><td>Temperature -30°C~80°C (-22°F~176°F)<br>Humidity 0~80%RH, no condensing<br>No corrosive gas</td></tr></tbody></table>

## Software Installation

To install PiGear Nano’s software, please run this command in your home directory:

```
pi@raspberrypi ~ $ wget https://www.uugear.com/repo/PiGearNano/installPiGearNano.sh
```

If your Raspberry Pi has internet connection, it will immediately download the script from our website, and you will then see the “install.sh” script in your home directory. Then you just need to this script with with sudo:

```
pi@raspberrypi ~ $ sudo sh installPiGearNano.sh
```

You will need to use sudo to run this script because it also tries to modify the /boot/config.txt file (will make backup first). The software will be installed in the “pgnano” directory and also UUGear Web Interface (UWI) will be installed/updated to “uwi” directory.

After installing the software, you need to restart your Raspberry Pi, so the UWI server will be running in the background. With default configuration you should be able to access your PiGearNano via UWI on address http://raspberrypi:8000/pgnano/. If your Raspberry Pi does not use raspberrypi host name, or this hostname is not resolvable in your network environment, you need to modify the uwi.conf file in “uwi” directory to include the real IP address of your Raspberry Pi.

## User Manual / Documentation

You can find the user manual here: https://www.uugear.com/doc/PiGearNano_UserManual.pdf
