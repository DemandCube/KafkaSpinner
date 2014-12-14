#!/bin/bash

cp /opt/kafka/config/server.properties /opt/kafka/config/server.bak && sed -e "s/broker.id=0/broker.id=$BROKER_ID/;s/#host.name=localhost/host.name=knode$BROKER_ID/;s/zookeeper.connect=localhost:2181/zookeeper.connect=$ZK_CONNECT/;s/num.partitions=2/num.partitions=$NUM_PARTITIONS/" /opt/kafka/config/server.bak > /opt/kafka/config/server.properties

cp /opt/kafka/config/producer.properties /opt/kafka/config/producer.bak && sed -e "s/metadata.broker.list=localhost:9092/metadata.broker.list=$BROKER_LIST/" /opt/kafka/config/producer.bak > /opt/kafka/config/producer.properties

cp /opt/kafka/config/consumer.properties /opt/kafka/config/consumer.bak && sed -e "s/zookeeper.connect=127.0.0.1:2181/zookeeper.connect=$ZK_CONNECT/" /opt/kafka/config/consumer.bak > /opt/kafka/config/consumer.properties

rm /opt/kafka/config/server.bak
rm /opt/kafka/config/producer.bak
rm /opt/kafka/config/consumer.bak
#sed 's/??/\
#/g' /opt/kafka/config/tmp.properties > /opt/kafka/config/server.properties
#rm /opt/kafka/config/tmp.properties
/usr/sbin/sshd -D;
