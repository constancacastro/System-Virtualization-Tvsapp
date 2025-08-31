
CLI_DIR = tvsctl-cli
SRV_DIR = tvsctl-srv

all:
	mkdir -p $(SRV_DIR)/bin
	mkdir -p $(CLI_DIR)/bin
	gcc -o $(SRV_DIR)/bin/tvsctld $(SRV_DIR)/src/*.c -lsystemd
	gcc -o $(CLI_DIR)/bin/tvsctl $(CLI_DIR)/src/*.c

install:
	sudo ./install-all.sh
