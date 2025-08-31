#!/bin/bash

if [ $UID != 0 ]; then
	echo "Need to execute as superuser"
	exit 1
fi

if [ ! -z "$1" ]; then
	scale=$1
fi
scale=${scale:=1}

if [ ! -z "$2" ]; then
	base=$2
fi
base=${base:=35000}

UPSTREAM_STR="upstream tvsapp"
NGINX_CONF="/etc/nginx/sites-available/tvsapp"
TMP_FILE="./tmp"
touch $TMP_FILE

in_upstream=0
while IFS=$'\n' read -r line; do
	if [[ $in_upstream == 0 && $line =~ $UPSTREAM_STR ]]; then
		echo "$UPSTREAM_STR {"
		counter=0
		while [[ $counter < $scale ]]; do
			PORT=$(( $base + $counter ))
			echo -e "\tserver 127.0.0.1:$PORT;"
			counter=$(( $counter + 1))
		done
		echo "}"
		in_upstream=1
		continue
	fi

	if [[ $in_upstream == 1 ]]; then
		if [[ $line == "}" ]]; then
			in_upstream=0
		fi
		continue
	fi
	echo "$line"
done < $NGINX_CONF > $TMP_FILE

mv $TMP_FILE $NGINX_CONF
