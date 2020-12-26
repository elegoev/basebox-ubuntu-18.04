# cleanup task

# delete ubuntu log file
Push-Location
Set-Location "./packer_build_dir"
if($?) {
  vagrant destroy -f
}
Pop-Location

# call cleanup
Write-Host "$PSScriptRoot\post-processors\cleanup.ps1"
Invoke-Expression "$PSScriptRoot\post-processors\cleanup.ps1"
