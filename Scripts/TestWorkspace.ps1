param([string] $workspacedir)

if([string]::IsNullOrWhiteSpace($workspacedir)) { $workspacedir ="$env:USERPROFILE\TestWkspace" }
if (Test-Path $workspacedir) {
    Remove-Item -Path $workspacedir -Recurse -Force | Out-Null
}
Write-Host "Creating workspace at $workspacedir"
new-ws $workspacedir Contoso arm

# import packages from the sample workspace (same as the tools dir path currently)
importpkg *
importbsp RPi2
importproduct RPiRecovery

$product = "RPiRecovery"
$config = "Test"

#Cleanup all build directories
$result = buildpkg Clean
#build all packages
$result = buildpkg all
if (!$result) { 
    Publish-Error "New-IoTCabPackage failed"
    return
}
#check feature ids
$gfids = gpfids
if ($gfids.Count -eq 0) { 
    Publish-Error "Get-IoTProductFeatureIDs failed"
    return
}

buildimage $product $config

createwinpe $product $config

buildrecovery $product $config

verifyrecovery $product $config

$prod = New-IoTProduct $product $config
$ffufile = $prod.FFUName
Mount-IoTFFUImage $ffufile
New-IoTFFUCIPolicy
Dismount-IoTFFUImage
