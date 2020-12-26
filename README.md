## ubuntu-18.04

Vagrant Box with Ubuntu 18.04

### Base image

Used base image [bento/ubuntu-18.04](https://app.vagrantup.com/bento/boxes/ubuntu-18.04)

### Automatic provisioning

The base image is provisioned with bash script [ubuntu-18.04.sh](https://github.com/elegoev/basebox-ubuntu-18.04/blob/master/provisioning/ubuntu-18.04.sh)

### Configuration
#### Required Vagrant Plugins

- vagrant-disksize
- vagrant-hosts
- vagrant-secret
- vagrant-share
- vagrant-vbguest
- vagrant-vmware-esxi

###  Create Vagrant Box Environment
#### Provider "virtualbox"

1. Create directory `mkdir "name of directory"`
1. Goto directory `cd "name of directory"`
1. Create Vagrantfile `Vagrantfilent init "elegoev/ubuntu-18.04"`
1. Start vagrant box `vagrant up`

#### Provider "vmware_esxi"

1. Create directory `mkdir "name of directory"`
1. Goto directory `cd "name of directory"`
1. Download basebox `vagrant box add "elegoev/ubuntu-18.04" --provider vmware_esxi`
1. Create secret file `.vagrant/secret.yaml`
   - add `esxi_username: "<ESXi root username"`
   - add `esxi_password: "<ESXi root password"`
1. Create [Vagrantfile](https://github.com/elegoev/vagrant-ubuntu-18.04-images/blob/master/jenkins/vagrant/Vagrantfile.tpl)
1. Create file [`metadata.json`](https://github.com/elegoev/vagrant-ubuntu-18.04-images/blob/master/jenkins/vagrant/metadata.json.tpl)
1. Copy and edit [`box.json`](https://github.com/elegoev/vagrant-ubuntu-18.04-images/blob/master/jenkins/vagrant/box.json)
1. Start vagrant box `vagrant up --provider vmware_esxi`

### Versioning

Repository follows sematic versioning  [![](https://img.shields.io/badge/semver-2.0.0-green.svg)](http://semver.org)

### Changelog

For all notable changes see [CHANGELOG](https://github.com/elegoev/basebox-ubuntu-18.04/blob/master/CHANGELOG.md)

### License

Licensed under The MIT License (MIT) - for the full copyright and license information, please view the [LICENSE](https://github.com/elegoev/basebox-ubuntu-18.04/blob/master/LICENSE) file.

### Issue Reporting

Any and all feedback is welcome.  Please let me know of any issues you may find in the bug tracker on github. You can find it [here. ](https://github.com/elegoev/basebox-ubuntu-18.04/issues)
