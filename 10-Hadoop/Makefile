# GNU Makefile
MVN=/usr/bin/mvn
MYHOMEJAVA=/usr/local/jdk1.8.0_131
JAR=$(MYHOMEJAVA)/bin/jar
JAVA=$(MYHOMEJAVA)/bin/java
JAVAC=$(MYHOMEJAVA)/bin/javac

NAME=sdi-hadoop
cGROUP=com
nGROUP=wsudesc
GROUP=$(cGROUP).$(nGROUP)
MVNFLAGS=archetype:generate -DgroupId=$(GROUP) -DartifactId=$(NAME) -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false
MVNDEP=dependency:get -Dartifact=org.apache.hadoop:hadoop-core:1.2.1
CLASSPATH=-classpath .org/apache/hadoop/hadoop-core/1.2.1/hadoop-core-1.2.1.jar
JARFILE=wc.jar

JFLAGS = -g 

default: newproject makepom makedep makelink sourcejava makepackage makejar makeinput copyfiles allOK

SDITestDropBox: SDITestDropBox.java dep.xml

newproject: 
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	@echo "%%%%                     SDIDB: Criação do Projeto MAVEN"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	$(MVN) $(MVNFLAGS)

makepom:
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	@echo "%%%%                     SDIDB: Copia do pom.xml"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	head -16 $(NAME)/pom.xml > /tmp/pom.xml
	cat dep.xml >> /tmp/pom.xml
	mv /tmp/pom.xml $(NAME)/pom.xml

makedep:
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	@echo "%%%%                     SDIDB: download das dependências"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	cd $(NAME) && $(MVN) $(MVNDEP)

makelink:
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	@echo "%%%%                     SDIDB: Link p/ dependências"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	cd $(NAME) && ln -sf ~/.m2/repository/org .org

sourcejava:
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	@echo "%%%%                     SDIDB: Link arquivo fonte (SDITestDropBox.java)"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	cd $(NAME)/src/main/java/$(cGROUP)/$(nGROUP)/ &&  ln -sf ../../../../../../WordCount.java WordCount.java
	cd $(NAME) &&  ln -sf ../WordCount.java WordCount.java

makepackage:
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	@echo "%%%%                     SDIDB: Compila projeto MAVEN"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	cd $(NAME) && $(MVN) package

makejar: WordCount.java
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	@echo "%%%%                     SDIDB: Gera Jar WordCount Hadoop"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	cd $(NAME) && $(JAVAC) $(CLASSPATH) WordCount.java 
	cd $(NAME) && $(JAR) cf $(JARFILE) WordCount*.class 

makeinput:
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	@echo "%%%%                     SDIDB: Cria arquivos de base "
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	cd $(NAME) && mkdir input
	cd $(NAME) && echo "Hello World Bye World" > input/file01
	cd $(NAME) && echo "Hello Hadoop Goodbye Hadoop" > input/file02

copyfiles:
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	@echo "%%%%                     SDIDB: Copia arquivos local p/ HDFS "
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	hadoop fs -mkdir input_word
	hadoop fs -put $(NAME)/input/file* input_word

allOK:
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	@echo "%%%%                     SDIDB: Para testar HelloJar, execute no terminal:	"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	@echo "cd $(NAME) ; java -cp  target/sdi-hadoop-1.0-SNAPSHOT.jar com.wsudesc.App ; cd -"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	@echo "%%%%                     SDIDB: Para testar WordCount, execute no terminal:	"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	@echo "cd $(NAME) ; hadoop jar wc.jar WordCount input_word output_word; cd -"
	@echo "cd $(NAME) ; hadoop fs -cat output_word/part-r-00000; cd -"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	@echo "%%%%                     SDIDB: Operações sobre o FS do Hadoop:	"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	@echo "CRIAR DIRETORIO: hadoop fs -mkdir <DIR>" 
	@echo "COPIAR ARQUIVOS: hadoop fs -put <LOCAL> <HDFS>" 
	@echo "REMOVER ARQUIVO: hadoop fs -rm <FILE>"
	@echo "REMOVER DIRETORIO: hadoop fs -rmdir <DIR>"
	

clean:
	rm -rf $(NAME)
	hadoop fs -rm input_word/*
	hadoop fs -rmdir input_word
	hadoop fs -rm output_word/*
	hadoop fs -rmdir output_word

cleanall:
	rm -rf $(NAME)
	rm -rf ~/.m2/
