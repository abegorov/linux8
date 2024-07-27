# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV['VAGRANT_EXPERIMENTAL'] = 'disks'

MACHINES = {
  :zfs => {
    :box => 'generic/centos9s',
    :cpus => 2,
    :memory => 1024,
    :disks => {
      :disk001 => '128MB',
      :disk002 => '128MB',
      :disk003 => '128MB',
      :disk004 => '128MB',
      :disk005 => '128MB',
      :disk006 => '128MB',
      :disk007 => '128MB',
      :disk008 => '128MB',
      :disk009 => '128MB',
      :disk010 => '128MB',
      :disk011 => '128MB',
      :disk012 => '128MB',
      :disk013 => '128MB',
      :disk014 => '128MB',
      :disk015 => '128MB',
      :disk016 => '128MB',
      :disk017 => '128MB',
      :disk018 => '128MB',
      :disk019 => '128MB',
      :disk020 => '128MB',
      :disk021 => '128MB',
      :disk022 => '128MB',
      :disk023 => '128MB',
      :disk024 => '128MB',
      :disk025 => '128MB',
      :disk026 => '128MB',
      :disk027 => '128MB',
      :disk028 => '128MB',
      :disk029 => '128MB'
    },
    :script => 'provision.sh'
  }
}

Vagrant.configure('2') do |config|
  MACHINES.each do |host_name, host_config|
    config.vm.define host_name do |host|
      host.vm.box = host_config[:box]
      host.vm.host_name = host_name.to_s

      config.vm.synced_folder "logs/", "/vagrant"

      host.vm.provider :virtualbox do |vb|
        vb.cpus = host_config[:cpus]
        vb.memory = host_config[:memory]
      end

      host_config[:disks].each do |name, size|
        host.vm.disk :disk, name: name.to_s, size: size
      end

      host.vm.provision :shell do |shell|
        shell.path = host_config[:script]
        shell.privileged = false
      end
    end
  end
end
