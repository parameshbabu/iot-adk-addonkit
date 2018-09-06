<#
    .SYNOPSIS
    Function to import QC BSP into your workspace and update the bsp files as required by the latest tools
    
    .DESCRIPTION
    Function to import QC BSP into your workspace and update the bsp files as required by the latest tools
    
    .PARAMETER BSPZipFile
    Mandatory parameter, BSP Zip file from QC
    
    .PARAMETER BSPPkgDir
    Mandatory parameter, Location where to extract the required BSP cab files

    .PARAMETER ImportBSP
    Optional switch parameter, to import the QCDB410C BSP

    .EXAMPLE
    Import-QCBSP C:\Temp\db410c_bsp.zip C:\QCBSP
    
    .NOTES
    You will need to download the QC BSP from the QC website first before using this method. 
    #>
[CmdletBinding()]
Param
(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateScript( { Test-Path $_ -PathType Leaf })]
    [String]$BSPZipFile,
    [Parameter(Position = 1, Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$BSPPkgDir,
    [Parameter(Position = 2, Mandatory = $false)]
    [Switch]$ImportBSP
)

if ($env:ARCH -ine "arm") {
    Write-Error "Incorrect architecture. setenv arm"
    return
}
if ($ImportBSP){
    Import-IoTBSP QCDB410C
}
$qcfmxml = "$env:BSPSRC_DIR\QCDB410C\Packages\QCDB410CFM.xml"

New-DirIfNotExist $BSPPkgDir -Force

$fmobj = New-IoTFMXML $qcfmxml
$pkglist = $fmobj.GetPackageNames()
#skipping parsing QCDB410CTestFM.xml. Just one entry hardcoded here.
$pkglist += "Qualcomm.QC8916.UEFI.cab" 

$exceptionlist = @(
    'Qualcomm.QC8916.OEMDevicePlatform.cab'
    'Qualcomm.QC8916.qcMagAKM8963.cab'
    'Qualcomm.QC8916.qcAlsPrxAPDS9900.cab'
    'Qualcomm.QC8916.qcAlsCalibrationMTP.cab'
    'Qualcomm.QC8916.qcTouchScreenRegsitry1080p.cab'
)

#Expand-Archive -Path $BSPZipFile -DestinationPath $BSPPkgDir
Add-Type -Assembly System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead($BSPZipFile)
$zip.Entries | Where-Object {$_.Name -like '*.cab'} | ForEach-Object {
    $filename = Split-Path -Path $_ -Leaf
    if ($pkglist -contains $filename) {
        if ($exceptionlist -contains $filename) {
            Write-Debug "---> Exception $filename"
            $filepath = Split-Path -Path $_ -Parent
            $dirname = Split-Path -Path $filepath -Leaf
            if ($filename -ieq "Qualcomm.QC8916.OEMDevicePlatform.cab") {
                if (($dirname -ieq "SBC") -and (!($filepath.Contains("8916")))) {
                    Write-Host "Extracting $_"
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, "$BSPPkgDir\$filename", $true)
                }
                else { Write-Debug "Skipping $_" }
            }
            else {
                #For other exception files, take content from MTP directory
                if ($dirname -ieq "MTP") {
                    Write-Host "Extracting $_"
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, "$BSPPkgDir\$filename", $true)
                }
                else { Write-Debug "Skipping $filepath" }
            }
        }
        else {
            Write-Host "Extracting $_"
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, "$BSPPkgDir\$filename", $true)
        }
    }
}
$zip.Dispose()
