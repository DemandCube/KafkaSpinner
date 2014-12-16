set -x

#Install Docker
sudo add-apt-repository ppa:cwchien/gradle
sudo apt-get update
sudo apt-get install docker.io gradle -y
source /etc/bash_completion.d/docker.io

#Install latest version of docker 
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
sudo sh -c "echo deb https://get.docker.com/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
sudo apt-get update
sudo apt-get install lxc-docker -y

#Create docker group
sudo groupadd docker

#Set up kafkaspinner user - create user, create home, create ssh keys
#sudo useradd -d /home/kafkaspinner -s /bin/bash -p password -m kafkaspinner
#sudo adduser kafkaspinner sudo
#sudo su - root -c "echo \"kafkaspinner ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers"
#sudo gpasswd -a kafkaspinner docker
#Set SSH key for kafkaspinner
#sudo su - kafkaspinner -c "mkdir /home/kafkaspinner/.ssh"
#sudo su - kafkaspinner -c "ssh-keygen -f /home/kafkaspinner/.ssh/id_rsa -t rsa -N ''"
#sudo su - kafkaspinner -c "chmod 700 /home/kafkaspinner/.ssh"
#sudo su - kafkaspinner -c "chmod 600 /home/kafkaspinner/.ssh/*"

#Add vagrant user to docker group
sudo gpasswd -a vagrant docker

#Set up new public key for vagrant user
sudo su - vagrant -c "mkdir /home/vagrant/.ssh"
sudo su - vagrant -c "ssh-keygen -f /home/vagrant/.ssh/id_rsa -t rsa -N ''"
sudo su - vagrant -c "chmod 700 /home/vagrant/.ssh"
sudo su - vagrant -c "chmod 600 /home/vagrant/.ssh/*"


#Add root user to docker group
sudo gpasswd -a root docker

#Set up new public key for root user
sudo su - root -c "mkdir /root/.ssh"
sudo su - root -c "ssh-keygen -f /root/.ssh/id_rsa -t rsa -N ''"
sudo su - root -c "chmod 700 /root/.ssh"
sudo su - root -c "chmod 600 /root/.ssh/*"


#Restart docker service
sudo service docker.io restart
sudo service docker restart