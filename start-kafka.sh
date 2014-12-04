#!/bin/bash 
#./start-zookeeper.sh;

KAFKA_HOME=/opt/kafka;

#function startBroker(){
#  /opt/kafka/config/config_modifier.sh
  $KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties > log.txt& 
#}

#mkdir -p ~/.ssh;
#mv /opt/authorized_keys ~/.ssh/authorized_keys;
#chmod 700 ~/.ssh;
#chmod 644 ~/.ssh/authorized_keys;

#startBroker;
#/usr/sbin/sshd -D;
