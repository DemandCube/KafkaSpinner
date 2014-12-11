#This is to allow passwordless ssh with root
sudo su - root
ssh-keygen -f /root/.ssh/id_rsa -t rsa -N ''
cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
echo "root ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
sed -i 's/^PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
service ssh reload
service ssh restart

#Install Docker
apt-get update
apt-get install docker.io -y
source /etc/bash_completion.d/docker.io

#Pull down KafkaSpinner
cd ~/
git clone git://github.com/DemandCube/KafkaSpinner