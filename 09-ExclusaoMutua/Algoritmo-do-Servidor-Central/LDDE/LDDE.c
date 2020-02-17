#include "LDDE_privado.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>



/*
	LDDE - Lista Din�mica Duplamente Encadeada
	Autor: Mauricio Aronne Pillon
	Data: 08/09/09
    obs.: c�digo modificado da LDSE de Tiago Brandes (ex-monitor de AED)
*/

/*-------------------------------------------------------------------------*/
/* Cria uma LDDE */
int criaLDDE(ppLDDE pp, int tamanho_info)
{
	/* aloca descritor */
	(*pp) = (LDDE *)malloc(sizeof(LDDE));
    if( (*pp) == NULL)
    	return FRACASSO;

	/* inicia atributos */
	(*pp)->tamanho_info = tamanho_info;
	(*pp)->inicio = NULL;
	(*pp)->fim = NULL;

	return SUCESSO;
}

/* Destroi uma LDDE */
int destroiLDDE(ppLDDE pp)
{
	if( (*pp) == NULL)
		return FRACASSO;

	/* reinicia e desaloca o descritor */
	reiniciaLDDE((*pp));
	free((*pp));
	(*pp) = NULL;

	return SUCESSO;
}

/* reinicia a LDDE, desalocando todos os dados */
int reiniciaLDDE(pLDDE p)
{
	NoLDDE *aux, *prox;

	if(p == NULL)
		return FRACASSO;

	/* caminha pela lista e desaloca todos os n�s */
	aux = p->inicio;
	while(aux != NULL){
		prox = aux->prox;
		free(aux->dados);
		free(aux);
		aux = prox;
	}

	p->inicio = NULL;
	p->fim = NULL;

	return SUCESSO;
}


/*-------------------------------------------------------------------------*/
/* Testa se a LDDE est� vazia */
int testaVazia(pLDDE p)
{
	if(p == NULL)
		return FRACASSO;

	if(p->inicio == NULL)
		return SUCESSO;
	else
		return FRACASSO;

}

/* retorna a quantidade de elementos da LDSE */
int contaElementos(pLDDE p)
{
	if(p == NULL)
		return FRACASSO;

	int n = 0;
	NoLDDE *aux = p->inicio;

	/* conta os elementos da lista */
	while(aux != NULL){
		aux = aux->prox;
		n++;
	}

	return n;
}


/*-------------------------------------------------------------------------*/
/* insere um elemento no in�cio da LDDE */
int insereInicio(pLDDE p, void *elemento)
{
	NoLDDE *novo;

	if(p == NULL)
		return FRACASSO;

	/* aloca novo n� e copia o conte�do */
	novo = (NoLDDE *)malloc(sizeof(NoLDDE));
	if(novo == NULL)
		return FRACASSO;
	novo->dados = (void *)malloc(p->tamanho_info);
	if(novo->dados == NULL){
		free(novo);
		return FRACASSO;
	}
	memcpy(novo->dados, elemento, p->tamanho_info);

	/* atualiza o encadeamento dos n�s */
	novo->prox = p->inicio;
	novo->ant = NULL;
	p->inicio = novo;

	/* Caso a lista esteja vazia, fim = inicio */
	if (p->fim == NULL)
		p->fim = novo;
	else
	    novo->prox->ant = novo;


	return SUCESSO;
}

/* insere um elemento no final da LDSE */
int insereFim(pLDDE p, void *elemento) {
	NoLDDE *novo;

	if(p == NULL)
		return FRACASSO;

	if(testaVazia(p))
		return insereInicio(p, elemento);	// para evitar a condi��o especial
											// onde p->inicio precisaria ser
											// atualizado

	/* aloca novo n� e copia o conte�do */
	novo = (NoLDDE *)malloc(sizeof(NoLDDE));
	if(novo == NULL)
		return FRACASSO;
	novo->dados = (void *)malloc(p->tamanho_info);
	if(novo->dados == NULL){
		free(novo);
		return FRACASSO;
	}
	memcpy(novo->dados, elemento, p->tamanho_info);

	/* atualiza o encadeamento dos n�ss */
	novo->prox = NULL;
	novo->ant = p->fim;
	p->fim->prox = novo;
	p->fim = novo;
	return SUCESSO;
}

