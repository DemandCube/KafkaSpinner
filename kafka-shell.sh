#!/bin/bash

ssh -o StrictHostKeyChecking=no root@localhost -p $(docker inspect -f '{{ if index .NetworkSettings.Ports "22/tcp" }}{{(index (index .NetworkSettings.Ports "22/tcp") 0).HostPort}}{{ end }}' "$1")
