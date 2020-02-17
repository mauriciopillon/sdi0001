#!/bin/bash

stop-dfs.sh
hdfs namenode -format
start-dfs.sh
echo "hdfs mpillon"
hadoop fs -mkdir /user/; 
hadoop fs -mkdir /user/mpillon; 
hadoop fs -chown -R mpillon:hadoop_group /user/mpillon; 
hadoop fs -chmod -R 700 /user/mpillon;

#for i in `seq 1 20`; do
#  echo "hdfs aluno"$i;
#  hadoop fs -mkdir /user/hduser$i; 
#  hadoop fs -chown -R hduser$i:hadoop_group /user/hduser$i; 
#  hadoop fs -chmod -R 700 /user/hduser$i;
#done
