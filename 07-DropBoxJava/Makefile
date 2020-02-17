# GNU Makefile
MVN=/usr/bin/mvn
JAR=/usr/local/jdk1.8.0_131/bin/jar
JAVA=/usr/local/jdk1.8.0_131/bin/java
JAVAC=/usr/local/jdk1.8.0_131/bin/javac

NAME=sdi-dropbox
cGROUP=com
nGROUP=wsudesc
GROUP=$(cGROUP).$(nGROUP)
MVNFLAGS=archetype:generate -DgroupId=$(GROUP) -DartifactId=$(NAME) -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false
MVNDEP=dependency:get -Dartifact=com.dropbox.core:dropbox-core-sdk:2.1.1

JFLAGS = -g 

default: newproject makepom makedep makelink sourcejava makepackage allOK

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
	cd $(NAME) && ln -sf ~/.m2/repository/com com
	@#cd $(NAME) && cp -r ~/.m2/repository/com . 

sourcejava:
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	@echo "%%%%                     SDIDB: Link arquivo fonte (SDITestDropBox.java)"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	cd $(NAME)/src/main/java/$(cGROUP)/$(nGROUP)/ &&  ln -sf ../../../../../../SDITestDropBox.java SDITestDropBox.java

makepackage:
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	@echo "%%%%                     SDIDB: Compila projeto MAVEN"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	cd $(NAME) && $(MVN) package

allOK:
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	@echo "%%%%                     SDIDB: Para testar HelloJar, execute no terminal:	"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	@echo "cd $(NAME) ; java -cp  target/sdi-dropbox-1.0-SNAPSHOT.jar com.wsudesc.App ; cd -"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	@echo "%%%%                     SDIDB: Para testar UploadDB (/tmp/test.txt), execute no terminal:	"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	@echo "cd $(NAME) ; java -cp  target/$(NAME)-1.0-SNAPSHOT.jar:com/dropbox/core/dropbox-core-sdk/2.1.1/dropbox-core-sdk-2.1.1.jar:com/fasterxml/jackson/core/jackson-core/2.7.4/jackson-core-2.7.4.jar $(cGROUP).$(nGROUP).app.SDITestDropBox;  cd -"


cleanall:
	rm -rf $(NAME) 
	rm -rf ~/.m2/

clean:
	rm -rf $(NAME)
