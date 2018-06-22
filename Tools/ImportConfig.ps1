<#
# ImportConfig.ps1
# Imports the CUSConfig.zip file (downloaded from Device Update Center) into the product directory
# and updates the input xmls with the required changes
#>

Param(
    [string] $productname,
    [string] $zipfile
)

################
# Main Function
################

$productdir = "$env:SRC_DIR\Products\$productname"
if (!(Test-Path $productdir)) {
    Write-Host "Error: $productdir not found." -ForegroundColor Red
    return
}
if (!(Test-Path $zipfile)) {
    Write-Host "Error: $zipfile not found." -ForegroundColor Red
    return
}

#check if config files are already present
$cfgdir = "$productdir\Packages\CUSConfig"
if (Test-Path $cfgdir){
    Write-Host "Error: CUSConfig files already exists."
    return
} else {
    New-Item $cfgdir -ItemType Directory | Out-Null
}

#unzip the file
Expand-Archive -Path $zipfile -DestinationPath $cfgdir
Write-Host "Updating OEMInputXML files"

$ocpfmfile = "%BLD_DIR%\MergedFMs\OCPUpdateFM.xml"

$files = Get-ChildItem -Path $productdir\ -File -Filter *OEMInput.xml | Foreach-Object {$_.FullName}
foreach ($file in $files) {
    $filename = Split-Path -Path $file -Leaf
    Write-Host "Processing $filename"
    $xmlfile = [xml] (Get-Content -Path $file)
    # add the FM file
    $node = $xmlfile.GetElementsByTagName("AdditionalFM") |  Where-Object { ($_.InnerText) -ieq $ocpfmfile }
    if ($node) {
        Write-Host "  Add OCPUpdateFM : Exists"
    }else{
        $fmnode = $xmlfile.OEMInput.AdditionalFMs
        $newfm = $xmlfile.CreateElement("AdditionalFM", "http://schemas.microsoft.com/embedded/2004/10/ImageUpdate")
        $newfm.InnerText = $ocpfmfile
        $retval = $fmnode.AppendChild($newfm)
        Write-Debug "$newfm added"
        Write-Host "  Add OCPUpdateFM : Added"
        $dirty = $true
    }
    # remove featureid IOT_GENERIC_POP
    $fid = "IOT_GENERIC_POP"
    $node = $xmlfile.GetElementsByTagName("Feature") |  Where-Object { ($_.InnerText) -ieq $fid }
    if ($node) {
        $parentnode = $node.ParentNode
        $oldnode = $parentnode.RemoveChild($node)
        Write-Host "  Remove $fid : Removed"
        Write-Debug "$oldnode removed"
        $dirty = $true
    } else {
        Write-Host "  Remove $fid : Skip, doesn't exist"
    }
    # add feature id CUS_DEVICE_INFO
    $fid = "CUS_DEVICE_INFO"
    $node = $xmlfile.GetElementsByTagName("Feature") |  Where-Object { ($_.InnerText) -ieq $fid }
    if ($node) {
        Write-Host "  Add $fid : Exists"
    } else {
        $node = $xmlfile.OEMInput.Features.OEM
        $newfid = $xmlfile.CreateElement("Feature","http://schemas.microsoft.com/embedded/2004/10/ImageUpdate")
        $newfid.InnerText = $fid
        $retval = $node.AppendChild($newfid)
        Write-Debug "$newfid added"
        Write-Host "  Add $fid : Added"
        $dirty = $true
    }
    if ($dirty) {
        $xmlfile.Save($file) | Out-Null
    }
}
