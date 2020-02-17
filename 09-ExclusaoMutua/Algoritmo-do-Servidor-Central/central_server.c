#include <string.h>
#include <unistd.h>
#include <stdio.h>
#include <netdb.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <stdlib.h>
#include <pthread.h>
#include <fcntl.h>
#include "LDDE/LDDE_publico.h"

#define SUCCESS 1
#define FAIL 0
#define N 5

void *newclient(void *);
static int connFd;
pthread_mutex_t mutex;
pLDDE lista_de_pedidos;

// **********************************************************
int bind_connection (int *listenFd, int portNo, pthread_t *threadA){
  struct sockaddr_in svrAdd, clntAdd;
  socklen_t len;

  //create socket
  *listenFd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);

  if(*listenFd < 0){
    printf ("\n\t\t########\tCannot open socket (%d)\n\t\t########\t",getpid());
    return FAIL;
  }

  bzero((char*) &svrAdd, sizeof(svrAdd));
  svrAdd.sin_family = AF_INET;
  svrAdd.sin_addr.s_addr = INADDR_ANY;
  svrAdd.sin_port = htons(portNo);

  if(bind(*listenFd, (struct sockaddr *)&svrAdd, sizeof(svrAdd)) < 0) {
    printf ("\n\t\t########\tCannot bind %d\n\t\t########\t\n",getpid());
    return FAIL;
  }
  listen(*listenFd, 5);

  return SUCCESS;
}

// **********************************************************
int accept_connection (int listenFd, int portNo, pthread_t *threadA){
  struct sockaddr_in svrAdd, clntAdd;
  socklen_t len;

  len = sizeof(clntAdd);

  //socklen_t len = sizeof(clntAdd);
  printf ("[%ld] Listening (%d)\n", (long) pthread_self(), getpid());
  connFd = accept(listenFd, (struct sockaddr *)&clntAdd, &len);
  if (connFd < 0) {
    printf ("\n\t\t########\tCannot accept connection (%d)\n\t\t########\t\n", getpid());
    return FAIL;
  } else
    printf ("Connection successful (%d)\n", getpid());
  if (!pthread_create(threadA, NULL, newclient, (void*) &connFd)) {
    printf ("Thread created successfully (%d)\n", getpid());
    return SUCCESS;
  } else {
    printf ("\n\t\t########\tCreation of thread failed (%d)\n\t\t########\t\n", getpid());
    return FAIL;
  }
}

// **********************************************************
// Thread procurada está na lista?
// Resposta: SUCCESS(SIM) e FAIL (NAO);
int inlist (long wanted) {
  long busca=0;

  pthread_mutex_lock(&mutex);
  for (int i=1; i <= N; i++) {
    if (buscaPosicao(lista_de_pedidos, i, &busca) == FAIL) {
      pthread_mutex_unlock(&mutex);
      return FAIL;
    }
    else if (busca == wanted) {
      pthread_mutex_unlock(&mutex);
      return SUCCESS;
    }
  }
}

// **********************************************************
// Imprime todos os elementos da Lista
int print_alllist (long myid, char *str) {
  long wanted=0;

  printf("\t\t\t\tPRINT_ALLList:%s (%ld)\n", str, myid);
  fflush(stdout);
  for (int i=1; i <= N; i++){
    if (buscaPosicao(lista_de_pedidos, i, &wanted) == FAIL){
      if (i==1) {
        printf("\t\t\t\tList[%d]: Empty List %ld!\n", i, myid);
      }
      return FAIL;
    } else {
      printf("\t\t\t\tList[%d]: %ld\n", i, wanted);
      fflush(stdout);
    }
  }
  return SUCCESS;
}

// **********************************************************
// Thread myid solicita TOKEN
int get_token(long myid, int sock){
  int fila_ok=0;
  int mytoken=0;
  long tokenId=0;
  char stoken[5];

  if (inlist (myid) == FAIL) {
    // myid não estava na lista
    pthread_mutex_lock(&mutex);
    if (!insereFim(lista_de_pedidos, &myid))
      printf("\n\t\t########\tInserting ERROR\t\t########\t\n");
    //print_alllist(myid,"GET_TOKEN (INSERT)");
    pthread_mutex_unlock(&mutex);
    printf("%ld inserted into token request list.\n",myid);
    fflush(stdout);
  }

  pthread_mutex_lock(&mutex);
  //print_alllist(myid,"GET_TOKEN (GET)");
  buscaInicio(lista_de_pedidos, &tokenId);
  pthread_mutex_unlock(&mutex);
  if (myid == tokenId) {
    printf("%ld got token and is processing it.\n",myid);
    bzero(stoken, 5);
    sprintf(stoken,"TOKEN");
    //write(sock,&stoken,5);
    send(sock, stoken , strlen(stoken), 0);
    printf("%ld Token sent %s.\n",(long) pthread_self(),stoken);
    //sleep(10);
  } else {
    printf("\t\t########\t%ld is waiting token and token is with [%ld]\t\t########\t\n", myid, tokenId);
    //print_alllist(myid,"Waiting TOKEN");
    sleep(1);
    //printf("%ld aguardando token (%ld)\n", myid, tokenId);
    get_token((long) pthread_self(), sock);
  }
}

