#include "lamport.h"

// Implementação do comportamento descrito no gráfico para Processo P0
int processP0(int pid) {
  char MSG[512];
  int step = 6;
  int myclock = -6;

  printf("[P0] (%d) process run!\n", pid);
  // Execução do evento 01-P0
  myclock = exec("[P0]",pid,myclock,step);

  strcpy(MSG,"MENSAGEM_A");
  // Envio da MENSAGEM_A de P0 p/ P1
  myclock = sendMSG(portA,"localhost", MSG, myclock, step);
  printf("[P0][%d] MSG(%s) sended from P0 to P1\n", myclock,MSG);

  for (int i=0; i <7; i++) {
    // Execução dos eventos 03 à 09 de P0
    myclock = exec("[P0]",pid,myclock,step);
  }

  // Aguarda a MENSAGEM_D gerada por P1
  myclock = recvMSG(portD,MSG, myclock, step);
  printf("\n[P0][%d] MSG(%s) received in P0 from P1", myclock, MSG);

  // Execução do evento 11-P0
  myclock = exec("[P0]",pid,myclock,step);

  printf("#####\t\t[P0][%d] (%d) process finish!!\t\t#####\n", myclock, pid);
  return 0;
}
