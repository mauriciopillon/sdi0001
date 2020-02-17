#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>

// Constantes c/ nro de portas (uma por mensagem)
#define portA 8996
#define portB 8997
#define portC 8998
#define portD 8999

typedef struct sockaddr SOCKADDR;

// Função que executa um evento
// Recebe: nome do processo, hora lógica atual e passo de incremento da hora.
// Retorna o tempo após a execução do evento.
int exec(char *name, int pid, int cclock1, int step);

// Função que contrói mensagem
// Recebe: mensagem e a hora atual
// Retorna a mensagem concatenada <MSG:currentclock>
char *buildMSG (char *MSG, int currentclock);

// Função que avança o relógio lógico
// Recebe: hora atual e passo de incremento da hora.
int Uclock (int clock_event1, int step);

// Função que extrai a hora de uma mensagem do relógio de lamport
// Recebe a mensagem no formato <MSG:currentclock>
// Retorna o inteiro correspondente a currentclock.
int clockMSG (char *MSG);

// Interface das funções de envio/recebimento de mensagens
int recvMSG(int port, char *MSG, int myclock, int step);
int sendMSG(int port, char *host, char *MSG, int cclock1, int step);
