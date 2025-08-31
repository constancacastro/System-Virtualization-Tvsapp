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
LARGEST_PORT=0
while IFS= read -r line; do
	if [[ $in_upstream == 0 && $line =~ $UPSTREAM_STR ]]; then
		echo "$UPSTREAM_STR {"
		in_upstream=1
		continue
	fi

	if [[ $in_upstream == 1 ]]; then
		if [[ $line =~ $REGEX_PORT ]]; then
			echo "$line"
			PORT=${BASH_REMATCH[1]}
			if [[ $PORT > $LARGEST_PORT ]]; then
				LARGEST_PORT=$PORT
			fi
		else
			if [[ $line == "}" ]]; then
				in_upstream=0
				counter=1
				while [[ $counter -le $DELTA ]]; do
					NEW_PORT=$(( $LARGEST_PORT + $counter ))
					echo -e "\tserver 127.0.0.1:$NEW_PORT;"
					if [[ $RUNNING == 1 ]]; then
						systemctl start tvsapp@$NEW_PORT
					fi
					counter=$(( $counter + 1))
				done
				echo "}"
			fi
		fi
		continue
	fi
	echo "$line"
done < $NGINX_CONF_FILE > $TMP_FILE

mv $TMP_FILE $NGINX_CONF_FILE
