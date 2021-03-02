# set build environment
$env:SRC_IMAGE_NAME = 'ubuntu/bionic64'
$env:SRC_IMAGE_VERSION = '20210224.0.0'

# run vagrant
vagrant up

# delete ubuntu log file
$LogFileName = '.\ubuntu-bionic-18.04-cloudimg-console.log'
if (Test-Path $LogFileName) {
  Remove-Item $LogFileName
}

