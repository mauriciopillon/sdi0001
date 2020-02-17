#include <stdio.h>
#include "tools.h"

int main (int argc, char *argv[]) {
	FILE *filewrite, *fileread;
	char *msg = NULL;
	char filename[50];

	// Verificação dos parâmetros oriundos da console
	if (argc != 2) {
		printf("ERRO: ./main filename\n");
		exit(1);
	}

  sprintf (filename, "%s.client", argv[1]);
	fileread = fopen(filename,"r");
	if (fileread == NULL) {
		printf("Error: Na abertura dos arquivos (%s).", filename);
		exit(1);
	}

	sprintf (filename, "%s.serv", argv[1]);
	filewrite = fopen(filename,"w");
	if (filewrite == NULL) {
		printf("Error: Na abertura dos arquivos (%s).", filename);
		exit(1);
	}

  msg = readline (fileread);
	printf ("[%s]\n", msg);
	writeline (msg, filewrite);

	msg = readline (fileread);
	printf ("[%s]\n", msg);
	writeline (msg, filewrite);

	fclose (fileread);
	fclose (filewrite);

	return 0;
}
