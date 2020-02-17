#include "lamport.h"

// Implementação do comportamento descrito no gráfico para Processo P2
int processP2(int pid) {
  char MSG[512];
  int step = 10;
  int myclock = -10;

  printf("[P2] (%d) process run!\n", pid);
  myclock = exec("[P2]",pid,myclock,step);
  myclock = exec("[P2]",pid,myclock,step);
  myclock = exec("[P2]",pid,myclock,step);
  myclock = exec("[P2]",pid,myclock,step);

  myclock = recvMSG(portB,MSG, myclock, step);
  printf("[P2][%d] MSG(%s) received in P2 from P1\n", myclock, MSG);

  myclock = exec("[P2]",pid,myclock,step);

  strcpy(MSG,"MENSAGEM_C");
  myclock = sendMSG(portC,"localhost", MSG, myclock, step);
  printf("[P2][%d] MSG(%s) sended from P2 to P1\n", myclock, MSG);

  myclock = exec("[P2]",pid,myclock,step);
  myclock = exec("[P2]",pid,myclock,step);
  myclock = exec("[P2]",pid,myclock,step);
  myclock = exec("[P2]",pid,myclock,step);
  printf("#####\t\t[P2][%d] (%d) process finish!!\t\t#####\n", myclock, pid);
  return 0;
}
