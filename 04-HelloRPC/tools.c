#include <time.h>
#include <sys/time.h>
#include "tools.h"

// %%%%%%%%%%%%%%% FERRAMENTAS p/ VETORES %%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
double wtime() {
  struct timeval t;
  gettimeofday(&t, NULL);
  return t.tv_sec + (double) t.tv_usec / 1000000;
}

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
int writeline (char *msg, FILE *file){
  fprintf(file,"%s", msg);
  return 0;
}

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
char *readline (FILE *file){
  static int cont=0;
  char *getLine = NULL;
  char c;
  int linha=0;

  getLine = (char *) malloc (256*sizeof(char));
  fseek( file, cont, SEEK_SET );
  for (;;cont++) {
    c = fgetc( file );
    if ((linha == 256) || (c ==  EOF)){
      //printf ("%d(%c)\n",cont, c);
      return (getLine);
    }
    getLine[linha++] = c;
    //printf ("%d[%d](%c)\n",cont, linha, c);
  }
  return NULL;
}
