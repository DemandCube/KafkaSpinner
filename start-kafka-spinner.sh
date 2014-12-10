#!/bin/bash 

NUM_KAFKA=3;
MIN_KAFKA_NODE=2;
CURRENT_NODE=1;
CURRENT_ZOO_NODE=1;
FAILURE_TIME_RANGE=30-60;
FAILURE_NUM_NODE=1;
ATTACH_TIME_RANGE=1-5;
MIN_ZOO=1
MAX_ZOO=3
ZOO_BASE_PORT=218;
KAFKA_BASE_PORT=909;
SSH_BASE_PORT=222;
SSH_PUBLIC_KEY=~/.ssh/id_rsa.pub
NUM_PARTITIONS=2

# This function is used to display usage.
function usage
{
  echo -e "\nKafka Spinner Usage: \n
  --kafka-node-range      Number of minimum and maximum kafka nodes to launch. (eg: --kafka-node-range 3-5, Default: 1-3)
  --zookeeper-node-range  Number of minimum and maximum zookeeper nodes to launch. (eg: --zookeeper-node-range 3-5, Default: 1-3)
  --failure-time-range    Failure time range to make kafka node to fail in between the given time duration. It will be measured in minutes. (eg: --failure-time-range 30-60)
  --failure-num-node      Random nimber of nodes to fail when cluster is up and running. (eg: --failure-num-node 2)
  --attach-time-range     Time range to add new nodes to the cluster after node failure. It will be measured in minutes (eg: --attach-time-range 15-15)
  --ssh-public-key        Path of ssh public key (eg: --ssh-public-key /root/.ssh/id_rsa.pub)
  --num-partitions        Number of partitions for kafka
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

  for i in "${ALL_NODE[@]}" 
    do 
      #echo $i
      for j in "${ALL_NODE[@]}"
        do
          ssh -o StrictHostKeyChecking=no $USER@$(hostname) -p $(docker inspect -f '{{ if index .NetworkSettings.Ports "22/tcp" }}{{(index (index .NetworkSettings.Ports "22/tcp") 0).HostPort}}{{ end }}' "$i") "echo '$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" $j)    $j'  >> /etc/hosts"
        done
    done 
}

function modifyHosts
{
  echo "Modifying /etc/hosts..."
  for i in "${ALL_NODE[@]}"
    do
      for j in "${FAILED_NODE[@]}"
        do
ssh -o StrictHostKeyChecking=no $USER@$(hostname) -p $(docker inspect -f '{{ if index .NetworkSettings.Ports "22/tcp" }}{{(index (index .NetworkSettings.Ports "22/tcp") 0).HostPort}}{{ end }}' "$i") "cp /etc/hosts /etc/hosts.bak && sed -e '/"$j"/s=^[0-9\.]*='"$(docker inspect -f '{{ .NetworkSettings.IPAddress }}' $j)"'=' /etc/hosts.bak > /etc/hosts"
        done
    done

 for i in "${FAILED_NODE[@]}"
    do
      #echo $i
      for j in "${ALL_NODE[@]}"
        do
          ssh -o StrictHostKeyChecking=no $USER@$(hostname) -p $(docker inspect -f '{{ if index .NetworkSettings.Ports "22/tcp" }}{{(index (index .NetworkSettings.Ports "22/tcp") 0).HostPort}}{{ end }}' "$i") "echo '$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" $j)    $j'  >> /etc/hosts"
        done
    done
  unset $FAILED_NODE
}

