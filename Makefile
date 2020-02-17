# GNU Makefile

default: soquetes chatSoquetes multicast HelloRMI HelloRPC WSJava-console ComunicacaoIndireta-RabbitMQ DropBoxJava Lamport ExclusaoMutua Hadoop

soquetes: 00-soquetes/Makefile
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	cd 00-soquetes && make > ../Logsoquetes.log
	@echo "-------------------------------------"
	@echo "Soquetes: OK"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"

chatSoquetes: 01-chatSoquetes/Makefile 
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	cd 01-chatSoquetes  && make > ../LogChatSoquetes.log
	@echo "-------------------------------------"
	@echo "ChatSoquetes: OK"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"

multicast: 02-multicast/Makefile
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	cd 02-multicast  && make > ../LogMulticast.log
	@echo "-------------------------------------"
	@echo "Multicast: OK"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"

HelloRMI: 03-HelloRMI/Makefile
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	cd 03-HelloRMI  && make  > ../LogHelloRMI.log
	@echo "-------------------------------------"
	@echo "HelloRMI: OK"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"

HelloRPC: 04-HelloRPC/Makefile
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	cd 04-HelloRPC  && make > ../LogHelloRPC.log
	@echo "-------------------------------------"
	@echo "HelloRPC: OK"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"

WSJava-console: 05-WSJava-console/Makefile
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	cd 05-WSJava-console  && make > ../LogWSJava-console.log
	@echo "-------------------------------------"
	@echo "WSJava: OK"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"

ComunicacaoIndireta-RabbitMQ: 06-RabbitMQJava/Makefile
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	cd 06-RabbitMQJava  && make > ../LogRabbitMQ.log
	@echo "-------------------------------------"
	@echo "RabbitMQ: OK"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"

DropBoxJava: 07-DropBoxJava/Makefile
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	cd 07-DropBoxJava  && make > ../LogDropBox.log
	@echo "-------------------------------------"
	@echo "Dropbox: OK"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"

Lamport: 08-Lamport/Makefile
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	cd 08-Lamport  && make > ../LogLamport.log
	@echo "-------------------------------------"
	@echo "Relogio de Lamport: OK"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"

ExclusaoMutua: 09-ExclusaoMutua/Makefile
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	cd 09-ExclusaoMutua  && make > ../LogExclusaoMutua.log
	@echo "-------------------------------------"
	@echo "Algortimo do Servidor Central: OK"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"

Hadoop: 10-Hadoop/Makefile
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	cd 10-Hadoop  && make > ../LogHadoop.log
	@echo "Hadoop: OK"
	@echo "-------------------------------------"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"

clean:
	cd 00-soquetes  && make clean > ../Logsoquetes-clean.log
	cd 01-chatSoquetes  && make clean > ../LogChatSoquetes-clean.log
	cd 02-multicast  && make clean > ../LogMulticast-clean.log
	cd 03-HelloRMI  && make clean > ../LogHelloRMI-clean.log
	cd 04-HelloRPC  && make clean > ../LogHelloRPC-clean.log
	cd 05-WSJava-console  && make clean > ../LogWSJava-console-clean.log
	cd 06-RabbitMQJava  && make clean > ../LogRabbitMQ-clean.log
	cd 07-DropBoxJava  && make clean  > ../LogDropBox-clean.log
	cd 08-Lamport  && make clean  > ../LogLamport-clean.log
	cd 09-ExclusaoMutua  && make clean > ../LogExclusaoMutua-clean.log
	cd 10-Hadoop  && make clean > ../LogHadoop-clean.log

cleanall:
	make clean
	rm -f Log*.log
	cd 07-DropBoxJava  && make cleanall
	cd 10-Hadoop  && make cleanall
