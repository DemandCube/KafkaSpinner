#!/bin/bash



# This function is used to display usage.
function usage
{
  echo -e "\nKafka Spinner Cluster operations usage\n"
  printf "%s\t%s\n" "--ip" "Print list of IP address and hostname on the cluster"  
  printf "%s\t\t\t%s\n" "--ssh" "SSH into any node of the cluster. eg: --ssh nodename"      
  printf "%s\t\t%s\n" "--help | -h" "Help"  
}

function printClusterInfo
{
CLUSTER_CONTAINER_LIST+=($(docker ps -a -q))
printf "%s\t%s\n" "HOSTNAME" "IP ADDRESS"
for i in "${CLUSTER_CONTAINER_LIST[@]}"
do
        printf "%s\t\t%s\n" "$(docker inspect -f '{{ .Config.Hostname }}' $i)" "$(docker inspect -f '{{ .NetworkSettings.IPAddress }}' $i)" 
done
}

function sshNode
{
ssh -o StrictHostKeyChecking=no root@$(docker inspect -f '{{ .NetworkSettings.IPAddress }}' $1)
}

while [ "$1" != "" ]; do
  case $1 in
    --ssh)                   shift
                             sshNode $1
                             ;;
    --ip)      printClusterInfo
                             ;;
    -h | --help )            usage
                             exit
                             ;;
    * )                      usage
                             exit 1
  esac
  shift
done
