#!/bin/bash

# get boxname
BASEBOXNAME=$(vagrant status --machine-readable | grep metadata | cut -d',' -f 2)
echo "BASEBOXNAME = $BASEBOXNAME"

GREEN='\033[0;32m'
READ='\033[0;31m'
NC='\033[0m'

echo "${GREEN}>>>> vagrant build started${NC}"

# output directory for vagrant box
BOXDIR="./box-virtualbox"
if [ -d $BOXDIR ]; then
  rm -fr $BOXDIR
  mkdir $BOXDIR
else
  mkdir $BOXDIR
fi

BOXBUILD=$(git rev-parse --short HEAD)
# BOXNAME="$BASEBOXNAME-$BOXVERSION"
BOXNAME="$BASEBOXNAME"
BOXFILENAME="$BOXNAME-$BOXBUILD.box"

echo "BASEBOXNAME: $BASEBOXNAME"
echo "BOXBUILD:    $BOXBUILD"
echo "BOXFILENAME  $BOXFILENAME"
echo "BOXDIR:      $BOXDIR"

### check metadata step
echo "${GREEN}>>>> check vagrant box on vagrant cloud${NC}"
CLOUDNAMESPACE="elegoev"
CLOUDCURRENTVERSION=$(vagrant cloud box show $CLOUDNAMESPACE/$BASEBOXNAME | grep current_version | awk  '{print $2}')
echo "CLOUDCURRENTVERSION = $CLOUDCURRENTVERSION"
METADATABUILD=$(echo $CLOUDCURRENTVERSION | cut -d'-' -f 2)
echo "METADATABUILD = $METADATABUILD"
echo "Build = $BOXBUILD"

if [[ "$BOXBUILD" == "$METADATABUILD" ]]; then
  echo "METADATABUILD:                $METADATABUILD"
  echo "${RED}>>>> Image for build $BOXBUILD already deployed${NC}"
  exit 1
else
  echo "${GREEN}>>>> Create new image for build ${BOXBUILD}${NC}"
fi

### get latest box step
echo "${GREEN}>>>> get latest basebox${NC}"
vagrant box update
echo "${GREEN}>>>> remove old baseboxes${NC}"
vagrant box prune

### create step
echo "${GREEN}>>>> create & provision vagrant box${NC}"
vagrant up
RETVAL=$?
if [ $RETVAL -ne 0 ] ; then
    vagrant destroy -f
    exit 1
fi

# get version
if [ -f "version" ]; then
  BOXVERSION=$(cat version)
else
  BOXVERSION="0.1.0-alpha"
fi

### export step
echo "${GREEN}>>>> export vagrant box (provider: virtualbox)${NC}"
vagrant package --base $BASEBOXNAME \
                --output $BOXDIR/$BOXFILENAME
mv $BOXDIR/$BOXFILENAME $BOXDIR/$BOXFILENAME.gz
gunzip $BOXDIR/$BOXFILENAME
tar rf $BOXDIR/$BOXFILENAME info.json
gzip $BOXDIR/$BOXFILENAME > /dev/null 2>&1
mv $BOXDIR/$BOXFILENAME.gz $BOXDIR/$BOXFILENAME
BOXSHA1HASHCODEVB=$(sha1sum $BOXDIR/$BOXFILENAME | awk  '{print $1}')

