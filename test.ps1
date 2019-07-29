
$metadata="{`"test1`":`"xxxx`",`"test2`":`"yyyy`"}"
echo $metadata
$cloudversiondesc = $metadata
echo $cloudversiondesc
$versionops = "--version-description " + $cloudversiondesc
echo $versionops

$versionstr = "`````json `
{```""test1```"":```""xxxx```",```"""test2```""":```"yyyy```"""} `
``````"


echo y | vagrant cloud publish "elegoev/ubuntu-18.04" "200000001" virtualbox "./box/ubuntu-18.04-18.04.201907262240-9848d96.box" `
                 --description "Testbeschreibung" `
                 --short-description "Testshortbeschreibung" `
                 --release `
                 --version-description $versionstr
