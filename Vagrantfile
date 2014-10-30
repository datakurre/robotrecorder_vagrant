# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|
  config.vm.box = 'puphpet/debian75-x32'
  config.vm.synced_folder 'recordings', '/recordings'

  # Port forwarding for Selenium Server:
  config.vm.network :forwarded_port, guest: 4444, host: 4444

  # Handle provision with puppet:
  config.vm.provision :puppet do |puppet|
  end
end
