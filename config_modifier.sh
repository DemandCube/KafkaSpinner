#!/bin/bash

#BROKER_ID=4
sed -e "s/broker.id=0/broker.id=$BROKER_ID/;s/#host.name=localhost/host.name=knode$BROKER_ID/;s/zookeeper.connect=localhost:2181/zookeeper.connect=znode:2181/" /opt/kafka/config/server.properties > /opt/kafka/config/tmp.properties
sed 's/??/\
/g' /opt/kafka/config/tmp.properties > /opt/kafka/config/server.properties
rm /opt/kafka/config/tmp.properties

