KafkaSpinner
============
The main goal of KafkaSpinner is to simulate realtime Multi-node Kafka cluster. This can be mainly used for testing purpose. Initially it launches multi-node kafka cluster with the given arguments. After launching cluster, kafka spinner make random nodes to die and add nodes in random period of time, so it simulate real kafka cluster environment.


##How to run?

###Prerequisites
1. [Install Docker](https://docs.docker.com/installation/ubuntulinux/) in host machine.
2. Install git. 
3. Enable passwordless ssh.
Kafka spinner needs passwordless communication from host machine to all docker containers. Host machine need to modify hosts file of docker container every time when new node is added to the cluster. For that host machine should have public ssh key. If not, please generate an rsa key file ```ssh-keygen -t rsa``` using this command. Do not enter a passphrase, just leave it blank.

###Steps to run
1. ```git clone https://github.com/DemandCube/KafkaSpinner.git```
2. ```cd KafkaSpinner```
3. ```./start-kafka-spinner.sh --kafka-node-range 1-3 --zookeeper-node-range 1-3 --failure-time-range 10-30 --attach-time-range 10-30 --failure-num-node 1 --ssh-public-key ~/.ssh/id_rsa.pub```

###Arguments
1. --kafka-node-range - Number of minimum and maximum kafka nodes to launch. (eg: --kafka-node-range 3-5, Default: 1-3)
2. --zookeeper-node-range - Number of minimum and maximum zookeeper nodes to launch. (eg: --zookeeper-node-range 3-5, Default: 1-3)
3. --failure-time-range - Failure time range to make kafka node to fail in between the given time duration. It will be measured in minutes. (eg: --failure-time-range 30-60)
4. --failure-num-node - Random nimber of nodes to fail when cluster is up and running. If value is 0, no node failure will occure in the cluster. (eg: --failure-num-node 2)
5. --attach-time-range - Time range to add new nodes to the cluster after node failure. It will be measured in minutes (eg: --attach-time-range 15-15)
6. --ssh-public-key - Path of ssh public key (eg: --ssh-public-key /root/.ssh/id_rsa.pub)
7. --num-partitions - Number of partitions for kafka.




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

## Tested with 
#####Ubuntu 12.04, Docker version 1.3.2, kafka_2.9.2-0.8.1.1 , Zookeeper version: 3.4.6 

####Note: 
1. kafka spinner may not run well or have some issues, since it is in development is in progress.





