#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <sys/un.h> //n
#include <sys/stat.h> //n
#include <sys/socket.h>
#include <stdlib.h> //n
#include <fcntl.h> //n

#define SOCKET_PATH "/run/isel/tvs/request/tvsctld.sock"

// Function to create a Unix domain socket connection
int create_connection() {
    struct sockaddr_un addr;
    int sockfd;

    // Create the socket
    sockfd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (sockfd == -1) {
        perror("socket");
        exit(EXIT_FAILURE);
    }

    // Set the socket address structure
    memset(&addr, 0, sizeof(struct sockaddr_un));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, SOCKET_PATH, sizeof(addr.sun_path) - 1);

    // Connect to the socket
    if (connect(sockfd, (struct sockaddr*)&addr, sizeof(struct sockaddr_un)) == -1) {
        perror("connect");
        close(sockfd);
        exit(EXIT_FAILURE);
    }

    return sockfd;
}

int wait_for_ak(int cli_sock){
	char buffer[2];
	ssize_t len = recv(cli_sock, buffer, 2, 0);
	if(len == -1 ||  buffer[0] != 'A' || buffer[1] != 'K' ){
		return -1;
	}
	return 0;
}

int main(int argc, const char * argv[]) {
	// These must always be the first instructions. DON'T EDIT
	close(0); open("/dev/null", O_RDONLY);       // DON'T EDIT

	// TO DO
	if (argc < 2){
		printf("Missing arguments: please indicate which operation to perform.\n");
		exit(EXIT_FAILURE);
	}else if(argc > 128){
		printf("Too mny arguments\n");
		exit(EXIT_FAILURE);
	}

	int cli_sock = create_connection();
	int msg_to_send = argc-1;
	
	//Tell server how many messages to expect
	char count = (char)msg_to_send;
	int ret = send(cli_sock, &count, sizeof(char), 0);
 	if(ret == -1){
		perror("send msg count");
		close(cli_sock);
		exit(EXIT_FAILURE);
	}

	if( wait_for_ak(cli_sock) == -1){
		perror("Aknowledge");
		close(cli_sock);
		exit(EXIT_FAILURE);
	}

	//Send all messages
	for(int i=1; i<=msg_to_send; i++){
		const char* message = argv[i];
		int ret = send(cli_sock, message, strlen(message), 0);
		if(ret == -1){
			printf("Error sending message at index %d\n!", i);
			close(cli_sock);
			exit(EXIT_FAILURE);
		}
		if( wait_for_ak(cli_sock) == -1 ){
			perror("Aknowledge");
			close(cli_sock);
			exit(EXIT_FAILURE);
		}
	}

    printf("Messages sent to the service.\n");

    // Receive a response from the service
    char buffer[256];
	int idx = 0;
	while (idx<255) {
		ssize_t len = recv(cli_sock, &buffer[idx], sizeof(buffer)-1-idx, 0);
		idx+=len;
		if (len == -1) {
			perror("recv");
			close(cli_sock);
			exit(EXIT_FAILURE);
		}else if(len == 0) {
			break;
		}

		//buffer[idx] = '\0';
    	//printf("Received %ld bytes from service: %s\n", len, buffer);
	}
	if(idx != 0){
		buffer[idx] = '\0';  // Null-terminate the received data
		printf("%s", buffer);
	}
	 
    // Close the socket connection
    close(cli_sock);

    return 0;
}
