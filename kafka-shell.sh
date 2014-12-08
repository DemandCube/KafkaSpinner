#!/bin/bash

ssh -o StrictHostKeyChecking=no $USER@$(hostname) -p $(docker inspect -f '{{ if index .NetworkSettings.Ports "22/tcp" }}{{(index (index .NetworkSettings.Ports "22/tcp") 0).HostPort}}{{ end }}' "$1")
