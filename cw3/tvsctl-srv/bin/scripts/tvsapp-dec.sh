#!/bin/bash

if [ $UID != 0 ]; then
	echo "Requires superuser permissions."
	exit 1
fi

if [ ! -z "$1" ]; then
	DELTA=$1
fi
DELTA=${DELTA:=1}

#Check if it's running
RUNNING_CMD=$(systemctl status tvsapp@*)
RUNNING=1
if [[ "$RUNNING_CMD" == "" ]]; then
	RUNNING=0
fi

NGINX_CONF_FILE="/etc/nginx/sites-available/tvsapp"
UPSTREAM_STR="upstream tvsapp"
REGEX_PORT="server 127\.0\.0\.1:([0123456789]+);"
TMP_FILE="./tmp"

in_upstream=0
SMALLEST_PORT=0
TOTAL_PORTS=0
while IFS= read -r line; do
	if [[ $in_upstream == 0 && $line =~ $UPSTREAM_STR ]]; then
		echo "$UPSTREAM_STR {"
		in_upstream=1
		continue
	fi

	if [[ $in_upstream == 1 ]]; then
		if [[ $line =~ $REGEX_PORT ]]; then
			TOTAL_PORTS=$(( $TOTAL_PORTS + 1))
			PORT=${BASH_REMATCH[1]}
			if [[ $PORT < $SMALLEST_PORT || $SMALLEST_PORT == 0 ]]; then
				SMALLEST_PORT=$PORT
			fi
		elif [[ $line == "}" ]]; then
			in_upstream=0

			NEW_TOTAL=$(( $TOTAL_PORTS - $DELTA ))
			if [[ $NEW_TOTAL -le 0 ]]; then
				NEW_TOTAL=1
			fi

			counter=0
			while [[ $counter -lt $NEW_TOTAL ]]; do
				NEW_PORT=$(( $SMALLEST_PORT + $counter ))
				echo -e "\tserver 127.0.0.1:$NEW_PORT;"
				counter=$(( $counter + 1))
			done
			if [[ $RUNNING == 1 ]]; then
				while [[ $counter -lt $TOTAL_PORTS ]]; do
					OLD_PORT=$(( $SMALLEST_PORT + $counter ))
					systemctl stop tvsapp@$OLD_PORT
					counter=$(( $counter + 1))
				done
			fi
			echo "}"
		fi
		continue
	fi
	echo "$line"
done < $NGINX_CONF_FILE > $TMP_FILE

mv $TMP_FILE $NGINX_CONF_FILE