while [ "$1" != "" ]; do
  case $1 in
    --kafka-node-range)      shift
                             IFS='-' read -a KAFKA_NODE_RANGE <<< "${1}"
                             NUM_KAFKA=${KAFKA_NODE_RANGE[1]}
                             MIN_KAFKA_NODE=${KAFKA_NODE_RANGE[0]}
                             ;;
    --zookeeper-node-range)  shift
                             IFS='-' read -a ZOO_NODE_RANGE <<< "${1}"
                             MIN_ZOO=${ZOO_NODE_RANGE[0]}
                             MAX_ZOO=${ZOO_NODE_RANGE[1]}
                             ;;
    --failure-time-range)    shift
                             FAILURE_TIME_RANGE=$1
                             ;;
    --failure-num-node)      shift
                             FAILURE_NUM_NODE=$1
                             #DIFF=`expr $NUM_KAFKA - $FAILURE_NUM_NODE`
                             #if [ $DIFF -lt $MIN_KAFKA_NODE ];then
                             #echo "It is not allowed to kill/fail nodes less than minimum node"
                             #exit 1
                             #fi
                             ;;
    --attach-time-range)     shift
                             ATTACH_TIME_RANGE=$1
                             ;;
    --ssh-public-key)        shift
                             SSH_PUBLIC_KEY=$1
                             if [ -z "$1" ] ; then 
                               echo "Exiting with non-zero error code. --ssh-public-key should not be empty"
                               exit 1
                             fi
                             ;;
    --num-partitions)        shift
                             NUM_PARTITIONS=$1
                             ;;
    -h | --help )            usage
                             exit
                             ;;
    * )                      usage
                             exit 1
  esac
  shift
done

function runCommand
{
  ssh -o StrictHostKeyChecking=no $USER@$(hostname) -p $(docker inspect -f '{{ if index .NetworkSettings.Ports "22/tcp" }}{{(index (index .NetworkSettings.Ports "22/tcp") 0).HostPort}}{{ end }}' "$1") "$2"
}

function startKafkaContainer
{
  docker run -d -p 22 -p $KAFKA_BASE_PORT$1:9092 -e BROKER_ID=$1 -e ZK_CONNECT=$ZK_CONNECT -e BROKER_LIST=$BROKER_LIST -e NUM_PARTITIONS=$NUM_PARTITIONS --privileged  -h knode$1 --name knode$1 ubuntu:kafka /opt/kafka/config/config-kafka.sh
}

function startZookeeperContainer
{
  docker run -d -p 22 -p $ZOO_BASE_PORT$1:2181 -e SERVER_ID=$1 --privileged  -h zoo$1 --name zoo$1  ubuntu:kafka /opt/zookeeper/config-zookeeper.sh
}


#Copy public ssh to authorized_keys
echo "Copy public ssh to authorized_keys"
cat $SSH_PUBLIC_KEY > ./authorized_keys

# Removing existing docker containers which are running
#docker stop $(docker ps -a -q)
docker rm -f $(docker ps -a -q)

echo "Removing zookeeper configuration file if exists in local"
rm zoo.cfg

echo "Creating zookeeper configuration file for cluster"
echo "tickTime=2000" > zoo.cfg
echo "initLimit=10" >> zoo.cfg
echo "syncLimit=2" >> zoo.cfg
echo "dataDir=/tmp/zookeeper" >> zoo.cfg
echo "clientPort=2181" >> zoo.cfg
while [ "$CURRENT_ZOO_NODE" -le "$MAX_ZOO" ]
  do
    echo "server.$CURRENT_ZOO_NODE=zoo$CURRENT_ZOO_NODE:2888:3888" >> zoo.cfg
    ZK_CONNECT+='zoo'$CURRENT_ZOO_NODE':2181,'
    CURRENT_ZOO_NODE=`expr $CURRENT_ZOO_NODE + 1`
done

while [ "$CURRENT_NODE" -le "$NUM_KAFKA" ]    # this is loop1
  do
    BROKER_LIST+='knode'$CURRENT_NODE':9092,'
    CURRENT_NODE=`expr $CURRENT_NODE + 1`
done

BROKER_LIST="${BROKER_LIST%?}"
ZK_CONNECT="${ZK_CONNECT%?}"
CURRENT_ZOO_NODE=1
CURRENT_NODE=1

