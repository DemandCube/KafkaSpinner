KafkaSpinner
============
The main goal of KafkaSpinner is to simulate realtime Multi-node Kafka cluster. This can be mainly used for testing purpose. Initially it launches multi-node kafka cluster with the given arguments. After launching cluster, kafka spinner make random nodes to die and add nodes in random period of time, so it simulate real kafka cluster environment.


##How to run?

###Prerequisites
1. [Install Docker](https://docs.docker.com/installation/ubuntulinux/) in host machine. (Version 1.3.2 or greater)
2. Install git. 
3. Add new user for kafka spinner - ```sudo adduser kafkaspinner```.
4. Add the docker group if it doesn't already exist - ```sudo groupadd docker```.
5. Add the connected user ÔkafkaspinnerÕ to the docker group - ```sudo gpasswd -a kafkaspinner docker```.
6. Restart the Docker daemon - ```sudo service docker restart```.
7. Optional - If you are on Ubuntu 14.04 and up use docker.io instead - ```sudo service docker.io restart``` 
8. Login into kafkaspinner - ```su kafkaspinner```
9. ```cd``` to home folder.
10. Enable passwordless ssh.
Kafka spinner needs passwordless communication from host machine to all docker containers. Host machine need to modify hosts file of docker container every time when new node is added to the cluster. For that host machine should have public ssh key. If not, please generate an rsa key file ```ssh-keygen -t rsa``` using this command. Do not Œenter a passphrase, just leave it blank.
```
vagrant@vagrant-ubuntu-trusty-64:/vagrant$ sudo su
root@vagrant-ubuntu-trusty-64:/vagrant# ssh-keygen -t rsa
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa):
#Don't enter a password here!!
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /root/.ssh/id_rsa.
Your public key has been saved in /root/.ssh/id_rsa.pub.
The key fingerprint is:
f1:9a:9d:a4:6e:8c:a3:55:e5:2b:7a:31:7d:a3:a5:8d root@vagrant-ubuntu-trusty-64
The key's randomart image is:
+--[ RSA 2048]----+
|                 |
|                 |
|        . .      |
|         =       |
|        S.+      |
|       .o*.o+    |
|      .o=o+B .   |
|     .oo+.E .    |
|    ...+.        |
+-----------------+
root@vagrant-ubuntu-trusty-64:/vagrant#
```


###Steps to run
1. ```git clone https://github.com/DemandCube/KafkaSpinner.git```
2. ```cd KafkaSpinner```
3. ```./start-kafka-spinner.sh --kafka-node-range 1-3 --zookeeper-node-range 1-3 --failure-time-range 10-30 --attach-time-range 10-30 --failure-num-node 1 --ssh-public-key ~/.ssh/id_rsa.pub --off-zookeeper-failure```

###Steps to run using Vagrant
1. ```vagrant up```
2. ```vagrant ssh```
3. ```cd /KafkaSpinner```
4. This repo is now mounted in that folder, use kafkaSpinner how you see fit.

###Arguments
1. --kafka-node-range - Number of minimum and maximum kafka nodes to launch. (eg: --kafka-node-range 3-5, Default: 1-3)
2. --zookeeper-node-range - Number of minimum and maximum zookeeper nodes to launch. (eg: --zookeeper-node-range 3-5, Default: 1-3)
3. --failure-time-range - Failure time range to make kafka node to fail in between the given time duration. It will be measured in minutes. (eg: --failure-time-range 30-60)
4. --failure-num-node-range - Random nimber of nodes to fail when cluster is up and running. If value is 0, no node failure will occure in the cluster. (eg: --failure-num-node-range 2-3)
5. --attach-time-range - Time range to add new nodes to the cluster after node failure. It will be measured in minutes (eg: --attach-time-range 15-15)
6. --ssh-public-key - Path of ssh public key (eg: --ssh-public-key /root/.ssh/id_rsa.pub)
7. --num-partitions - Number of partitions for kafka. (eg: --num-partitions 3)
8. --off-zookeeper-failure - Turn off zookeeper node failure using this option. Dont want to give value for this (eg: --off-zookeeper-failure)
9. --new-nodes-only - Will add new node with new broker-id and new hosname
10. --start-only - Starts only zookeeper or kafka nodes. (eg: --start-only zookeeper, Options: zookeeper/kafka)

###Get into shell for testing
After you started your cluster you can get into shell using ```./kafka-shell.sh zoo1```. Argument is the docker conainer name.

###How do you get container name and hostname?
To be simple you can run ```docker ps``` and get the list of conatiners with name.

Kafka spinner using simple naming convention to name containers and its hostname. Since kafka spinner is the simulator of multi-node kafka cluster, it will dynamically auto-generate docker container name and host name. Also it will expose kafka and zookeeper ports with some simple logics and it can be identified easily. It is as follows.

Kafka container name is generated in such a way that it containes 'knode' as prefix and sequence number of the container.
for example, if the sequence number of the container is 5, then the container name is "knode5". hostname is same as conatainer name.

Same as kafka, Zookeeper container name is generated with the prefix 'zoo' continued by sequence number of the conatiner. for example 'zoo3'

###How do you get exposed ports of zookeeper and kafka?
Since docker is an VM running inside a machine it needs to expose ports to the host machine. As same as naming convention for container name and hostname, kafka spinner uses <prefix>+<sequence number> to expose ports to the host machine.
For zookeeper, prefix is '218' and it continued by sequence number of the container. ex: 2181 for zoo1, 2182 for zoo2, 2183 for zoo3
For kafka, prefix is '909' and it continued by sequence number of the container. ex: 909 for knode1, 9092 for knode2, 9093 for knode3.


##Cluster Helper
```./cluster-helper.sh``` will help you to get ip address of the containers in the cluster, and also helps to ssh login into the specific node in the cluster.
 
###Arguments
1. --ip - Print list of IP address and hostname on the cluster. eg: ```./cluster-helper.sh --ip```
2. --ssh - SSH into any node of the cluster. eg: --ssh nodename. eg: ```./cluster-helper.sh --ssh nodename```

## Tested with 
#####Ubuntu 12.04, Ubuntu 14.04 Docker version 1.3.2, kafka_2.9.2-0.8.1.1 , Zookeeper version: 3.4.6 





