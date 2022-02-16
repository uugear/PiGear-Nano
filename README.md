# PiGear-Nano

PiGear Nano is a high performance Nano–ITX (12x12cm) carrier board for Raspberry Pi Compute Module 4.

![PiGear Nano](https://www.uugear.com/wordpress/wp-content/uploads/2021/11/01-600x600.jpg)

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