echo "Building base docker image..."
docker build -t ubuntu:kafka .
ALL_NODE=()

while [ "$CURRENT_ZOO_NODE" -le "$MAX_ZOO" ]
  do
    ZOO_NODE[$CURRENT_ZOO_NODE]=zoo$CURRENT_ZOO_NODE
    ALL_NODE+=(zoo$CURRENT_ZOO_NODE)
    echo "starting zoo$CURRENT_ZOO_NODE container..."
#    docker run -d -p 22 -p $ZOO_BASE_PORT$CURRENT_ZOO_NODE:2181 -e SERVER_ID=$CURRENT_ZOO_NODE --privileged  -h zoo$CURRENT_ZOO_NODE --name zoo$CURRENT_ZOO_NODE  ubuntu:kafka /opt/zookeeper/config-zookeeper.sh
    startZookeeperContainer $CURRENT_ZOO_NODE
    CURRENT_ZOO_NODE=`expr $CURRENT_ZOO_NODE + 1`
done


while [ "$CURRENT_NODE" -le "$NUM_KAFKA" ] 
  do
    NODE[$CURRENT_NODE]=knode$CURRENT_NODE
    ALL_NODE+=(knode$CURRENT_NODE)
    echo "starting knode$CURRENT_NODE..."
    #sudo docker run -d -P -e BROKER_ID=$CURRENT_NODE --privileged  -h knode$CURRENT_NODE --name knode$CURRENT_NODE  ubuntu:kafka /opt/kafka/start-kafka.sh
    startKafkaContainer $CURRENT_NODE
    CURRENT_NODE=`expr $CURRENT_NODE + 1`
done

echo $ZK_CONNECT

updateHosts


echo "Start zookeeper in all node"
for i in "${ZOO_NODE[@]}"
  do
    echo "Starting zookeeper in $i"
    runCommand $i /opt/zookeeper/start-zookeeper.sh
  done

echo "Start kafka in all node"
for i in "${NODE[@]}"
  do
    echo "Starting kafka in $i"
    runCommand $i /opt/kafka/start-kafka.sh
  done

#echo "Starting zookeeper"
#sudo docker run -d -p 2181:2181 -p 2222:22 -h znode --name znode ubuntu:kafka /opt/zookeeper/start-zookeeper.sh
##Wainting for 5 seconds to allow znode to start zookeeper
#echo "Waiting for 10 seconds to allow znode to start zookeeper"
#sleep 10
#
#while [ "$CURRENT_NODE" -le "$NUM_KAFKA" ]    # this is loop1
#  do
#    NODE[$CURRENT_NODE]=knode$CURRENT_NODE
#    echo "starting knode$CURRENT_NODE..."
#    sudo docker run -d -P -e BROKER_ID=$CURRENT_NODE --privileged  -h knode$CURRENT_NODE --link znode:znode --name knode$CURRENT_NODE  ubuntu:kafka /opt/kafka/start-kafka.sh
#    CURRENT_NODE=`expr $CURRENT_NODE + 1`
#done

#updateHosts
array_contains () {
local array="$1[@]"
    local seeking=$2
    local in=1
    for element in "${!array}"; do
        if [[ $element == $seeking ]]; then
            in=0
            break
        fi
    done
    return $in
}

function addNode
{
  echo "Adding new node"
  for i in "${FAILED_NODE[@]}"
    do
      #echo "Failed nodes are $i"
      echo "starting $i..."
      j=$(sed 's/[^0-9]//g' <<<  $i)
      if [[ "$i" == *zoo* ]]; then
        echo "$j"
        startZookeeperContainer $j
      else
        startKafkaContainer $j
      fi
    done
  modifyHosts
  for i in "${FAILED_NODE[@]}"
    do
      #echo "Failed nodes are $i"
      echo "starting $i..."
      if [[ "$i" == *zoo* ]]; then
        echo "Starting zookeeper in $i"
        runCommand $i /opt/zookeeper/start-zookeeper.sh
      else
        echo "Starting kafka in $i"
        runCommand $i /opt/kafka/start-kafka.sh
      fi
    done
  
  startFailureTimer
}

