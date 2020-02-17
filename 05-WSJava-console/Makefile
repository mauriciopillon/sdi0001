# GNU Makefile
JAR=/usr/local/jdk1.8.0_131/bin/jar
JAVA=/usr/local/jdk1.8.0_131/bin/java
JAVAC=/usr/local/jdk1.8.0_131/bin/javac

JFLAGS = -g 
.SUFFIXES: hello/.java .class
.java.class:
	$(JAVAC) $(JFLAGS) hello\$*.java

default: HelloWordClient HelloWorldServerImpl HelloWorldServer HelloWorldServerPublisher

HelloWordClient: hello/HelloWorldClient.java
	$(JAVAC) $(JFLAGS) hello/HelloWorldClient.java
	
HelloWorldServerImpl: hello/HelloWorldServerImpl.java
	$(JAVAC) $(JFLAGS) hello/HelloWorldServerImpl.java

HelloWorldServer: hello/HelloWorldServer.java
	$(JAVAC) $(JFLAGS) hello/HelloWorldServer.java

HelloWorldServerPublisher: hello/HelloWorldServerPublisher.java
	$(JAVAC) $(JFLAGS) hello/HelloWorldServerPublisher.java

clean:
	rm -f hello/*.class 
