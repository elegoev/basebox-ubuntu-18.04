#!/bin/bash

# get boxname
BASEBOXNAME=$(vagrant status --machine-readable | grep metadata | cut -d',' -f 2)
echo "BASEBOXNAME = $BASEBOXNAME"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}>>>> vagrant build started${NC}"

# output directory for vagrant box
BOXDIR="./box-virtualbox"
if [ -d $BOXDIR ]; then
  rm -fr $BOXDIR
  mkdir $BOXDIR
else
  mkdir $BOXDIR
fi

BOXBUILD="$(git rev-parse --short HEAD)"
# BOXNAME="$BASEBOXNAME-$BOXVERSION"
BOXNAME="$BASEBOXNAME"
BOXFILENAME="$BOXNAME-$BOXBUILD.box"

echo "BASEBOXNAME: $BASEBOXNAME"
echo "BOXBUILD:    $BOXBUILD"
echo "BOXFILENAME  $BOXFILENAME"
echo "BOXDIR:      $BOXDIR"

### get latest box step
echo -e "${GREEN}>>>> get latest basebox${NC}"
vagrant box update
echo -e "${GREEN}>>>> remove old baseboxes${NC}"
vagrant box prune

### create metadata
echo -e "${GREEN}>>>> create metadata${NC}"
PARENTBOXNAME=$(cat ./provisioning/${BASEBOXNAME}.json | jq -r ".hostvars.vagrant_image")
PARENTBOXVERSION=$(vagrant box list | grep ${PARENTBOXNAME} |  awk  '{print $3}' | tr --delete ")")

### check metadata step
echo -e "${GREEN}>>>> check vagrant box on vagrant cloud${NC}"
CLOUDNAMESPACE="elegoev"
CLOUDCURRENTVERSION=$(vagrant cloud box show $CLOUDNAMESPACE/$BASEBOXNAME | grep current_version | awk  '{print $2}')
CLOUDMETADATA=$(vagrant cloud box show $CLOUDNAMESPACE/$BASEBOXNAME --versions $CLOUDCURRENTVERSION | grep "parentboxversion")
# echo "METADATA = $CLOUDMETADATA"
# echo "CLOUDCURRENTVERSION = $CLOUDCURRENTVERSION"
METADATABUILD="$(echo $CLOUDCURRENTVERSION | cut -d'-' -f 2)"
METADATAPARENTBOXVERSION=$(echo $CLOUDMETADATA | jq -r ".parentboxversion")
echo "PARENTBOXNAME:            $PARENTBOXNAME"
echo "PARENTBOXVERSION:         $PARENTBOXVERSION"
echo "METADATAPARENTBOXVERSION: $METADATAPARENTBOXVERSION"
echo "BUILD:                    $BOXBUILD"
echo "METADATABUILD:            $METADATABUILD"

if [ "$BOXBUILD" == "$METADATABUILD" ]; then
  if [ "$PARENTBOXVERSION" == "$METADATAPARENTBOXVERSION" ]; then
     echo -e "${RED}>>>> Image for build $BOXBUILD already deployed${NC}"
     exit 0
  else
    echo -e "${GREEN}>>>> Create new image for parentbox $PARENTBOXNAME (PARENTBOXVERSION) ${NC}"
  fi
else
  echo -e "${GREEN}>>>> Create new image for build ${BOXBUILD}${NC}"
fi

### create step
echo -e "${GREEN}>>>> create & provision vagrant box${NC}"
vagrant up
RETVAL=$?
if [[ $RETVAL -ne 0 ]] ; then
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
echo -e "${GREEN}>>>> export vagrant box (provider: virtualbox)${NC}"
vagrant package --base $BASEBOXNAME \
                --output $BOXDIR/$BOXFILENAME
mv $BOXDIR/$BOXFILENAME $BOXDIR/$BOXFILENAME.gz
gunzip $BOXDIR/$BOXFILENAME
tar rf $BOXDIR/$BOXFILENAME info.json
gzip $BOXDIR/$BOXFILENAME > /dev/null 2>&1
mv $BOXDIR/$BOXFILENAME.gz $BOXDIR/$BOXFILENAME
BOXSHA1HASHCODEVB=$(sha1sum $BOXDIR/$BOXFILENAME | awk  '{print $1}')

### create step for esxi image
echo -e "${GREEN}>>>> convert vagrant box (provider: vmware_esxi)${NC}"
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
echo -e "Boxfile = $ESXIBOXDIR/$BOXFILENAME"
BOXSHA1HASHCODEESXI=$(sha1sum $ESXIBOXDIR/$BOXFILENAME | awk  '{print $1}')

### publish step
echo -e "${GREEN}>>>> start vagrant box publish${NC}"
CLOUDBOXNAME="$BASEBOXNAME"
CLOUDBOXVERSION="$BOXVERSION-$BOXBUILD"
CLOUDBOXPATHVB="$BOXDIR/$BOXFILENAME"
CLOUDBOXPATHESXI="$ESXIBOXDIR/$BOXFILENAME"
CLOUDSHORTDESC=$(cat info.json | jq -r ".Description")
CLOUDDESC=$CLOUDSHORTDESC
DESCMARKUPPREFIX=$"\`\`\`json"
DESCMARKUPPOSTFIX=$"\`\`\`"
CLOUDVERSIONDESC=$(cat <<EOF
${DESCMARKUPPREFIX}
{"build":"$BOXBUILD","parentbox":"$PARENTBOXNAME","parentboxversion":"$PARENTBOXVERSION","vbboxsha1hash":"$BOXSHA1HASHCODEVB","esxiboxsha1hash":"$BOXSHA1HASHCODEESXI"}
${DESCMARKUPPOSTFIX}
EOF
)

echo "CLOUDVERSIONDESC = $CLOUDVERSIONDESC"
# publish for provider virtualbox
echo -e "${GREEN}>>>> publish vagrant box (provider: virtualbox)${NC}"
echo y | vagrant cloud publish "$CLOUDNAMESPACE/$CLOUDBOXNAME" "$CLOUDBOXVERSION" virtualbox "$CLOUDBOXPATHVB" \
                 --description "$CLOUDDESC" \
                 --short-description "$CLOUDSHORTDESC" \
                 --release \
                 --version-description "$CLOUDVERSIONDESC" \
                 --force
RETVAL=$?
if [[ $RETVAL -ne 0 ]] ; then
   vagrant destroy -f
   exit 1
fi

# publish for provider vmware_esxi
echo -e "${GREEN}>>>> publish vagrant box (provider: vmware_esxi)${NC}"
echo y | vagrant cloud publish "$CLOUDNAMESPACE/$CLOUDBOXNAME" "$CLOUDBOXVERSION" vmware_esxi "$CLOUDBOXPATHESXI" \
                 --description "$CLOUDDESC" \
                 --short-description "$CLOUDSHORTDESC" \
                 --release \
                 --version-description "$CLOUDVERSIONDESC" \
                 --force
RETVAL=$?
if [[ $RETVAL -ne 0 ]] ; then
      vagrant destroy -f
      exit 1
fi

### destroy step
echo -e "${GREEN}>>>> destroy vagrant basebox${NC}"
vagrant destroy -f

echo -e "${GREEN}>>>> vagrant build finished${NC}"
