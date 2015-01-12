#!/bin/bash 
KAFKA_HOME=/opt/kafka;
ZK_CONNECT=$1
TMP_DESCRIBE_PATH=/tmp/describe
TMP_VERIFY_PATH=/tmp/verify
VERSION=1
REASSIGNMENT_JSON_FILE=/tmp/execute.json
NEW_BROKER=$2
NOT_COMPLETED_SUCCESSFULLY="true"

echo "ZK_CONNECT = $ZK_CONNECT"
echo "NEW_BROKERS = $NEW_BROKER"

$KAFKA_HOME/bin/kafka-topics.sh --describe --zookeeper $ZK_CONNECT > $TMP_DESCRIBE_PATH

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

if [ -s $TMP_DESCRIBE_PATH ]
then
rm $REASSIGNMENT_JSON_FILE
echo "{\"version\":$VERSION,\"partitions\":[" >> $REASSIGNMENT_JSON_FILE

IFS=',' read -ra NEW_BROKER_ARRAY <<< "$NEW_BROKER"
while read line 
 do 
  BROKER_LIST=()
  echo "$line" | grep -q "ReplicationFactor" 
  if [ $? -ne 0 ];then
#   echo $line   
   topic=`echo "$line" | awk '{print $2}'`
   partition=`echo "$line" | awk '{print $4}'`
   replicas=`echo "$line" | awk '{print $8}'`
   isr=`echo "$line" | awk '{print $10}'`

   IFS=',' 
   read -ra REPLICA_ARRAY <<< "$replicas"
   read -ra ISR_ARRAY <<< "$isr"
   BROKER_LIST=( "${ISR_ARRAY[@]}" )

    while [ "${#BROKER_LIST[@]}" -lt "${#REPLICA_ARRAY[@]}"  ]
    do
       selectedBroker=$(shuf -i 1-${#NEW_BROKER_ARRAY[@]} -n 1)
       selectedBroker=`expr $selectedBroker - 1`
       array_contains BROKER_LIST "${NEW_BROKER_ARRAY[$selectedBroker]}" && ALREADY_EXISTS="true" || ALREADY_EXISTS="false"
       if [ "$ALREADY_EXISTS" == "false"  ] ; then
           BROKER_LIST+=(${NEW_BROKER_ARRAY[$selectedBroker]})
       fi
    
    done

   BROKER_LIST_STR=""
   for i in "${BROKER_LIST[@]}"; do
    BROKER_LIST_STR+="$i,"
   done

    BROKER_LIST_STR="${BROKER_LIST_STR%?}"
    TOPICS_JSON+=`echo "{\"topic\":\"$topic\"","\"partition\":$partition,\"replicas\":[$BROKER_LIST_STR]},"`
  fi 
done < $TMP_DESCRIBE_PATH


TOPICS_JSON="${TOPICS_JSON%?}"

echo "$TOPICS_JSON" >> $REASSIGNMENT_JSON_FILE
echo "]}" >> $REASSIGNMENT_JSON_FILE


$KAFKA_HOME/bin/kafka-reassign-partitions.sh --zookeeper $ZK_CONNECT --reassignment-json-file $REASSIGNMENT_JSON_FILE --execute

echo "Verify the status of the partition reassignment"
while [ "$NOT_COMPLETED_SUCCESSFULLY" == "true" ]
do
  $KAFKA_HOME/bin/kafka-reassign-partitions.sh --zookeeper $ZK_CONNECT --reassignment-json-file $REASSIGNMENT_JSON_FILE --verify > $TMP_VERIFY_PATH
  while read line 
  do
     echo "$line" | grep -q "Status of partition reassignment"
     #echo "$?"
    if [ $? -ne 0 ];then
      readLine=`echo "$line"`
      echo "$readLine"
      if [[ $readLine == *"completed successfully"* ]]; then
        NOT_COMPLETED_SUCCESSFULLY="false"
      else
        NOT_COMPLETED_SUCCESSFULLY="true"
        break
      fi
     fi
  done < $TMP_VERIFY_PATH
  sleep 1
done

else
 echo "No topics found"
fi
