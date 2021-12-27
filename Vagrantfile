# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
    config.vm.box = "almalinux/8"
    config.vm.box_version = "8.4.20211014"

    config.vm.provider "virtualbox" do |vb|
        vb.cpus = 8
        vb.memory = 16384

        10.times do |num|
            disk_file = "./disk#{num+1}.vdi"
            unless File.exists?(disk_file)
                vb.customize [ 'createhd', '--filename', disk_file, '--format', 'VDI', '--size', 32 * 1024 ]
            end
            vb.customize [ 'storageattach',
                :id,
                '--storagectl', 'SATA Controller',
                '--port', num + 2,
                '--device', 0,
                '--type', 'hdd',
                '--medium', disk_file,
                '--hotpluggable', 'on'
            ]
        end
    end

    config.vm.provision "shell", path: 'disk_array_setup.sh'
end