function killNodee
{
  #CURRENT_NODE=`expr $CURRENT_NODE + 1`
  ZOO_KILL_COUNT=0
  KAFKA_KILL_COUNT=0
  FAILED_COUNT=1
  NUM_KAFKA_TO_KILL=`expr $NUM_KAFKA - $MIN_KAFKA_NODE`
  NUM_ZOO_TO_KILL=`expr $MAX_ZOO - $MIN_ZOO`
  unset  FAILED_NODE
  #declare -A FAILED_NODE=()
  FAILED_NODE=()
  failureNodeCount=$(shuf -i 1-"$FAILURE_NUM_NODE" -n 1)
  #failureNodeCount=3
  echo "$failureNodeCount node going to die now"
  while [ "${#FAILED_NODE[@]}" -lt "$failureNodeCount"  ]
  do
   ZOO_KAFKA=$(shuf -i 1-2 -n 1) 
   if [[ "$ZOO_KAFKA" -eq 1 && "$ZOO_KILL_COUNT" -lt "$NUM_ZOO_TO_KILL" ]] ; then
     zooNodeNumber=$(shuf -i 1-${#ZOO_NODE[@]} -n 1)
     array_contains FAILED_NODE "zoo$zooNodeNumber" && Z_ALREADY_EXISTS="true" || Z_ALREADY_EXISTS="false"
     if [ "$Z_ALREADY_EXISTS" == "false"  ] ; then
       FAILED_NODE+=("zoo$zooNodeNumber")
       ZOO_KILL_COUNT=`expr $ZOO_KILL_COUNT + 1`
     fi
     #echo "zoo$zooNodeNumber"
   elif [[ "$ZOO_KAFKA" -eq 2 && "$KAFKA_KILL_COUNT" -lt "$NUM_KAFKA_TO_KILL" ]] ; then 
     kafkaNodeNumber=$(shuf -i 1-${#NODE[@]} -n 1)
     array_contains FAILED_NODE "knode$kafkaNodeNumber" && K_ALREADY_EXISTS="true" || K_ALREADY_EXISTS="false"
     if [ "$K_ALREADY_EXISTS" == "false"  ] ; then
      #echo "adding knode....."
      FAILED_NODE+=("knode$kafkaNodeNumber")
      KAFKA_KILL_COUNT=`expr $KAFKA_KILL_COUNT + 1`
     fi
     #echo "knode$kafkaNodeNumber >>> KAFKA_KILL_COUNT=$KAFKA_KILL_COUNT"
   fi
   if [[ "$ZOO_KILL_COUNT" -eq "$NUM_ZOO_TO_KILL" && "$KAFKA_KILL_COUNT" -eq "$NUM_KAFKA_TO_KILL" ]] ; then 
    break
   fi
  done

  for i in "${FAILED_NODE[@]}"
    do
      #echo "Failed nodes are $i"
      echo "$i going to die..."
      #docker stop $i
      docker rm -f $i
      sleep 1
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

function killNode
{
  FAILED_COUNT=1
  unset  FAILED_NODE
  declare -A FAILED_NODE
  failureNodeCount=$(shuf -i 1-"$FAILURE_NUM_NODE" -n 1)
  echo "$failureNodeCount node going to fail now"
  failureNumNodes=($(shuf -i 1-${#NODE[@]} -n "$failureNodeCount"))
  for i in "${failureNumNodes[@]}"
    do
      echo "knode$i going to die..."
      docker rm -f knode$i
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
       killNodee
       break
     fi
   done
}

if [ "$FAILURE_NUM_NODE" != "0" ] ; then
  startFailureTimer
fi