// **********************************************************
// Thread myid libera o token.
int free_token (long myid, int sock) {
  char send[10];

  printf("%ld FREE_TOKEN (%ld)\n",(long) pthread_self(),(long) pthread_self());
  fflush(stdout);
  //print_alllist(myid,"ANTES: FREE_TOKEN");
  pthread_mutex_lock(&mutex);
  if (!removeInicio(lista_de_pedidos, &myid))
    printf("\n\t\t########\tError deleting list!\t\t########\t\n");
  fflush(stdout);
  //sleep(5);
  //print_alllist(myid,"DEPOIS: FREE_TOKEN");
  pthread_mutex_unlock(&mutex);
}

// **********************************************************
// Lança thread para atendimento especializado de cliente
void *newclient (void *socket_desc) {
  char recvbuf[10];
  int sock = *(int*)socket_desc;
  int retread=0;

  printf ("Thread No: %ld\n", (long) pthread_self());
  while(1) {
    bzero(recvbuf, 10);
    retread = read(sock, recvbuf, 10);
    if (retread) {
      printf("%ld received msg[%s]\n", (long) pthread_self(), recvbuf);
      fflush(stdout);
      sleep(1);

      if(!strcmp(recvbuf,"GET__TOKEN")) {
        //printf("\t\t\t\tGET__TOKEN\n");
        //fflush(stdout);
        get_token ((long) pthread_self(),sock);
      }

      if(!strcmp(recvbuf,"FREE_TOKEN")) {
        //printf("\t\t\t\tFREE_TOKEN\n");
        //fflush(stdout);
        free_token ((long) pthread_self(),sock);
      }

      if(!strcmp(recvbuf,"EXIT_TOKEN")) {
        //print_alllist((long) pthread_self(),"EXIT_TOKEN");
        printf ("\nClosing thread[%ld] and conn.\n", (long) pthread_self());
        fflush(stdout);
        return NULL;
      }
    } else {
      printf("\n\t\t########\t[%ld] receive ERROR [%d]\t\t########\t\n", (long) pthread_self(), retread);
      fflush(stdout);
      return NULL;
    }
  }
}

// **********************************************************
// Processo principal
int main(int argc, char* argv[])
{
  int portNo, listenFd;
  socklen_t len;
  int loop = 0;
  struct sockaddr_in svrAdd, clntAdd;
  int noThread = 0;
  pthread_t threadA[N];

  if (argc < 2) {
    printf ("\n\t\t########\tSyntaxe : ./server <port>\n\t\t########\t");
    return 0;
  }

  portNo = atoi(argv[1]);
  if((portNo > 65535) || (portNo < 2000)) {
    printf ("\n\t\t########\tPlease enter a port number between 2000 - 65535\n\t\t########\t");
    return 0;
  }

  if(!criaLDDE(&lista_de_pedidos, sizeof(long))){
    printf("\n\t\t########\tError creating list..\n\t\t########\t\n");
    exit(1);
  }

  if (bind_connection (&listenFd,portNo, &threadA[noThread]) == FAIL)
    printf("\n\t\t########\tConnection ERROR (%d)\n###########\n",getpid());

  while (noThread < N) {
    if (accept_connection (listenFd,portNo, &threadA[noThread]) == FAIL)
      printf("\n\t\t########\tConnection ERROR (%d)\n\t\t########\t\n",noThread);
    noThread++;
  }

  for(int i = 0; i < N; i++) {
    pthread_join(threadA[i], NULL);
    printf ("Finish (%d)...\n",i);
  }

  close(connFd);

  if(!destroiLDDE(&lista_de_pedidos)){
    printf("\n\t\t########\tError deleting list..\n\t\t########\t\n");
    exit(1);
  }
}
