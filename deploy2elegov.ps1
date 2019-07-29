## deploy vagrant box to vagrant cloud
#

# prepare environment
#
#         vagrant cloud auth login elegoev
#


$CLOUDSHORTDESC = Get-Content info.json | jq -r ".Description"

vag-bp -custboxname "ubuntu-18.04" `
       -targetns "elegoev" `
       -targetrepo vagrantcloud `
       -boxdesc "$CLOUDSHORTDESC" `
       -versiondesc ""
