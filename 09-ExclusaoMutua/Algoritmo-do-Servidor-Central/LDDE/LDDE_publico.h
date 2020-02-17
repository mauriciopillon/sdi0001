
#define SUCESSO 1
#define FRACASSO 0


typedef struct LDDE *pLDDE, **ppLDDE;

// Funções básicas de uma LDDE
int criaLDDE(ppLDDE pp, int tamanho_info);
int destroiLDDE(ppLDDE pp);
int reiniciaLDDE(pLDDE p);

int insereInicio(pLDDE p, void *elemento);
int insereFim(pLDDE p, void *elemento);
int inserePosicao(pLDDE p, int N, void *elemento);

int removeInicio(pLDDE p, void *elemento);
int removeFim(pLDDE p, void *elemento);
int removePosicao(pLDDE p, int N, void *elemento);

int buscaInicio(pLDDE p, void *elemento);
int buscaFim(pLDDE p, void *elemento);
int buscaPosicao(pLDDE p, int N, void *elemento);

// Funções adicionais
int testaVazia(pLDDE p);
int contaElementos(pLDDE p);
//int vizinhos (pLDDE p, void * ant, void * pos, void * prox, int pos);

