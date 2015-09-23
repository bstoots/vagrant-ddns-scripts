# -*- mode: ruby -*-
# vi: set ft=ruby :
module OS
  def OS.windows?
    (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
  end
  def OS.mac?
    (/darwin/ =~ RUBY_PLATFORM) != nil
  end
  def OS.unix?
    !OS.windows?
  end
  def OS.linux?
    OS.unix? and not OS.mac?
  end
end

Vagrant.configure(2) do |config|

  config.vm.box = "ubuntu/trusty64"
  config.vm.guest = :linux
  config.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"
  config.vm.box_download_checksum_type = "sha256"
  config.vm.box_download_checksum = "d9615654c5ea16b66d1fec1b9dbd4a9f3aeafd0bd59ac497040638f8789b3885"

  # config.vm.box = 'freebsd/FreeBSD-10.2-RELEASE'
  # config.vm.guest = :freebsd
  # config.ssh.shell = "/bin/sh"
  # config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    vb.gui = false
    # Customize the amount of memory on the VM:
    vb.memory = "1024"
  end

  # Run triggers
  config.trigger.after [:up, :resume, :reload] do
    if OS.windows? then
      run 'powershell -NoProfile -ExecutionPolicy Unrestricted -File .\ddns.ps1 -action add -interface eth0 -hostname foo.localhost -nsupdatekey "D:\Users\bstoots\Klocalhost.+157+11776.key"'
    else 
      # 
    end
  end
  config.trigger.after [:destroy, :suspend, :halt] do
    if OS.windows? then
      run 'powershell -NoProfile -ExecutionPolicy Unrestricted -File .\ddns.ps1 -action delete -interface eth0 -hostname foo.localhost -nsupdatekey "D:\Users\bstoots\Klocalhost.+157+11776.key"'
    else
      # 
    end
  end

end
