# GNU Makefile

JC = /usr/local/jdk1.8.0_131/bin/javac
JFLAGS = #-Xlint
TARGET = MultiThreadChatServer.class MultiThreadChatClient.class clientThread.class

all: $(TARGET)

clientThread.class: clientThread.java
	$(JC) $(JFLAGS) clientThread.java 

MultiThreadChatServer.class: MultiThreadChatServer.java
	$(JC) $(JFLAGS) MultiThreadChatServer.java 

MultiThreadChatClient.class: MultiThreadChatClient.java
	$(JC) $(JFLAGS) MultiThreadChatClient.java 

clean:
	rm -f *~ $(TARGET)
