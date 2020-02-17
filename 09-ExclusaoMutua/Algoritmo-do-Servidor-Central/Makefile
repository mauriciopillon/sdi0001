# GNU Makefile

CC = gcc
CCFLAGS = -Wall
LDFLAGS = -pthread -lpthread
TARGET = client central_server #central_server_nosync
NOME=LDDE

all: $(TARGET)

$(NOME).o:	LDDE/$(NOME).c LDDE/$(NOME)_publico.h LDDE/$(NOME)_privado.h
		$(CC) $(CFLAGS) -c LDDE/$(NOME).c -o $(NOME).o

central_server:	central_server.c $(NOME).o
		$(CC) $(CFLAGS) $(LDFLAGS) central_server.c $(NOME).o -o central_server

clean:
	rm -f *.o *~ $(TARGET)
