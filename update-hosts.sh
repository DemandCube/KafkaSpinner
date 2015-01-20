#!/bin/bash 
CLUSTER_CONTAINER_LIST+=($(docker ps -a -q))
ALL_NODE=()

#getting kafka spinner related containers
for i in "${CLUSTER_CONTAINER_LIST[@]}"
do
  hostname=$(docker inspect -f '{{ .Config.Hostname }}' $i)
  if [[ "$hostname" == *knode* || "$hostname" == *zoo*  ]]; then
    ALL_NODE+=($hostname)
  fi
done

#Updating /etc/hosts file on all container
echo "Updating hosts on all container"
for i in "${ALL_NODE[@]}" 
do
  for j in "${ALL_NODE[@]}"
  do
    ssh -o StrictHostKeyChecking=no root@$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" $i) "echo '$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" $j)    $j'  >> /etc/hosts"
  done
done 
