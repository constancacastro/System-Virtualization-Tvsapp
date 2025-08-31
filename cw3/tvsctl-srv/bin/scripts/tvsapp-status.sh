#!/bin/bash

oldIFS=$IFS
IFS="
"

#Nginx status
PS_NGINX=$(ps ax -o pid,command | grep nginx)
WORKER_REGEX=".*worker.*"
MASTER_REGEX="([0123456789]+).*master process"

MASTER_PID=0
count=0
for line in $PS_NGINX; do
	#echo "line: $line"
	if [[ $line =~ $WORKER_REGEX ]]; then
		count=$(( $count + 1 ))
	elif [[ $line =~ $MASTER_REGEX ]]; then
		MASTER_PID=${BASH_REMATCH[1]}
	fi
done
if [[ $count != 0 ]];then
	echo "NGINX: There are $count worker processes; master has PID=$MASTER_PID"
else
	echo "NGINX: nginx is not running."
fi
#Webapp status
WEBAPP_REGEX="Started tvsapp@([0123456789]+).service"
WEBAPP_STATUS=$(systemctl status tvsapp@* | egrep $WEBAPP_REGEX)

LARGEST_PORT=0
SMALLEST_PORT=99999
webapp_count=0
for line in $WEBAPP_STATUS; do
	if [[ $line =~ $WEBAPP_REGEX ]]; then

		PORT=${BASH_REMATCH[1]}
		if [[ $PORT -gt $LARGEST_PORT ]]; then
			LARGEST_PORT=$PORT
		fi
		if [[ $PORT -lt $SMALLEST_PORT ]]; then
			SMALLEST_PORT=$PORT
		fi
		webapp_count=$(( $webapp_count + 1))
	fi
done
if [[ $webapp_count == 0 ]]; then
	echo "TVSAPP: No instances running."
elif [[ $webapp_count == 1 ]]; then
	echo "TVSAPP: There is one tvsapp instance running in port $SMALLEST_PORT."
else
	echo "TVSAPP: There are $webapp_count tvsapp instances running in ports [$SMALLEST_PORT : $LARGEST_PORT]"
fi

#db status
DB_STATUS=$(systemctl status elasticsearch)
DB_ACTIVE_REGEX="Active: active \(running\) (.+ ago)"
DB_STATUS_REGEX="Active: (.+ \(.+\))"
if [[ $DB_STATUS =~ $DB_ACTIVE_REGEX ]]; then
	SINCE=${BASH_REMATCH[1]}
	echo "Elasticsearch is active and running $SINCE."
elif [[ $DB_STATUS =~ $DB_STATUS_REGEX ]]; then
	STATUS=${BASH_REMATCH[1]}
	echo "Elasticsearch status is $STATUS."
else
	echo "No elasticsearch service was found."
fi

IFS=$oldIFS
