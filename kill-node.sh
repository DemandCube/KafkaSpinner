#!/bin/bash


#echo "kill node sub script"
function usage
{
  echo -e "\nKill Nodes Usage: \n
  --stop                     Stop docker containers. Value should be list of docker containers name or id with comma seperated value (eg: --stop knode1,zoo1)
  --remove                   Remove docker containers. Value should be list of docker containers name or id with comma seperated value (eg: --remove knode1,zoo1)
  -h | --help                Help\n";
}


function getContainersArray
{
CONTAINERS=()                
IFS=','
read -ra TEMP_ARRAY <<< "$1"
CONTAINERS=( "${TEMP_ARRAY[@]}" )
}


while [ "$1" != "" ]; do
  case $1 in
    --stop)                  	shift
				getContainersArray $1
				echo "Stopping containers ${CONTAINERS[@]}"
				docker stop "${CONTAINERS[@]}"
                             	;;
    --remove)  			shift
				getContainersArray $1
				echo "Killing containers ${CONTAINERS[@]}"
                                docker rm -f "${CONTAINERS[@]}"
                             	;;
    -h | --help )            	usage
                             	exit
                             	;;
    * )                      	usage
        	                exit 1
  esac
  shift
done
 
