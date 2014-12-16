# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/trusty64"
  
  #Get the vagrant image set up
  #config.vm.provision :shell, path: "bootstrap.sh"
  
  #Sync this folder with the VM
  #config.vm.synced_folder "./", "/home/kafkaspinner/KafkaSpinner", :owner=> 'kafkaspinner', :group=>'kafkaspinner', :create=>true
  config.vm.synced_folder "./", "/KafkaSpinner"#, :owner=> 'kafkaspinner', :group=>'kafkaspinner', :create=>true
  
  config.vm.provision :shell, path: "bootstrap.sh"
  #config.vm.provision :shell, inline: "sudo mount -t vboxsf -o uid=`id -u kafkaspinner`,gid=`id -g kafkaspinner` ./ /KafkaSpinner"

  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
  end
end
