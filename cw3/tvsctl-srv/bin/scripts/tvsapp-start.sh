#!/bin/bash

if [ $UID != 0 ] ; then
	echo "Need superuser permissions."
	exit 1
fi


NGINX_CONF="/etc/nginx/sites-available/tvsapp"
UPSTREAM_STR="upstream tvsapp"
PORT_REGEX="server 127\.0\.0\.1:([0123456789]+);"

#start all web app instances
in_upstream=0
while read line; do
	if [[ $line =~ $UPSTREAM_STR ]]; then
		in_upstream=1
		continue
	fi
	if [[ $in_upstream == 1 ]]; then
		if [[ $line =~ $PORT_REGEX ]]; then
			PORT=${BASH_REMATCH[1]}
			systemctl start tvsapp@$PORT
		else
			if [[ $line == "}" ]]; then
				in_upstream=0
			fi
		fi
		continue
	fi
done < $NGINX_CONF

#Enable configuration
ln -s $NGINX_CONF /etc/nginx/sites-enabled/tvsapp

#Tell ngix to re-read config
PS_OUTPUT=$(ps -A -o pid,command | grep "nginx: master" | grep -v "grep")
PID_REGEX="([0123456789]+).*nginx"

if [[ $PS_OUTPUT =~ $PID_REGEX ]]; then
	PID=${BASH_REMATCH[1]}
	kill -s HUP $PID
fi

#Start elastic search
systemctl start elasticsearch
