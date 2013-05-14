# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  # Require 32bit Debian 7.0:
  config.vm.box = "wheezy32"

  # This is a "base box" for Debian 7.0 wheezy, created with veewee
  # (so, you probably should not trust this one, but create your own):
  config.vm.box_url = "https://dl.dropboxusercontent.com/u/228224/wheezy32.box"

  # Port forwarding for Selenium Server:
  config.vm.network :forwarded_port, guest: 4444, host: 4444

  # Handle provision with puppet:
  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "manifests"
    puppet.manifest_file  = "init.pp"
  end

end