### create step for esxi image
echo "${GREEN}>>>> convert vagrant box (provider: vmware_esxi)${NC}"
ESXIBOXDIR="./box-esxi"
cp -r $BOXDIR $ESXIBOXDIR
cd $ESXIBOXDIR
mv $BOXFILENAME $BOXFILENAME.gz
gunzip $BOXFILENAME
tar xvf $BOXFILENAME > /dev/null 2>&1
rm $BOXFILENAME
sed -i -e 's/virtualbox-2.2/vmx-07/g' box.ovf
sed -i -e 's/sataController0/SCSIController/g' box.ovf
sed -i -e 's/SATA Controller/SCSI Controller/g' box.ovf
sed -i -e 's/AHCI/lsilogic/g' box.ovf
sed -i -e 's/<rasd:ResourceType>20</<rasd:ResourceType>6</g' box.ovf
sed -i -e 's/virtualbox/vmware_esxi/g' metadata.json
ovftool box.ovf box.vmx
rm box.ovf
rm box-disk001.vmdk
mkdir ./include
wget https://raw.githubusercontent.com/elegoev/vagrant-ubuntu-18.04/master/jenkins/vagrantfile/_Vagrantfile -o ./include/_Vagrantfile
tar cvf $BOXFILENAME . > /dev/null 2>&1
gzip $BOXFILENAME
mv $BOXFILENAME.gz $BOXFILENAME
cd ..
echo "Boxfile = $ESXIBOXDIR/$BOXFILENAME"
BOXSHA1HASHCODEESXI=$(sha1sum $ESXIBOXDIR/$BOXFILENAME | awk  '{print $1}')

### create metadata
echo "${GREEN}>>>> create metadata${NC}"
PARENTBOXNAME=$(cat ./provisioning/${BASEBOXNAME}.json | jq -r ".hostvars.vagrant_image")
PARENTBOXVERSION=$(vagrant box list | grep ${PARENTBOXNAME} |  awk  '{print $3}' | tr --delete ")")
echo "PARENTBOXNAME:        $PARENTBOXNAME"
echo "PARENTBOXVERSION:     $PARENTBOXVERSION"
echo "BOXSHA1HASHCODEVB:    $BOXSHA1HASHCODEVB"
echo "BOXSHA1HASHCODEESXI:  $BOXSHA1HASHCODEESXI"

### publish step
echo "${GREEN}>>>> start vagrant box publish${NC}"
CLOUDBOXNAME="$BASEBOXNAME"
CLOUDBOXVERSION="$BOXVERSION-$BOXBUILD"
CLOUDBOXPATHVB="$BOXDIR/$BOXFILENAME"
CLOUDBOXPATHESXI="$ESXIBOXDIR/$BOXFILENAME"
CLOUDSHORTDESC=$(cat info.json | jq -r ".Description")
CLOUDDESC=$CLOUDSHORTDESC
CLOUDVERSIONDESC="$(cat <<EOF
```json
{"build":"$BOXBUILD","parentbox":"$PARENTBOXNAME","parentboxversion":"$PARENTBOXVERSION","vbboxsha1hash":"$BOXSHA1HASHCODEVB","esxiboxsha1hash":"$BOXSHA1HASHCODEESXI"}
```
EOF
)"
echo "CLOUDVERSIONDESC = $CLOUDVERSIONDESC"
# publish for provider virtualbox
echo "${GREEN}>>>> publish vagrant box (provider: virtualbox)${NC}"
echo y | vagrant cloud publish "$CLOUDNAMESPACE/$CLOUDBOXNAME" "$CLOUDBOXVERSION" virtualbox "$CLOUDBOXPATHVB" \
                 --description "$CLOUDDESC" \
                 --short-description "$CLOUDSHORTDESC" \
                 --release \
                 --version-description "$CLOUDVERSIONDESC" \
                 --force
# publish for provider vmware_esxi
echo "${GREEN}>>>> publish vagrant box (provider: vmware_esxi)${NC}"
echo y | vagrant cloud publish "$CLOUDNAMESPACE/$CLOUDBOXNAME" "$CLOUDBOXVERSION" vmware_esxi "$CLOUDBOXPATHESXI" \
                 --description "$CLOUDDESC" \
                 --short-description "$CLOUDSHORTDESC" \
                 --release \
                 --version-description "$CLOUDVERSIONDESC" \
                 --force

### destroy step
echo "${GREEN}>>>> destroy vagrant basebox${NC}"
vagrant destroy -f

echo "${GREEN}>>>> vagrant build finished${NC}"
