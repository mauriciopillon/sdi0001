
#include "LDDE_publico.h"

typedef struct LDDE{
    struct NoLDDE *inicio;		// ponteiro para o primeiro nó da lista
	struct NoLDDE *fim;			// ponteiro para o último nó da lista
    int tamanho_info;           // tamanho da informação contida nos nós
}LDDE;

typedef struct NoLDDE{
    void *dados;        		// ponteiro para os dados do nó
    struct NoLDDE *prox;		// ponteiro para o próximo elemento
	struct NoLDDE *ant;			// ponteiro para o elemento anterior
}NoLDDE;
