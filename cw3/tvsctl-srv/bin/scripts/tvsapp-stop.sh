#!/bin/bash

if [ $UID != 0 ]; then
	echo "Need superuser privilages."
	exit 1
fi

if [ $# == 1 ]; then
	if [ $1 != "-db" ]; then
		echo "invalid argument"
		exit 1
	else
		systemctl stop elasticsearch
	fi
fi

systemctl stop tvsapp@*
rm /etc/nginx/sites-enabled/tvsapp

#Tell ngix to re-read config
PS_OUTPUT=$(ps -A -o pid,command | grep "nginx: master" | grep -v "grep")
PID_REGEX="([0123456789]+).*nginx"

if [[ $PS_OUTPUT =~ $PID_REGEX ]]; then
	PID=${BASH_REMATCH[1]}
	kill -s HUP $PID
fi
