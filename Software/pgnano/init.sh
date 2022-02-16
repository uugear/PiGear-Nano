#!/bin/bash
# /etc/init.d/pgnano

### BEGIN INIT INFO
# Provides:          pgnano
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: PiGear Nano initialize script
# Description:       This service is used to manage PiGear Nano service
### END INIT INFO

case "$1" in
    start)
        echo "Starting PiGear Nano Daemon..."
        /home/pi/pgnano/daemon.sh &
	sleep 1
	daemonPid=$(ps --ppid $! -o pid=)
	echo $daemonPid > /var/run/pgnano_daemon.pid
        ;;
    stop)
        echo "Stopping PiGear Nano Daemon..."
	daemonPid=$(cat /var/run/pgnano_daemon.pid)
	kill -9 $daemonPid
        ;;
    *)
        echo "Usage: /etc/init.d/pgnano start|stop"
        exit 1
        ;;
esac

exit 0
