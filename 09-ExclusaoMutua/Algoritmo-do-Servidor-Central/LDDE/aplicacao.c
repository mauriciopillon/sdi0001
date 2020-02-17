#include <stdio.h>
#include <stdlib.h>
#include "aplicacao.h"


int main(int argc, char **argv)
{
	pLDDE lista;
	int opcao, num, pos, i;
	
	if(!criaLDDE(&lista, sizeof(int))){
		printf("Erro ao criar a lista.\n");
		system("PAUSE");
		exit(1);
	}

	for (i=0;i<20;i++)
		if(insereFim(lista, &i)){
			printf("... inserido com sucesso(%d).\n",i);
		}else{
			printf("... falha na insercao.\n");
		}

	num=100;	
	if(insereFim(lista, &num)){
		printf("... inserido com sucesso.\n");
	}else{
		printf("... falha na insercao.\n");
	}

	num=110;	
	if(inserePosicao(lista, 1, &num)){
		printf("... inserido com sucesso.\n");
	}else{
		printf("... falha na insercao.\n");
	}

	if(removeInicio(lista, &num)){
		printf("... [%i](inicio) removido com sucesso.\n", num);
	}else{
		printf("... falha na remocao.\n");
	}

	if(removeFim(lista, &num)){
		printf("... [%i](fim) removido com sucesso.\n", num);
	}else{
		printf("... falha na remocao.\n");
	}

	if(removePosicao(lista, 3, &num)){
		printf("... [%i](pos=3) removido com sucesso.\n", num);
	}else{
		printf("... falha na remocao.\n");
	}

	if(buscaInicio(lista, &num)){
		printf("... [%i] buscado com sucesso.\n", num);
	}else{
		printf("... falha na busca.\n");
	}

	if(buscaFim(lista, &num)){
		printf("... [%i] buscado com sucesso.\n", num);
	}else{
		printf("... falha na busca.\n");
	}
	
    if(buscaPosicao(lista, 1, &num))
		printf("... [%i] buscado com sucesso.\n", num);
	else
		printf("... falha na busca.\n");
	
	for (i=0;i<20;i++)
		if(removeFim(lista, &num)){
			printf("... [%i](fim) removido com sucesso.\n", num);
		}else{
			printf("... falha na remocao.\n");
		}

	if(reiniciaLDDE(lista)){
		printf("... lista reiniciada com sucesso.\n");
	}else{
		printf("... falha na reinicializacao.\n");
	}

	if(removeInicio(lista, &num)){
		printf("... [%i] removido com sucesso.\n", num);
	}else{
		printf("... falha na remocao.\n");
	}

	if(!destroiLDDE(&lista)){
		printf("Erro ao destruir a lista.\n");
		system("PAUSE");
		exit(1);
	}
}
