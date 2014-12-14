#!/bin/bash


echo "$SERVER_ID" > /tmp/zookeeper/myid  

/usr/sbin/sshd -D;
