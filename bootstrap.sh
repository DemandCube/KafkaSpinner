set -x

#This is to allow passwordless ssh with root
#No longer needed
#sudo su - root
#ssh-keygen -f /root/.ssh/id_rsa -t rsa -N ''
#cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
#echo "root ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
#sed -i 's/^PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
#service ssh reload
#service ssh restart

#Install Docker
sudo add-apt-repository ppa:cwchien/gradle
sudo apt-get update
sudo apt-get install docker.io gradle -y
source /etc/bash_completion.d/docker.io


#Set up kafkaspinner user
sudo useradd -d /home/kafkaspinner -s /bin/bash -p password -m kafkaspinner
sudo adduser kafkaspinner sudo
sudo su - root -c "echo \"kafkaspinner ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers"
sudo groupadd docker
sudo gpasswd -a kafkaspinner docker
sudo service docker.io restart
#sudo su kafkaspinner

#Set SSH key
sudo su - kafkaspinner -c "mkdir /home/kafkaspinner/.ssh"
sudo su - kafkaspinner -c "ssh-keygen -f /home/kafkaspinner/.ssh/id_rsa -t rsa -N ''"
sudo su - kafkaspinner -c "chmod 700 /home/kafkaspinner/.ssh"
sudo su - kafkaspinner -c "chmod 600 /home/kafkaspinner/.ssh/*"



