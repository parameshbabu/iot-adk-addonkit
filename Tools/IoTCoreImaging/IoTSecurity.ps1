<#
This contains Workspace related functions
#>
. $PSScriptRoot\IoTPrivateFunctions.ps1

function Import-IoTCertificate {
    <#
    .SYNOPSIS
    Imports an certificate and adds to the Workspace security specification.

    .DESCRIPTION
    Imports an certificate and adds to the Workspace security specification.
    For Secure boot functionality, it is mandatory to specify the PlatformKey and the KeyExchangeKey.
    For Bitlocker functionality, DataRecoveryAgent is required.
    For Device guard functionality, Update is mandatory.
    You will also need the following certs in the local cert store of the build machine (either installed directly or on a smart card).
    For signing purpose
     - Certificate with private key corresponding to PlatformKey
     - Certificate with private key corresponding to KeyExchangeKey
     For testing purposes, you can use the sample pfx files provided in the sample workspace and install them by double clicking on them.

    .PARAMETER CertFile
    Mandatory parameter, specifying the package name, typically of namespace.name format. Wild cards supported.

    .PARAMETER CertType
    Mandatory parameter specifying the cert type. The supported values are
    for secure boot  : "PlatformKey","KeyExchangeKey","Database"
    for bit locker   : "DataRecoveryAgent"
    for device guard : "Update","User","Kernel", "Root"
    See IoTWorkspace.xml for the cert definitions.

    .PARAMETER Test
    Switch parameter specifying if the certificate is test certificate

    .EXAMPLE
    Import-IoTCertificate $env:SAMPLEWKS\Certs\OEM-KEK.cer KeyExchangeKey
    Imports OEM-KEK.cer as a KeyExchangeKey certificate for secure boot policy. The cert is also copied to the workspace certs folder.

    .EXAMPLE
    Import-IoTCertificate $env:SAMPLEWKS\Certs\OEM-PK.cer PlatformKey
    Imports OEM-PK.cer as a Platform key certificate for secure boot policy. The cert is also copied to the workspace certs folder.

    .EXAMPLE
    Import-IoTCertificate $env:SAMPLEWKS\Certs\OEM-DRA.cer DataRecoveryAgent
    Imports OEM-DRA.cer as a DataRecoveryAgent certificate for bitlocker policy. The cert is also copied to the workspace certs folder.

    .EXAMPLE
    Import-IoTCertificate $env:SAMPLEWKS\Certs\OEM-KEK.cer Update
    Imports OEM-KEK.cer as a update certificate for device guard policy. The cert is also copied to the workspace certs folder.

    .EXAMPLE
    Import-IoTCertificate $env:SAMPLEWKS\Certs\OEM-UMCI.cer User
    Imports OEM-UMCI.cer as a user mode code signing certificate for device guard. The cert is also copied to the workspace certs folder.

    .NOTES
    See Add-IoT* and Import-IoT* methods.

    .LINK
    [New-IoTOEMCerts](New-IoTOEMCerts.md)
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$CertFile,
        [Parameter(Position = 1, Mandatory = $true)]
        [ValidateSet("PlatformKey", "KeyExchangeKey", "Database", "DataRecoveryAgent", "Update", "User", "Kernel", "Root")]
        [String]$CertType,
        [Parameter(Position = 2, Mandatory = $false)]
        [Switch]$Test
    )
    $IoTWsXml = $env:IOTWSXML
    if (!$IoTWsXml) {
        Publish-Error "IoTWorkspace not opened. Use Open-IoTWorkspace"
        return
    }
    $wsdoc = New-IoTWorkspaceXML $IoTWsXml
    $retval = $wsdoc.AddCertificate($CertFile, $CertType, $Test)
    if (!$retval) {
        Publish-Error "Failed to add certificate $CertFile as $CertType"
    }
}

