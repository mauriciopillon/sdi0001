#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <stdlib.h>
#include <stdio.h>
#include "lamport.h"

//##############
int exec(char *name, int pid, int cclock1, int step){
  return 0;
}

//##############
char *buildMSG (char *MSG, int currentclock) {
  return MSG;
}

//##############
int clockMSG (char *MSG) {
  return 0;
}

//##############
int max (int clock_event1, int clock_event2, int step){
  return 0;
}

//##############
int Uclock (int clock_event1, int step){
  return 0;
}

//##############
void error(char *msg)
{
    perror(msg);
    exit(0);
}

//##############
int recvMSG(int port, char *MSG, int myclock, int step) {
  int sockfd, n;
  struct sockaddr_in serv_addr;
  struct hostent *server;
  int flag=0;
  char recvchar[512] = "zzz";

  sockfd = socket(AF_INET, SOCK_STREAM, 0);
  if (sockfd < 0)
      error("ERROR opening socket");
  server = gethostbyname("localhost");
  if (server == NULL) {
      fprintf(stderr,"ERROR, no such host\n");
      exit(0);
  }
  bzero((char *) &serv_addr, sizeof(serv_addr));
  serv_addr.sin_family = AF_INET;
  bcopy((char *)server->h_addr,
     (char *)&serv_addr.sin_addr.s_addr,
     server->h_length);
  serv_addr.sin_port = htons(port);
  while (flag < 5) {
    if (connect(sockfd,(SOCKADDR *)&serv_addr,sizeof(serv_addr)) < 0) {
        printf("RECV[%d] waiting in port (%d).\n", myclock, port);
        sleep(1);
        flag++;
    } else
      flag = 10;
  }

  n = read(sockfd,recvchar,512);
  if (n < 0)
     error("ERROR reading from socket");
  memcpy (MSG, recvchar, sizeof(recvchar));
  myclock = max(myclock,clockMSG(recvchar),step);
  //printf("RECV[%d][%d](%s)\n", myclock, clockMSG(recvchar), MSG);
  return Uclock(myclock,step);
}

//##############
int sendMSG(int port, char *host, char *MSG, int cclock1, int step) {
  int sockfd, newsockfd;
  socklen_t clilen;
  struct sockaddr_in serv_addr, cli_addr;
  int n;
  char sendchar[512] = "A";

  sockfd = socket(AF_INET, SOCK_STREAM, 0);
  if (sockfd < 0)
    error("ERROR opening socket");
  bzero((char *) &serv_addr, sizeof(serv_addr));
  serv_addr.sin_family = AF_INET;
  serv_addr.sin_addr.s_addr = INADDR_ANY;
  serv_addr.sin_port = htons(port);

  if (bind(sockfd, (struct sockaddr *) &serv_addr,sizeof(serv_addr)) < 0) {
    error("ERROR on binding");
  }

  listen(sockfd,5);
  clilen = sizeof(cli_addr);
  newsockfd = accept(sockfd, (struct sockaddr *) &cli_addr, &clilen);
  if (newsockfd < 0)
     error("ERROR on accept");
  cclock1 = Uclock(cclock1,step);
  memcpy(sendchar, buildMSG(MSG,cclock1), sizeof(sendchar));
  //printf("SEND[%d]:(%s)\n", cclock1,MSG);
  n = write(newsockfd,sendchar,512);
  if (n < 0) error("ERROR writing to socket");
  return cclock1;
}
