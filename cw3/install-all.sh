#!/bin/bash

if [ $UID != 0 ] ; then
	echo "Need superuser permissions."
	exit 1
fi

#TVS service and socket
SOCKET_SRC_DIR=./tvsctl-srv/etc/service
SERVICE_SRC_DIR=$SOCKET_SRC_DIR

SYSD_DIR=/etc/systemd/system

SOCKET_NAME=tvsctld.socket
SERVICE_NAME=tvsctld.service

cp $SOCKET_SRC_DIR/$SOCKET_NAME $SYSD_DIR
cp $SERVICE_SRC_DIR/$SERVICE_NAME $SYSD_DIR

#TVSAPP service & NGINX
TVSAPP_SERVICE_SRC=./tvsapp/etc/service
TVSAPP_SERVICE=tvsapp@.service

NGINX_SRC=./tvsctl-srv/etc/nginx/sites-available
NGINX_DIR=/etc/nginx/sites-available

cp $TVSAPP_SERVICE_SRC/$TVSAPP_SERVICE $SYSD_DIR
cp $NGINX_SRC/* $NGINX_DIR

#Executables
BASE_DIR=/opt/isel/tvs

SRV_DIR=$BASE_DIR/tvsctld/bin
CLI_DIR=$BASE_DIR/tvsctl/bin
TVSAPP_DIR=$BASE_DIR/tvsapp/app

SRV_SRC=./tvsctl-srv/bin
CLI_SRC=./tvsctl-cli/bin
TVSAPP_SRC=./tvsapp/app

mkdir -p $SRV_DIR
mkdir -p $CLI_DIR
mkdir -p $TVSAPP_DIR

cp -r $SRV_SRC/* $SRV_DIR
cp -r $CLI_SRC/* $CLI_DIR
cp -r $TVSAPP_SRC/* $TVSAPP_DIR

chgrp tvsgrp $SRV_DIR/tvsctld
chgrp tvsgrp $CLI_DIR/tvsctl

systemctl daemon-reload

systemctl start $SOCKET_NAME
