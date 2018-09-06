# Powershell version of IoT-ADK-Addonkit

Powershell version of the iot-adk-addonkit extends the functionality with further validation / verification steps in the imaging process.


## What's new in 6.0
* Support of Workspace concept : Workspace is a directory with IoTWorkspace.xml file specifying its attributes. This directory structure is similar to earlier iot-adk-addonkit without the tools and templates directory. You can now have multiple workspaces for building different products and use one common tooling directory.
* Sample Workspace : The addon kit comes with a sample workspace that you can access via the env variable SAMPLEWKS (`$env:SAMPLEWKS`). You can import oem packages, bsp and products from this workspace into your workspace for your use.
* Upgrade existing iot-adk-addonkit directory : You can upgrade your existing iot-adk-addonkit directory into a workspace, see [Work with Existing Workspace](#work-with-existing-workspace)
* Powershell functions and equivalent cmd functions available for many new features. See [Supported Functionality listing](#supported-functionality-listing).


## Get started

The pre-requisite for using this tools are same as the earlier iot-adk-addonkit projects.

Install the following pre-requisites
* [Windows 10 IoT Core Packages](https://www.microsoft.com/en-us/software-download/windows10iotcore)
* [Windows Assessment and Deployment Kit](https://developer.microsoft.com/windows/hardware/windows-assessment-deployment-kit)
* Get your BSP for your platform. See [Windows 10 IoT Core BSPs](https://docs.microsoft.com/en-us/windows-hardware/manufacture/iot/bsphardware) for links to get the BSPs. 
* Certificates - You will need to have these certificates (with private keys) in the local cert store ( either directly installed or loaded from a smart card)
    * Code signing certificate from a CA - Required for building retail image
    * Code signing EV certificate from a CA - Required to use Device Update Center
    * Security certificates from self - Required for the security features


## Work with New Workspace and Samples

Below are the steps to create a new workspace for imaging.

### Step 1: Create a workspace

1. Launch the IoTCorePShell ( Run `IoTCorePShell.cmd` ). This will launch the tool and also install the test certificates if required and opens the sample workspace present along with the tools by default.
2. Create a new workspace (say `C:\MyWorkspace` ) with the below command
    ```powershell
    New-IoTWorkspace C:\MyWorkspace Contoso arm
    (or) new-ws C:\MyWorkspace Contoso arm
    ```
    The Workspace will be created and opened. The required packages such as Registry.Version, Custom.Cmd and Provisioning.Auto will be imported into the workspace automatically. 
3. Import the required oem packages from the sample workspace (`$env:SAMPLEWKS`)
    ```powershell
    Import-IoTOEMPackage *
    (or) importpkg *
    ```
4. Import the required BSP (for example RPi2)
    ```powershell
    Import-IoTBSP RPi2
    (or) importbsp RPi2
    ```
    - For Intel BSPs, after you install them on your machine, you can import the bsp (say CHTx64) using 
        ```powershell
        Import-IntelBSP.ps1 <bspname>
        ```
    - For Qualcomm BSP, after downloading the zip file, you can extract the prebuilt cabs using 
        ```powershell
        # Import the QCDB410 BSP and extract the required cabs from the QC zip file
        Import-QCBSP.ps1  C:\BSP\db410c_bsp.zip C:\MyBSPs\ARM -ImportBSP
        ```
        Set `C:\MyBSPs\ARM` as the prebuilt package dir in the Workspace xml.

5. For importing an existing product, you can use the following command  
    ```powershell
    Import-IoTProduct RPiRecovery
    (or) importproduct RPiRecovery
    ```
    Now, the workspace has the necessary OEM packages, bsp and a product.

### Build a FFU

    Next steps are to build these to create an FFU.
1. Command to build package is
    ```powershell
    New-IoTCabPackage All
    (or) buildpkg all
    ```
2. Build the image for RPiRecovery product, test configuration.
    ```powershell
    New-IoTFFUImage RPiRecovery Test
    (or) buildimage RPiRecovery Test
    ```
    This will also build the necessary product specific packages and the fm files before starting the image creation.
3. Build the recovery FFU image with
    ```powershell
    New-IoTRecoveryImage RPiRecovery Test
    (or) buildrecovery RPiRecovery Test
    ```

### Building a Retail FFU
To build an retail image, you will need to retail sign all your packages and then create the FFU image.

1. Configure the code signing certificate for retail signing in the Workspace xml
    ```xml
    <!--Specify the retail signing certificate details, Format given below -->
    <RetailSignToolParam>/s my /i "Issuer" /n "Subject" /ac "C:\CrossCertRoot.cer" /fd SHA256</RetailSignToolParam>
    ```
    You could also specify the certificate by the thumbprint 
    ```xml
    <!--Specify the retail signing certificate details, Format given below -->
    <RetailSignToolParam>/s my /sha1 "thumbprint" /fd SHA256</RetailSignToolParam>
    ```

2. Enable retail signing with
    ```powershell
    Set-IoTRetailSign On
    (or) retailsign On
    ```
    This will set the sign tool parameter to the certificate specified as `RetailSignToolParam` in the Workspace xml. You will also see the prompt highlighting that the Retail mode is on. 
3. Rebuild all your packages with 
    ```powershell
    New-IoTCabPackage All
    (or) buildpkg all
    ```
4. If you have prebuilt cab packages, re-sign them using
    ```powershell
    Redo-IoTCabSignature <srccabdir> <dstcabdir>
    (or) re-signcabs <srccabdir> <dstcabdir>
    ```
    Set the BSPPkgDir setting to the `dstcabdir` in the product settings xml for retail configuration.
5. Build the image for retail configuration.
    ```powershell
    New-IoTFFUImage RPiRecovery Retail
    (or) buildimage RPiRecovery Retail
    ```
    This will also build the necessary product specific packages and the fm files before starting the image creation.
6. Build the Retail recovery FFU image with
    ```powershell
    New-IoTRecoveryImage RPiRecovery Retail
    (or) buildrecovery RPiRecovery Retail
    ```

## Work with Workspace and New contents

Steps to add new common package, appx package, driver package and finally a new product.

1. Add a new appx package using
    ```powershell
    Add-IoTAppxPackage C:\MyTest.appx fga
    (or) newappxpkg C:\MyTest.appx fga
    ```
    This also adds a feature id `APPX_MYTEST` in the OEMFM.xml file.
2. Add a new driver package using
    ```powershell
    Add-IoTDriverPackage C:\TestDriver\MyTest.inf
    (or) newdrvpkg C:\TestDriver\MyTest.inf
    ```
    This will copy all the files in the C:\TestDriver directory and also add a feature id `DRIVERS_MYTEST` in the OEMFM.xml file.
3. Add a common package using
    ```powershell
    Add-IoTCommonPackage Registry.MySettings
    (or) newcommonpkg Registry.MySettings
    ```
    This will add a feature id `REGISTRY_MYSETTINGS` in the OEMCOMMONFM.xml.
4. Create a new product (MyProduct) based on RPi2 BSP
    ```powershell
    Add-IoTProduct MyProduct RPi2
    (or) newproduct MyProduct RPi2
    ```
    This will prompt you for the SMBIOS values to be used in the product.
    You will also have a prompt for the BSP prebuilt directory for Retail/Test configurations that you can skip by pressing enter, if the defaults are already good.  `DeviceInventory_MyProduct.xml` is also generated which is used to register your device on the DUC portal.
5. Edit the OEMInputXML file to add the feature ids for the apps/driver and common package created above.
    ```powershell
    $product = New-IoTProduct MyProduct Test
    # specify the feature id with IsOEM true and $AllConfig true
    $product.AddFeatureID("APPX_TEST",$true,$true)
    $product.AddFeatureID("DRIVERS_MYTEST",$true,$true)
    $product.AddFeatureID("REGISTRY_MYSETTINGS",$true,$true)
    ```
6. Build the image
    ```powershell
    New-IoTFFUImage MyProduct Test
    (or) buildimage MyProduct Test
    ```
7. Create the product specific packages using 
    ```powershell
    # install test certificates from the sample workspace before running this
    #configure the certificates
    Import-IoTCertificate $env:SAMPLEWKS\Certs\OEM-PK.cer PlatformKey
    Import-IoTCertificate $env:SAMPLEWKS\Certs\OEM-UEFISB.cer KeyExchangeKey
    Import-IoTCertificate $env:SAMPLEWKS\Certs\OEM-DRA.cer DataRecoveryAgent
    Import-IoTCertificate $env:SAMPLEWKS\Certs\OEM-PAUTH.cer Update
    Import-IoTCertificate $env:SAMPLEWKS\Certs\OEM-UMCI.cer User
    Add-IoTSecurityPackages -Test
    ```
    This is the automated process for the detailed steps defined in [Turnkey Security on IoT Core](https://docs.microsoft.com/windows/iot-core/secure-your-device/securebootandbitlocker#turnkey-security-on-iot-core)
8. Now that the new security packages are created, include the Security features `Sec_BitLocker`,`Sec_SecureBoot` and `Sec_DeviceGuard` in the oeminputxml file and regenerate the FFU as per step 6. 
    ```powershell
    $product = New-IoTProduct MyProduct Test
    # specify the feature id with IsOEM true and $AllConfig true
    $product.AddFeatureID("Sec_BitLocker",$true,$true)
    $product.AddFeatureID("Sec_SecureBoot",$true,$true)
    $product.AddFeatureID("Sec_DeviceGuard",$true,$true)
    # build the image
    New-IoTFFUImage MyProduct Test
    ```
9. Create the recovery enabled FFU using
    ```powershell
    New-IoTRecoveryImage MyProduct Test
    (or) buildrecovery MyProduct Test
    ```
10. With the ffu created, you can mount the ffu using the following commands 
    ```powershell
    # mounts the ffu image
    Mount-IoTFFUImage C:\..\Flash.ffu
    # get the drive letters used - for information only
    Get-IoTFFUDrives
    #Dismount the image
    Dismount-IoTFFUImage
    ```

## Work with Existing Workspace

Steps to upgrade your existing iot-adk-addonkit project directory.

1. Launch the IoTCorePShell ( Run `IoTCorePShell.cmd` ). This will launch the tool and also install the test certificates if required and opens the sample workspace present along with the tools by default.

2. Run the migration command for the existing repo dir say `C:\Myproject\iot-adk-addonkit`, 
    ```powershell
    Redo-IoTWorkspace C:\Myproject\iot-adk-addonkit
    (or) migrate C:\Myproject\iot-adk-addonkit
    ```
    This command will generate the workspace xml file and product specific settings file that is required for rest of the scripts to work. The SMBIOS data for the product will be set to default and you will be required to update them to the proper values. For Qualcomm based products, the SMBIOS values from the SMBIOS.cfg will be used.

3. The tools and templates directory under your repo is not required anymore. These can be deleted ( note that the above command does not delete these folders, but moves them to a ToDelete folder).
4. Open this workspace and start using this as a new workspace described above. 
    ```powershell
    Open-IoTWorkspace C:\Myproject\iot-adk-addonkit\IoTWorkspace.xml
    (or) open-ws C:\Myproject\iot-adk-addonkit\IoTWorkspace.xml
    ```

## Work with Device Update Center

Steps to register your device on the device update center and publish updates are given below.

1. Register with the Device Update Center portal. You will require an EV cert for this process.
2. Configure the EV cert used in the Device Update Center in the Workspace.
    ```xml
        <!--Specify the ev signing certificate details, Format given below -->
        <EVSignToolParam>/s my /i "Issuer" /n "Subject" /fd SHA256</EVSignToolParam>
    ```
3. Create a product
    ```powershell
    New-IoTProduct SampleA RPi2
    (or) newproduct SampleA RPi2
    ```
    You will find an device inventory file `IoTDeviceModel_<product>.xml`. Use this file to register your device model in the DUC portal. If you change the SMBIOS fields or install a different IoTCore Kit version, you can regenerate this file using 
    ```powershell
    Export-IoTDeviceModel SampleA
    (or) exportidm SampleA
    ```
4. Once the device model is registered in the portal, you can download `CUSConfig.zip` file from the portal. You can then import this file into the product configuration using
    ```powershell
    Import-IoTDUCConfig SampleA "C:\Users\MyUser\Downloads\CUSConfig.zip"
    (or) importcfg SampleA "C:\Users\MyUser\Downloads\CUSConfig.zip"
    ```
    This will create a CUSConfig folder in the Product\Packages directory and also update the oeminput xml files.
5. Rebuild the image with the CUSConfig included. This will be the base shipping image for your device model.
    ```powershell
    New-IoTFFUImage SampleA Retail
    (or) buildimage SampleA Retail
    ```
6. When you have new update to create, **modify/update the OEM package contents** and increment the BSP_VERSION
    ```powershell
    Set-IoTCabVersion 10.0.1.0
    (or) setversion 10.0.1.0
    ```
7. Rebuild your packages and build your ffu image with the updated packages. Validate this FFU for functionality. You can then export the update package using
    ```powershell
    Export-IoTDUCCab SampleA Retail
    (or) exportpkgs SampleA Retail
    ```
    This will create a cab file under `$env:BUILD_DIR\<product>\<Config>\$env:BSP_VERSION`
8. You can upload this cab in the DUC portal.


## Supported Functionality listing

The supported functionality are listed below in logical groups.

| Function Name | Alias      |  CmdTools  | Remarks |
| :------------ |:-----------|:----------------|:--------|
| **Workspace Functions** | - | - | - |
|[New-IoTWorkspace](.\IoTCoreImaging\Docs\New-IoTWorkspace.md) | new-ws | new-ws.cmd | New functionality added|
|[Open-IoTWorkspace](.\IoTCoreImaging\Docs\Open-IoTWorkspace.md) | open-ws | open-ws.cmd | New functionality added|
|[Redo-IoTWorkspace](.\IoTCoreImaging\Docs\Redo-IoTWorkspace.md) | migrate | migrate.cmd | New functionality added|
|[Import-IoTOEMPackage](.\IoTCoreImaging\Docs\Import-IoTOEMPackage.md) | importpkg | importpkg.cmd | New functionality added|
|[Import-IoTProduct](.\IoTCoreImaging\Docs\Import-IoTProduct.md) | importproduct | importproduct.cmd | New functionality added|
|[Import-IoTBSP](.\IoTCoreImaging\Docs\Import-IoTBSP.md) | importbsp | importbsp.cmd | New functionality added|
|[Import-IoTCertificate](.\IoTCoreImaging\Docs\Import-IoTCertificate.md) | - | - | Imports the certificate for security functions|
|[Copy-IoTOEMPackage](.\IoTCoreImaging\Docs\Copy-IoTOEMPackage.md) | copypkg | TBD | New functionality added|
|[Copy-IoTProduct](.\IoTCoreImaging\Docs\Copy-IoTProduct.md) | copyproduct | TBD | New functionality added|
|[Copy-IoTBSP](.\IoTCoreImaging\Docs\Copy-IoTBSP.md) | copybsp | copybsp.cmd | New functionality added|
|[Add-IoTAppxPackage](.\IoTCoreImaging\Docs\Add-IoTAppxPackage.md) | newappxpkg | newappxpkg.cmd | Adds the feature id to the FM file automatically |
|[Add-IoTDriverPackage](.\IoTCoreImaging\Docs\Add-IoTDriverPackage.md) | newdrvpkg | newdrvpkg.cmd | Adds the feature id to the FM file automatically |
|[Add-IoTCommonPackage](.\IoTCoreImaging\Docs\Add-IoTCommonPackage.md) | newcommonpkg | newcommonpkg.cmd | Adds the feature id to the FM file automatically |
|[Add-IoTFilePackage](.\IoTCoreImaging\Docs\Add-IoTFilePackage.md) | - | - | Adds a file package and adds the feature id to the FM file automatically |
|[Add-IoTRegistryPackage](.\IoTCoreImaging\Docs\Add-IoTRegistryPackage.md) | - | - | Adds a registry package and adds the feature id to the FM file automatically |
|[Add-IoTProvisioningPackage](.\IoTCoreImaging\Docs\Add-IoTProvisioningPackage.md) | newprovpkg | newprovpkg.cmd | New functionality added |
|[Add-IoTBSP](.\IoTCoreImaging\Docs\Add-IoTBSP.md) | newbsp | newbsp.cmd | Adds new bsp based on a template |
|[Add-IoTProduct](.\IoTCoreImaging\Docs\Add-IoTProduct.md) | newproduct | newproduct.cmd | Adds new product  |
|[Add-IoTSecurityPackages](.\IoTCoreImaging\Docs\Add-IoTSecurityPackages.md) | -  | - | Adds security packages for the product  |
|[Get-IoTWorkspaceProducts](.\IoTCoreImaging\Docs\Get-IoTWorkspaceProducts.md) | gwsproducts | gwsproducts.cmd | Gets the list of product names in the workspace |
|[Get-IoTWorkspaceBSPs](.\IoTCoreImaging\Docs\Get-IoTWorkspaceBSPs.md) | gwsbsps | gwsbsps.cmd | Gets the list of BSP names in the workspace |
| **Build Functions** | - | - | - |
|[Set-IoTCabVersion](.\IoTCoreImaging\Docs\Set-IoTCabVersion.md) | setversion | setversion.cmd | Stores the version in the IoTWorkspace.xml |
|[New-IoTCabPackage](.\IoTCoreImaging\Docs\New-IoTCabPackage.md) | buildpkg | buildpkg.cmd | Creates `.cab` files  |
|[New-IoTProvisioningPackage](.\IoTCoreImaging\Docs\New-IoTProvisioningPackage.md)| buildppkg | buildppkg.cmd | Creates `.ppkg` files |
|[New-IoTFIPPackage](.\IoTCoreImaging\Docs\New-IoTFIPPackage.md)| buildfm | buildfm.cmd | Creates FIP packages and merged FM files |
|[New-IoTFFUImage](.\IoTCoreImaging\Docs\New-IoTFFUImage.md)| buildimage | buildimage.cmd | Creates regular FFU |
|[New-IoTRecoveryImage](.\IoTCoreImaging\Docs\New-IoTRecoveryImage.md)| buildrecovery | buildrecovery.cmd | Creates recovery FFU |
|[New-IoTWindowsImage](.\IoTCoreImaging\Docs\New-IoTWindowsImage.md)| createwinpe | createwinpe.cmd | Creates custom winpe with bsp drivers / recovery scripts |
|[Test-IoTRecoveryImage](.\IoTCoreImaging\Docs\Test-IoTRecoveryImage.md)| verifyrecovery | verifyrecovery.cmd | Verifies if the wim files in the recovery ffu are proper |
| **Env Functions** | - | - | - |
|[Set-IoTEnvironment](.\IoTCoreImaging\Docs\Set-IoTEnvironment.md) | setenv | setenv.cmd | Sets environment settings based on the config values in IoTWorkspace.xml  |
|[Convert-IoTPkg2Wm](.\IoTCoreImaging\Docs\Convert-IoTPkg2Wm.md) | convertpkg | convertpkg.cmd | Converts pkg.xml files to wm.xml files  |
|[Get-IoTProductFeatureIDs](.\IoTCoreImaging\Docs\Get-IoTProductFeatureIDs.md)| gpfids | gpfids.cmd | Gets features IDs supported in the IoTCore OS |
|[Get-IoTProductPackagesForFeature](.\IoTCoreImaging\Docs\Get-IoTProductPackagesForFeature.md)| gpfidpkgs | gpfidpkgs.cmd | Gets OS packages corresponding to features ID |
| **DUC Functions** | - | - | - |
|[Export-IoTDeviceModel](.\IoTCoreImaging\Docs\Export-IoTDeviceModel.md) | exportidm | exportidm.cmd | Exports the IoT Device Model for DUC registration |
|[Import-IoTDUCConfig](.\IoTCoreImaging\Docs\Import-IoTDUCConfig.md) | importcfg | importcfg.cmd | Imports the CUSConfig.zip into the product directory |
|[Export-IoTDUCCab](.\IoTCoreImaging\Docs\Export-IoTDUCCab.md) | exportpkgs | exportpkgs.cmd | Exports the update cab for DUC upload |
| **FFU Functions** | - | - | - |
|[Mount-IoTFFUImage](.\IoTCoreImaging\Docs\Mount-IoTFFUImage.md) | ffum | - | Mounts the FFU image |
|[Dismount-IoTFFUImage](.\IoTCoreImaging\Docs\Dismount-IoTFFUImage.md) | ffud | - | Dismounts the FFU image  |
|[Export-IoTFFUAsWims](.\IoTCoreImaging\Docs\Export-IoTFFUAsWims.md) | ffue | - | Exports the EFIESP/MainOS/Data partitions as Wims  |
|[New-IoTFFUCIPolicy](.\IoTCoreImaging\Docs\New-IoTFFUCIPolicy.md) | ffus | - | Scans the MainOS partition and generates CI policy (`initialpolicy.xml`) |
|[Get-IoTFFUDrives](.\IoTCoreImaging\Docs\Get-IoTFFUDrives.md) | ffugd | - | Returns a hashtable of the drive letters for the mounted partitions |
| **Signing/Test Functions** | - | - | - |
|[Set-IoTSignature](.\IoTCoreImaging\Docs\Set-IoTSignature.md) | setsignature | setsignature.cmd | Sets the Certificate info used for signing |
|[Test-IoTSignature](.\IoTCoreImaging\Docs\Test-IoTSignature.md) | TBD | - | Tests if the file is signed for the given config  |
|[Test-IoTCabSignature](.\IoTCoreImaging\Docs\Test-IoTCabSignature.md) | TBD | - | Tests if the Cab package and its contents are signed for the given config  |
|[Test-IoTPackages](.\IoTCoreImaging\Docs\Test-IoTPackages.md) | TBD | - | Tests all packages and its contents are signed, for the given product / config  |
|[Test-IoTFeatures](.\IoTCoreImaging\Docs\Test-IoTFeatures.md) | TBD | - | Tests if all feature ids are defined, for the given product / config  |
|[Add-IoTSignature](.\IoTCoreImaging\Docs\Add-IoTSignature.md) | signbinaries | signbinaries.cmd | Signs files with the cert set via Set-IoTSignature  |
|[Redo-IoTCabSignature](.\IoTCoreImaging\Docs\Redo-IoTCabSignature.md) | re-signcabs | re-signcabs.cmd | Resigns cab and its contents using Add-IoTSignature  |

### Class Documentation

| Class Name |  Factory Method | Remarks |
| :------------ |:--------|:--------|
|[IoTDeviceLayout](.\IoTCoreImaging\Docs\Classes\IoTDeviceLayout.md) |[New-IoTDeviceLayout](.\IoTCoreImaging\Docs\New-IoTDeviceLayout.md) | Class for managing Device Layout xml   |
|[IoTFMXML](.\IoTCoreImaging\Docs\Classes\IoTFMXML.md) |[New-IoTFMXML](.\IoTCoreImaging\Docs\New-IoTFMXML.md)| Class for managing Feature Manifest xml  |
|[IoTProvisioningXML](.\IoTCoreImaging\Docs\Classes\IoTProvisioningXML.md)|[New-IoTProvisioningXML](.\IoTCoreImaging\Docs\New-IoTProvisioningXML.md) | Class for managing Provisioning XML (Customisations.xml)  |
|[IoTWorkspaceXML](.\IoTCoreImaging\Docs\Classes\IoTWorkspaceXML.md)| [New-IoTWorkspaceXML](.\IoTCoreImaging\Docs\New-IoTWorkspaceXML.md) | Class for managing Workspace xml  |
|[IoTOemInputXML](.\IoTCoreImaging\Docs\Classes\IoTOemInputXML.md)|[New-IoTOemInputXML](.\IoTCoreImaging\Docs\New-IoTOemInputXML.md)| Class for managing OEMInput.xml  |
|[IoTProductSettingsXML](.\IoTCoreImaging\Docs\Classes\IoTProductSettingsXML.md) |[New-IoTProductSettingsXML](.\IoTCoreImaging\Docs\New-IoTProductSettingsXML.md)| Class for managing IoT Product settings xml |
|[IoTWMXML](.\IoTCoreImaging\Docs\Classes\IoTWMXML.md)|[New-IoTWMXML](.\IoTCoreImaging\Docs\New-IoTWMXML.md) | Class for managing windows manifest xml  |
|[IoTWMWriter](.\IoTCoreImaging\Docs\Classes\IoTWMWriter.md)|[New-IoTWMWriter](.\IoTCoreImaging\Docs\New-IoTWMWriter.md) | Class for writing windows manifest xml  |
|[IoTProduct](.\IoTCoreImaging\Docs\Classes\IoTProduct.md) |[New-IoTProduct](.\IoTCoreImaging\Docs\New-IoTProduct.md)| Class for managing IoT Product configuration  |

## Certificates
See [Windows Secure Boot Key Creation and Management Guidance](https://docs.microsoft.com/windows-hardware/manufacture/desktop/windows-secure-boot-key-creation-and-management-guidance)

### Quick download links
The same certs are also available in the `Tools\Certificates\Retail` folder.

* Microsoft KEK certificate: [MicCorKEKCA2011_2011-06-24.cer](http://go.microsoft.com/fwlink/?LinkId=321185)
* Windows CA: [MicWinProPCA2011_2011-10-19.cer](http://go.microsoft.com/fwlink/p/?linkid=321192)
* Microsoft UEFI CA: [MicCorUEFCA2011_2011-06-27.cer](http://go.microsoft.com/fwlink/p/?LinkID=321194)

