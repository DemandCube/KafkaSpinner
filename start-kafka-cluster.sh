#!/bin/bash 

NUM_KAFKA=1;
CURRENT_NODE=1;
FAILURE_TIME_RANGE=30-40;
FAILURE_NUM_NODE=1;
ATTACH_TIME_RANGE=1-5;

# This function is used to display usage.
function usage
{
  echo -e "\nKafka Spinner Usage: \n
  --num-kafka-node        Number of kafka nodes to launch. (eg: --num-kafka-node 3)
  --failure-time-range    Failure time range to make kafka node to fail in between the given time duration. It will be measured in minutes. (eg: --failure-time-range 30-60)
  --failure-num-node      Random nimber of nodes to fail when cluster is up and running. (eg: --failure-num-node 2)
  --attach-time-range     Time range to add new nodes to the cluster after node failure. It will be measured in minutes (eg: --attach-time-range 15-15)
  -h | --help             Help\n";
}

# Get exposed 22 port of the docker container. Need to pass conatiner name as argument
function getPort(){
  echo docker inspect -f '{{ if index .NetworkSettings.Ports "22/tcp" }}{{(index (index .NetworkSettings.Ports "22/tcp") 0).HostPort}}{{ end }}' "$1"
}

# Updates /etc/hosts of all kafka node 
function updateHosts
{
  echo "Updating /etc/hosts on all kafka nodes..."
  #IFS='.' read -ra IP <<< "$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" znode)"
  #echo ${IP[0]}.${IP[1]}.xx.xx

  for i in "${NODE[@]}" 
    do 
      #echo $i
      for j in "${NODE[@]}"
        do
          ssh -o StrictHostKeyChecking=no root@localhost -p $(docker inspect -f '{{ if index .NetworkSettings.Ports "22/tcp" }}{{(index (index .NetworkSettings.Ports "22/tcp") 0).HostPort}}{{ end }}' "$i") "echo '$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" $j)    $j'  >> /etc/hosts"
        done
    done 
#  exit 0
}

function modifyHosts
{
  echo "Modifying /etc/hosts..."
  for i in "${NODE[@]}"
    do
      for j in "${FAILED_NODE[@]}"
        do
ssh -o StrictHostKeyChecking=no root@localhost -p $(docker inspect -f '{{ if index .NetworkSettings.Ports "22/tcp" }}{{(index (index .NetworkSettings.Ports "22/tcp") 0).HostPort}}{{ end }}' "$i") "cp /etc/hosts /etc/hosts.bak && sed -e '/knode"$j"/s=^[0-9\.]*='"$(docker inspect -f '{{ .NetworkSettings.IPAddress }}' knode$j)"'=' /etc/hosts.bak > /etc/hosts"
        done
    done

 for i in "${FAILED_NODE[@]}"
    do
      #echo $i
      for j in "${NODE[@]}"
        do
          ssh -o StrictHostKeyChecking=no root@localhost -p $(docker inspect -f '{{ if index .NetworkSettings.Ports "22/tcp" }}{{(index (index .NetworkSettings.Ports "22/tcp") 0).HostPort}}{{ end }}' knode"$i") "echo '$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" $j)    $j'  >> /etc/hosts"
        done
    done
  startFailureTimer
}

while [ "$1" != "" ]; do
  case $1 in
    --num-kafka-node)        shift
                             NUM_KAFKA=$1
                             ;;
    --failure-time-range)    shift
                             FAILURE_TIME_RANGE=$1
                             ;;
    --failure-num-node)      shift
                             FAILURE_NUM_NODE=$1
                             ;;
    --attach-time-range)     shift
                             ATTACH_TIME_RANGE=$1
                             ;;
    -h | --help )            usage
                             exit
                             ;;
    * )                      usage
                             exit 1
  esac
  shift
done

# Removing existing docker containers which are running
sudo docker rm -f $(docker ps -a -q)

echo "Starting zookeeper"
sudo docker run -d -p 2181:2181 -p 2222:22 -h znode --name znode ubuntu:kafka /opt/zookeeper/start-zookeeper.sh
#Wainting for 5 seconds to allow znode to start zookeeper
echo "Wainting for 10 seconds to allow znode to start zookeeper"
sleep 10

while [ "$CURRENT_NODE" -le "$NUM_KAFKA" ]    # this is loop1
  do
    NODE[$CURRENT_NODE]=knode$CURRENT_NODE
    echo "starting knode$CURRENT_NODE..."
    sudo docker run -d -P -e BROKER_ID=$CURRENT_NODE --privileged  -h knode$CURRENT_NODE --link znode:znode --name knode$CURRENT_NODE  ubuntu:kafka /opt/kafka/start-kafka.sh
    CURRENT_NODE=`expr $CURRENT_NODE + 1`
done

updateHosts
function addNode
{
  echo "Adding new node"
  for i in "${FAILED_NODE[@]}"
    do
      #echo "Failed nodes are $i"
      echo "starting knode$i..."
      sudo docker run -d -P -e BROKER_ID=$i --privileged  -h knode$i --link znode:znode --name knode$i  ubuntu:kafka /opt/kafka/start-kafka.sh 
    done
  modifyHosts
}
function killNode
{
  FAILED_COUNT=1
  failureNodeCount=$(shuf -i 1-"$FAILURE_NUM_NODE" -n 1)
  echo "$failureNodeCount node going to fail now"
  failureNumNodes=($(shuf -i 1-${#NODE[@]} -n "$failureNodeCount"))
  for i in "${failureNumNodes[@]}"
    do
      echo "knode$i going to die..."
      sudo docker rm -f knode$i
      echo "knode$i died"
      FAILED_NODE[$FAILED_COUNT]=$i
      FAILED_COUNT=`expr $FAILED_COUNT + 1`
    done

  attach_time=$(( $(shuf -i "$ATTACH_TIME_RANGE" -n 1) * 60 ))
  while true;
   do
     attach_time=`expr $attach_time - 1`
     sleep 1
     echo "New node will be added in $attach_time seconds."
     if [ $attach_time -eq 1 ]; then
       #echo "Going to add..."
       addNode
       break
     fi
   done
}

function startFailureTimer 
{
  failure_time=$(( $(shuf -i "$FAILURE_TIME_RANGE" -n 1) * 60 ))
  while true;
   do 
     failure_time=`expr $failure_time - 1`
     sleep 1
     echo "Node failure will occur in $failure_time seconds."
     if [ $failure_time -eq 1 ]; then
       #echo "Going to kill..."
       killNode
       break
     fi
   done
}

startFailureTimer
