#include "lamport.h"
#include "processP0.h"
#include "processP1.h"
#include "processP2.h"

// Programa principal que cria três processos que executam em paralelo.
int main(int argc, char const *argv[]) {
  pid_t pidP1, pidP2;
  int childExitStatus;

  // Criação do Processo P2
  pidP2 = fork();
  if (pidP2)
    processP2(pidP2); // Somente Processo P2 executa está linha.
  else {
    // Criação do Processo P1
    pidP1 = fork();
    if (pidP1)
      processP1(pidP1); // Somente Processo P1 executa está linha.
    else {
      // Processo P0 utilizo processo principal
      processP0(getpid()); // Somente Processo P0 executa está linha.
    }
  }

  // Processo principal (Processo P0) aguarda o término de P2;
  waitpid( pidP2, &childExitStatus, 0);
  // Processo principal (Processo P0) aguarda o término de P1;
  waitpid( pidP1, &childExitStatus, 0);
  return 0;
}
