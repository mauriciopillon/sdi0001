
#include <string.h>
#include <unistd.h>
#include <stdio.h>
#include <netdb.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <strings.h>
#include <stdlib.h>
#include <time.h>
#include <sys/wait.h>

#define N 5 // número de clientes
#define Nmsg 5 // número de mensagens

// **********************************************************
// Solicita token p/ servidor central
int request_token (int listenFd) {
  char recvbuf[5];
  char sendbuf[10];

  //sprintf(msg,"SOLICITA_TOKEN(%d)(%d:%d)",getpid(),i,myrand);
  bzero(sendbuf, 10);
  sprintf(sendbuf,"GET__TOKEN");
  printf("[%d] sends message[%s].\n",getpid(),sendbuf);
  fflush(stdout);
  //write(listenFd, &sendbuf, strlen(sendbuf));
  send(listenFd, sendbuf, strlen(sendbuf), 0);
  bzero(recvbuf, 5);
  recvfrom(listenFd, recvbuf, 5, 0, NULL, NULL);
  printf("[%d] receives TOKEN_CONCEDIDO[%s].\n",getpid(),recvbuf);
  fflush(stdout);
}

// **********************************************************
// Libera token
int free_token (int listenFd) {
  char free[10];

  bzero(free, 10);
  // printf("%s\n",free);
  // fflush(stdout);
  sprintf(free,"FREE_TOKEN");
  printf("[%d] sends message[%s]\n",getpid(),free);
  fflush(stdout);
  write(listenFd, &free, strlen(free));
  //send(listenFd, sendbuf, strlen(sendbuf), 0);
}

// **********************************************************
// Comunica término da coenxão.
int close_client (int listenFd) {
  char exit[10];

  bzero(exit, 10);
  strcpy(exit,"EXIT_TOKEN");
  printf("[%d] sends message[%s]\n",getpid(),exit);
  write(listenFd, &exit, strlen(exit));
}

// **********************************************************
// Núcleo de execução (send/receive message)
int kernel_run (int listenFd) {
  int myrand=0;

  for(int i=0;i<Nmsg;i++) {
    request_token(listenFd);
    myrand = rand()%3;
    printf("[%d] running block %d (processing time is %d).\n", getpid(), i, myrand);
    sleep(myrand);
    free_token (listenFd);
  }
  close_client (listenFd);
  return 0;
}

// **********************************************************
// Conexão socket c/ servidor
int exec_process(int portNo, char *hostname) {
  int listenFd;
  struct sockaddr_in svrAdd;
  struct hostent *server;

  printf("Running(%d): port (%d) hostname [%s]\n", getpid(),portNo, hostname);
  //create client skt
  listenFd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);

  if(listenFd < 0){
    printf ("Cannot open socket");
    return 0;
  }

  server = gethostbyname(hostname);
  if(server == NULL){
    printf ("Host does not exist");
    return 0;
  }

  bzero((char *) &svrAdd, sizeof(svrAdd));
  svrAdd.sin_family = AF_INET;

  bcopy((char *) server -> h_addr, (char *) &svrAdd.sin_addr.s_addr, server -> h_length);
  svrAdd.sin_port = htons(portNo);
  int checker = connect(listenFd,(struct sockaddr *) &svrAdd, sizeof(svrAdd));

  if (checker < 0){
    printf ("Cannot connect!\n");
    return 0;
  }

  kernel_run(listenFd);
  return 0;
}

// **********************************************************
int main (int argc, char* argv[])
{
  int portNo=0;
  pid_t pid[N];
  int childExitStatus;

  if(argc < 3) {
    printf ("Syntax : ./client <host name> <port>");
    return 0;
  }

  portNo = atoi(argv[2]);
  if((portNo > 65535) || (portNo < 2000)) {
    printf ("Please enter port number between 2000 - 65535");
    return 0;
  }

  int master = getpid();
  for (int i=0; i < N; i++) {
    if (master==getpid()) {
      pid[i] = fork();
      if (!pid[i]) {
        sleep(i+i);
        exec_process(portNo,argv[1]);
        //printf("[Novo]Eu:%d Pai:%d Filho:%d\n", getpid(), getppid(), pid[2]);
      } else
      printf("Process[%d] starts client[%d].\n", getpid(),pid[i]);
    }
  }

  for (int i=0; i < N; i++)
    if (master==getpid()) {
      waitpid( pid[i], &childExitStatus, 0);
    }
  printf("Finish(%d)\n",getpid());
  return 0;
}
