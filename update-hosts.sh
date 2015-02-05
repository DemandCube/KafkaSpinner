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
  if grep -w -q "$i" /etc/hosts; then cp /etc/hosts /etc/hosts.bak && sed -e '/'"$i"'/s=^[0-9\.]*='"$(docker inspect -f '{{ .NetworkSettings.IPAddress }}' $i)"'=' /etc/hosts.bak > /etc/hosts; else echo "$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" $i)    $i"  >> /etc/hosts; fi
  for j in "${ALL_NODE[@]}"
  do
    #ssh -o StrictHostKeyChecking=no root@$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" $i) if grep -w -q "$j" /etc/hosts; then cp /etc/hosts /etc/hosts.bak && sed -e '/'"$j"'/s=^[0-9\.]*='"$(docker inspect -f '{{ .NetworkSettings.IPAddress }}' $j)"'=' /etc/hosts.bak > /etc/hosts; else echo "$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" $i)    $i"  >> /etc/hosts; fi
    ssh -o StrictHostKeyChecking=no root@$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" $i) "echo '$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" $j)    $j'  >> /etc/hosts"
    
  done
done 
