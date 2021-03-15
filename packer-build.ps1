# run packer for vagrant virtualbox provider
$env:SRC_IMAGE_NAME = 'ubuntu/bionic64'
$env:SRC_IMAGE_VERSION = '20210224.0.0'

packer build packer-virtualbox.json 