/* insere um elemento na en�sima posi��o da LDSE */
int inserePosicao(pLDDE p, int N, void *elemento)
{
	NoLDDE *aux, *anterior, *novo;
	int n, nele;

    nele = contaElementos(p);
	if(p == NULL)
		return FRACASSO;
	if(N > (nele+1))
		return FRACASSO;
	if(N == (nele+1))
		return insereFim(p, elemento);
	if(N == 1)
		return insereInicio(p, elemento);	// para evitar a condi��o especial
											// onde p->inicio precisaria ser
											// atualizado

	/* aloca novo n� e copia o conte�do */
	novo = (NoLDDE *)malloc(sizeof(NoLDDE));
	if(novo == NULL)
		return FRACASSO;
	novo->dados = (void *)malloc(p->tamanho_info);
	if(novo->dados == NULL){
		free(novo);
		return FRACASSO;
	}
	memcpy(novo->dados, elemento, p->tamanho_info);

	/* caminha at� a en�sima posi��o */
	anterior = p->inicio;
	aux = anterior->prox;
	n = 2;		// posi��o do elemento apontado por 'aux'
	while(n < N){
		anterior = aux;
		aux = aux->prox;
		n++;
	}

	/* atualiza encadeamento dos n�s */
	anterior->prox = novo;
	novo->ant = anterior;
	novo->prox = aux;
	aux->ant = novo;


	return SUCESSO;
}


/*-------------------------------------------------------------------------*/
/* remove o primeiro elemento da LDDE */
int removeInicio(pLDDE p, void *elemento)
{
	NoLDDE *aux;

	if(p == NULL)
		return FRACASSO;
	if(testaVazia(p))
		return FRACASSO;

	/* desaloca os dados e atualiza encadeamento */
	aux = p->inicio;
	memcpy(elemento, aux->dados, p->tamanho_info);
	p->inicio = aux->prox;
	free(aux->dados);
	free(aux);
	if (p->inicio == NULL)
		p->fim = NULL;

	return SUCESSO;
}

/* remove o �ltimo elemento da LDDE */
int removeFim(pLDDE p, void *elemento)
{
	NoLDDE *remove;

	if(p == NULL)
		return FRACASSO;
	if(testaVazia(p))
		return FRACASSO;
	if(p->fim == p->inicio)
		return removeInicio(p, elemento);	// para evitar a condi��o especial
											// onde p->inicio precisaria ser
											// atualizado

	/* remove recebe o fim da lista */
	remove = p->fim;

	/* desaloca os dados e atualiza encadeamento */
	remove->ant->prox = remove->prox;
	p->fim = remove->ant;

	memcpy(elemento, remove->dados, p->tamanho_info);
	free(remove->dados);
	free(remove);
	return SUCESSO;
}

/* remove o en�simo elemento da LDDE */
int removePosicao(pLDDE p, int N, void *elemento)
{
	NoLDDE *aux, *anterior;
	int n;

	if(p == NULL)
		return FRACASSO;
	if(testaVazia(p))
		return FRACASSO;

	n = contaElementos(p);
	if(N > n)
		return FRACASSO;
	if(N == n)
		return removeFim(p, elemento);
	if(N == 1)
		return removeInicio(p, elemento);	// para evitar a condi��o especial
											// onde p->inicio precisaria ser
											// atualizado

	/* caminha at� o en�simo elemento da lista */
	anterior = p->inicio;
	aux = anterior->prox;
	n = 2;		// posi��o do elemento apontado por 'aux'
	while(n < N){
		anterior = aux;
		aux = aux->prox;
		n++;
	}

	/* desaloca os dados e atualiza encadeamento */
	memcpy(elemento, aux->dados, p->tamanho_info);
	anterior->prox = aux->prox;
	aux->prox->ant = aux->ant;
	free(aux->dados);
	free(aux);

	return SUCESSO;
}


/*-------------------------------------------------------------------------*/


/* busca o elemento no in�cio da LDDE */
int buscaInicio(pLDDE p, void *elemento)
{
	if(p == NULL)
		return FRACASSO;
	if(testaVazia(p))
		return FRACASSO;

	/* copia elemento */
	memcpy(elemento, p->inicio->dados, p->tamanho_info);

	return SUCESSO;
}


/*-------------------------------------------------------------------------*/
/* busca o elemento no final da LDDE */
int buscaFim(pLDDE p, void *elemento)
{
	NoLDDE *fim;

	if(p == NULL)
		return FRACASSO;
	if(testaVazia(p))
		return FRACASSO;

	memcpy(elemento, p->fim->dados, p->tamanho_info);

	return SUCESSO;
}

/* busca o elemento na en�sima posi��o da LDDE */
int buscaPosicao(pLDDE p, int N, void *elemento)
{
	NoLDDE *aux;
	int n;

	if(p == NULL)
		return FRACASSO;
	n = contaElementos(p);
	if(N > n || n == 0)
		return FRACASSO;

	/* caminha at� a en�sima posi��o e copia elemento */
	aux = p->inicio;
	n = 1;		// posi��o apontada por 'aux'
	while(n < N){
		aux = aux->prox;
		n++;
	}
	memcpy(elemento, aux->dados, p->tamanho_info);

	return SUCESSO;
}
