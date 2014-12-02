#!/bin/bash 

NUM_KAFKA=1;
CURRENT_NODE=1;
#declare -a NODE;
#NODE=;

function usage
{
    echo -e "usage: \n
      --num-kafka-node      Number of kafka nodes to launch\n
      -h | --help           Help";
}

function getPort(){
    echo docker inspect -f '{{ if index .NetworkSettings.Ports "22/tcp" }}{{(index (index .NetworkSettings.Ports "22/tcp") 0).HostPort}}{{ end }}' "$1"
}

function updateHosts
{
#read -a NODE
echo "Updating hosts..."
IFS='.' read -ra IP <<< "$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" znode)"

echo ${IP[0]}.${IP[1]}.xx.xx


for i in "${NODE[@]}" 
do 
	echo $i
	for j in "${NODE[@]}"
        do


         ssh -o StrictHostKeyChecking=no root@localhost -p $(docker inspect -f '{{ if index .NetworkSettings.Ports "22/tcp" }}{{(index (index .NetworkSettings.Ports "22/tcp") 0).HostPort}}{{ end }}' "$i") "echo '$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" $j)    $j'  >> /etc/hosts"
        done
	
done 

exit 0
}

while [ "$1" != "" ]; do
    case $1 in
        --num-kafka-node)        shift
                                NUM_KAFKA=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done



sudo docker rm -f $(docker ps -a -q)

echo "starting zookeeper..."
sudo docker run -d -p 2181:2181 -p 2222:22 -h znode --name znode ubuntu:kafka /opt/zookeeper/start-zookeeper.sh
sleep 5

while [ "$CURRENT_NODE" -le "$NUM_KAFKA" ]    # this is loop1
do
  NODE[$CURRENT_NODE]=knode$CURRENT_NODE
   echo "starting knode$CURRENT_NODE..."
   sudo docker run -d -P -e BROKER_ID=$CURRENT_NODE --privileged  -h knode$CURRENT_NODE --link znode:znode --name knode$CURRENT_NODE  ubuntu:kafka /opt/kafka/start-kafka.sh
   CURRENT_NODE=`expr $CURRENT_NODE + 1`
done

updateHosts

#sudo docker run -d -p 3333:22 -h knode1 --link znode:znode --name knode1  ubuntu:kafka /opt/kafka/start-kafka.sh
#sudo docker run -d -p 4444:22 -h knode2 --link znode:znode --name knode2  ubuntu:kafka /opt/kafka/start-kafka.sh
#sudo docker run -d -p 5555:22 -h knode3 --link znode:znode --name knode3  ubuntu:kafka /opt/kafka/start-kafka.sh
