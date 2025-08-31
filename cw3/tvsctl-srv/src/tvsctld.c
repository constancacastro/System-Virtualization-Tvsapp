#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <errno.h>
#include <systemd/sd-daemon.h>

#define BASH_PATH "bash"
#define SCRIPT_PREFIX "scripts/tvsapp-"
#define SCRIPT_SUFFIX ".sh"

// Function to handle communication with the client
int get_client_con(int client_fd) {

	struct sockaddr_un cli_addr;
	socklen_t addrlen = sizeof(struct sockaddr_un);
	int cli_sock = accept(client_fd, (struct sockaddr *)  &cli_addr, &addrlen);
	if (cli_sock == -1) {
		perror("accept");
		return -1;
	}

	return cli_sock;
}

// Function to call bash and excute the script
int exec_script(int cli_sock, char* argv[]){
	
	char file_name[64];
	snprintf(file_name, sizeof(file_name), "%s%s%s", SCRIPT_PREFIX, argv[1], SCRIPT_SUFFIX);
	argv[1] = file_name;
	//printf("file_name: %s || %s\n", file_name, argv[1]);
	close(STDOUT_FILENO);
	dup(cli_sock);

	//const char* testarr[1];
	//testarr[0] = "ls";
	//testarr[1] = NULL;
	//return execvp(testarr[0], testarr);
	return execvp(argv[0], argv);
}

// Send aknowledge signal ot the client
void send_ak(int cli_sock){
	if (write(cli_sock, "AK", 2) == -1) {
        perror("write");
		close(cli_sock);
		exit(EXIT_FAILURE);
    }
}

#define MAX_MSGS 7
#define MAX_MSG_LEN 16

void communicate(int cli_sock){
	const int BUFFER_SIZE = 256;
    char buffer[BUFFER_SIZE];
    ssize_t bytes_read;

    // Get number of messages to expect
    bytes_read = read(cli_sock, buffer, sizeof(buffer) - 1);
    if (bytes_read == -1) {
        perror("read");
        close(cli_sock);
        exit(EXIT_FAILURE);
	}

    int n_msg = (int)buffer[0];
	if(n_msg < 1 || n_msg > MAX_MSGS-1){
		printf("Invalid n_msg: %d\n", n_msg);
		close(cli_sock);
		exit(EXIT_FAILURE);
	}

	printf("Expecting %d messages from client.\n", n_msg);
	send_ak(cli_sock);
	
	//Read data from the client
	char messages[MAX_MSGS][MAX_MSG_LEN];
	char* argv[MAX_MSGS];

	char* bash_str = BASH_PATH;
	argv[0] = bash_str;
	for(int i=0; i<n_msg; i++){
		bytes_read = read(cli_sock, buffer, sizeof(buffer) - 1);
		if (bytes_read == -1) {
			perror("read");
			close(cli_sock);
			exit(EXIT_FAILURE);
		}
		buffer[bytes_read] = '\0';  // Null-terminate the received data
		strcpy( /*dst*/ messages[i], /*src*/ buffer);
		argv[i+1] = messages[i];
		printf("Received %ld bytes from client: %s\n", bytes_read, messages[i]);
		send_ak(cli_sock);
	}
	argv[n_msg+1] = NULL;

	if( exec_script(cli_sock, argv) != 0 ){
		perror("exec");
		close(cli_sock);
		exit(EXIT_FAILURE);
	}

    // Respond to the client
    //const char *response = "Hello from the service!\n";
    //if (write(cli_sock, response, strlen(response)) == -1) {
    //    perror("write");
    //}

    // Close the connection
    close(cli_sock);
}

int main() {
    int client_fd;
    int num_fds;

    // Get the list of file descriptors passed by systemd
    num_fds = sd_listen_fds(0);  // 0 means to not drop the first file descriptor, it should be available at SD_LISTEN_FDS_START
    if (num_fds <= 0) {
        fprintf(stderr, "No file descriptors passed by systemd.\n");
        exit(EXIT_FAILURE);
    }

    client_fd = SD_LISTEN_FDS_START;  // Access the file descriptor passed by systemd
	if (client_fd == -1) {
		perror("Invalid socket descriptor");
		exit(EXIT_FAILURE);
	}

	printf("Handling client on file descriptor %d\n", client_fd);
	
	// Handle the client connection
    int sockfd = get_client_con(client_fd);
	if(sockfd == -1){
		exit(EXIT_FAILURE);
	}

	communicate(sockfd);
    return 0;
}