function New-IoTOEMCerts {
    <#
    .SYNOPSIS
    Generates the required OEM certificates.

    .DESCRIPTION
    Generates the OEM certificates required for the secure boot, bit locker and the device guard features. This will prompt for the password when creating each certificate.

    .EXAMPLE
    New-IoTOEMCerts

    .NOTES
    See also Import-IoTCertificate.

    .LINK
    [Import-IoTCertificate](Import-IoTCertificate.md)
    #>
    [CmdletBinding()]

    $paths = (Get-ChildItem $env:WPDKCONTENTROOT\ -Filter "makecert.exe" -Recurse).FullName
    if ($paths) {
        foreach ($path in $paths) {
            if ($path.contains("x86\makecert.exe")) {
                $ToolsDir = Split-Path $path -Parent
                break
            }
        }
    }
    else {
        Publish-Error "makecert.exe not found. Install Windows 10 SDK for generating certs."
        return
    }

    $MakeCert = "$ToolsDir\makecert.exe"
    $pvkpfx = "$ToolsDir\pvk2pfx.exe"

    $outputDir = "$env:IOTWKSPACE\Certs"
    New-DirIfNotExist "$outputDir\private"
    $OemName = $env:OEM_NAME
    # Filenames
    $Root = "$outputDir\$OemName-Root"
    $RootPri = "$outputDir\private\$OemName-Root"
    $CA = "$outputDir\$OemName-CA"
    $CAPri = "$outputDir\private\$OemName-CA"
    $PCA = "$outputDir\$OemName-PCA"
    $PCAPri = "$outputDir\private\$OemName-PCA"
    $PK = "$outputDir\$OemName-RootPK"
    $PKPri = "$outputDir\private\$OemName-RootPK"
    $KEK = "$outputDir\$OemName-KEK"
    $KEKPri = "$outputDir\private\$OemName-KEK"
    $KMCI = "$outputDir\$OemName-KMCI"
    $KMCIPri = "$outputDir\private\$OemName-KMCI"
    $UMCI = "$outputDir\$OemName-UMCI"
    $UMCIPri = "$outputDir\private\$OemName-UMCI"
    $BitlockerDRA = "$outputDir\$OemName-DRA"
    $BitlockerDRAPri = "$outputDir\private\$OemName-DRA"

    $ReApply = Test-Path "$RootPri.pfx"
    if ($ReApply -eq $False) {
        Publish-Status "Creating $RootPri.pfx"
        & $MakeCert -r -pe -n "CN=$OemName Root" -ss CA -sr CurrentUser -a sha256 -len 4096 -cy authority -sky signature -sv "$RootPri.pvk" "$Root.cer"
        & $pvkpfx -pvk "$RootPri.pvk" -spc "$Root.cer" -pfx "$RootPri.pfx"
    }
    Import-IoTCertificate "$Root.cer" Root

    $ReApply = Test-Path "$CAPri.pfx"
    if ($ReApply -eq $False) {
        Publish-Status "Creating $CAPri.pfx"
        & $MakeCert -pe -n "CN=$OemName CA" -ss CA -sr CurrentUser -a sha256 -len 4096 -cy authority -sky signature -iv "$RootPri.pvk" -ic "$Root.cer" -sv "$CAPri.pvk" "$CA.cer"
        & $pvkpfx -pvk "$CAPri.pvk" -spc "$CA.cer" -pfx "$CAPri.pfx"
    }

    $ReApply = Test-Path "$PCAPri.pfx"
    if ($ReApply -eq $False) {
        $year = Get-Date -Format "yyyy"
        Publish-Status "Creating $PCAPri.pfx"
        & $MakeCert -pe -n "CN=$OemName Production PCA $year" -ss CA -sr CurrentUser -a sha256 -len 4096 -cy authority -sky signature -iv "$CAPri.pvk" -ic "$CA.cer" -sv "$PCAPri.pvk" "$PCA.cer"
        & $pvkpfx -pvk "$PCAPri.pvk" -spc "$PCA.cer" -pfx "$PCAPri.pfx"
    }

    $ReApply = Test-Path "$KMCIPri.pfx"
    if ($ReApply -eq $False) {
        Publish-Status "Creating $KMCIPri.pfx"
        & $MakeCert -pe -n "CN=$OemName KMCI Codesigning, E=Info@$OemName-Name.com" -sr CurrentUser -a sha256 -len 2048 -cy end -eku 1.3.6.1.5.5.7.3.3 -sky signature -iv "$PCAPri.pvk" -ic "$PCA.cer" -sv "$KMCIPri.pvk" "$KMCI.cer"
        & $pvkpfx -pvk "$KMCIPri.pvk" -spc "$KMCI.cer" -pfx "$KMCIPri.pfx"
    }
    Import-IoTCertificate "$KMCI.cer" Kernel

    $ReApply = Test-Path "$UMCIPri.pfx"
    if ($ReApply -eq $False) {
        Publish-Status "Creating $UMCIPri.pfx"
        & $MakeCert -pe -n "CN=$OemName UMCI Codesigning, E=Info@$OemName-Name.com" -sr CurrentUser -a sha256 -len 2048 -cy end -eku 1.3.6.1.5.5.7.3.3 -sky signature -iv "$PCAPri.pvk" -ic "$PCA.cer" -sv "$UMCIPri.pvk" "$UMCI.cer"
        & $pvkpfx -pvk "$UMCIPri.pvk" -spc "$UMCI.cer" -pfx "$UMCIPri.pfx"
    }
    Import-IoTCertificate "$UMCI.cer" User

    #Making PK a root cert
    $ReApply = Test-Path "$PKPri.pfx"
    if ($ReApply -eq $False) {
        Publish-Status "Creating $PKPri.pfx"
        & $MakeCert -r -pe -n "CN=$OemName Root Platform Key" -ss CA -sr CurrentUser -a sha256 -len 4096 -cy authority -sky signature -sv "$PKPri.pvk"  "$PK.cer"
        & $pvkpfx -pvk "$PKPri.pvk" -spc "$PK.cer" -pfx "$PKPri.pfx"
    }
    Import-IoTCertificate "$PK.cer" PlatformKey
    Import-IoTCertificate "$PK.cer" Root

    #KEK is derived out of PK instead of PCA
    $ReApply = Test-Path "$KEKPri.pfx"
    if ($ReApply -eq $False) {
        Publish-Status "Creating $KEKPri.pfx"
        & $MakeCert -pe -n "CN=$OemName KEK Secure Boot" -sr CurrentUser -a sha256 -len 4096 -cy end -sky signature -iv "$PKPri.pvk" -ic "$PK.cer" -sv "$KEKPri.pvk"  "$KEK.cer"
        & $pvkpfx -pvk "$KEKPri.pvk" -spc "$KEK.cer" -pfx "$KEKPri.pfx"
    }
    Import-IoTCertificate "$KEK.cer" KeyExchangeKey
    Import-IoTCertificate "$KEK.cer" Update

    $ReApply = Test-Path "$BitlockerDRAPri.pfx"
    if ($ReApply -eq $False) {
        Publish-Status "Creating $BitlockerDRAPri.pfx"
        & $MakeCert -pe -n "CN=$OemName Data Recovery Agent" -sr CurrentUser -a sha256 -len 2048 -cy end -eku 1.3.6.1.4.1.311.67.1.2 -sky exchange -iv "$PCAPri.pvk" -ic "$PCA.cer" -sv "$BitlockerDRAPri.pvk" "$BitlockerDRA.cer"
        & $pvkpfx -pvk "$BitlockerDRAPri.pvk" -spc "$BitlockerDRA.cer" -pfx "$BitlockerDRAPri.pfx"
    }
    Import-IoTCertificate "$BitlockerDRA.cer" DataRecoveryAgent

    Remove-Item "$outputDir\private\*.pvk" -Force
    if ($ReApply) {
        Publish-Warning "Certificates already exist. See $outputDir"
    }
    else {
        Publish-Success "Certificates created. See $outputDir"
    }
}

function Install-IoTOEMCerts {
    <#
    .SYNOPSIS
    Installs the OEM certs (pfx files) in the certs\private folder

    .DESCRIPTION
    Installs the OEM certs (pfx files) in the certs\private folder

    .EXAMPLE
    Install-IoTOEMCerts

    .NOTES
    See also Import-IoTCertificate and New-IoTOEMCerts.

    .LINK
    [Import-IoTCertificate](Import-IoTCertificate.md)
    .LINK
    [New-IoTOEMCerts](New-IoTOEMCerts.md)
 #>
    [CmdletBinding()]

    $pfxfiles = (Get-ChildItem $env:IOTWKSPACE\Certs\ -Filter "*.pfx" -Recurse).FullName
    if ($pfxfiles) {
        foreach ($pfxfile in $pfxfiles) {
            Publish-Status "Importing $pfxfile"
            #certutil -user -importpfx $pfxfile NoRoot
            Import-PfxCertificate -FilePath $pfxfile -CertStoreLocation Cert:\CurrentUser\My
        }
        Publish-Success "Importing successful"
    }
    else {
        Publish-Error "No .pfx files found to install"
    }
}
