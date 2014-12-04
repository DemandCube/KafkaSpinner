#!/bin/bash

mkdir -p ~/.ssh;
mv /opt/authorized_keys ~/.ssh/authorized_keys;
chmod 700 ~/.ssh;
chmod 644 ~/.ssh/authorized_keys;

echo "$SERVER_ID" > /tmp/zookeeper/myid  

/usr/sbin/sshd -D;
