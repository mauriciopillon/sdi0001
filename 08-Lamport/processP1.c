#include "lamport.h"

// Implementação do comportamento descrito no gráfico para Processo P1
int processP1(int pid) {
  char MSG[512];
  int step = 8;
  int myclock = -8;

  printf("[P1] (%d) process run!\n", pid);
  myclock = exec("[P1]",pid,myclock,step);
  myclock = exec("[P1]",pid,myclock,step);

  myclock = recvMSG(portA,MSG, myclock, step);
  printf("[P1][%d] MSG(%s) received in P1 from P0\n", myclock, MSG);

  strcpy(MSG,"MENSAGEM_B");
  myclock = sendMSG(portB,"localhost", MSG, myclock, step);
  printf("[P1][%d] MSG(%s) sended from P1 to P2\n", myclock, MSG);

  myclock = exec("[P1]",pid,myclock,step);
  myclock = exec("[P1]",pid,myclock,step);
  myclock = exec("[P1]",pid,myclock,step);

  myclock = recvMSG(portC,MSG, myclock, step);
  printf("[P1][%d] MSG(%s) received in P1 from P2\n", myclock, MSG);

  strcpy(MSG,"MENSAGEM_D");
  myclock = sendMSG(portD,"localhost", MSG, myclock, step);
  printf("[P1][%d] MSG(%s) sended from P1 to P2\n", myclock, MSG);

  myclock = exec("[P1]",pid,myclock,step);
  myclock = exec("[P1]",pid,myclock,step);
  printf("#####\t\t[P1][%d] (%d) process finish!!\t\t#####\n", myclock, pid);
  return 0;
}
