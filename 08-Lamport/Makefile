# GNU Makefile

CC = gcc
CCFLAGS = -Wall
LDFLAGS =
TARGET = process

all: $(TARGET)

#lamport.o: lamport.c
#	$(CC) $(CCFLAGS) -c lamport.c -o $@ $(LDFLAGS)

process: process.c lamport.h lamport.o processP0.h processP1.h processP2.h
	$(CC) $(CCFLAGS) process.c lamport.o processP0.c processP1.c processP2.c -o $@ $(LDFLAGS)

clean:
	rm -f *~ $(TARGET) 
