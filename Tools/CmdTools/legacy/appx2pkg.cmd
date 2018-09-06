:: Run setenv before running this script
:: This script creates the folder structure and copies the template files for a new package
@echo off

goto START

:Usage
echo Usage: appx2pkg input.appx [fga/bgt/none] [CompName.SubCompName] [skipcert]
echo    input.appx.............. Required, input .appx file or .appxbundle
echo    fga/bgt/none............ Required, Startup ForegroundApp / Startup BackgroundTask / No startup
echo    CompName.SubCompName.... Optional, default is Appx.AppxName; Mandatory if you want to specify skipcert
echo    skipcert................ Optional, specify this to skip adding cert information to pkg xml file
echo    [/?].................... Displays this usage string.
echo    Example:
echo        appx2pkg C:\test\sample_1.0.0.0_arm.appx none
echo        appx2pkg C:\test\sample_1.0.0.0_arm.appxbundle none
endlocal
exit /b 1

:START

setlocal ENABLEDELAYEDEXPANSION
set STARTUP_OPTIONS=fga bgt none

if [%1] == [/?] goto Usage
if [%1] == [-?] goto Usage
if [%1] == [] goto Usage
if [%2] == [] goto Usage

set FILE_TYPE=%~x1
if not [%FILE_TYPE%] == [.appx] (
    if not [%FILE_TYPE%] == [.appxbundle] goto Usage
)

set LONG_NAME=%~n1
set FILE_NAME=%~n1
set "FILE_PATH=%~dp1"
set OUTPUT_PATH=%FILE_PATH%\Package
if not exist %OUTPUT_PATH% (
    mkdir %OUTPUT_PATH%
)
for /f "tokens=1 delims=_" %%i in ("%FILE_NAME%") do (
    set SHORT_FILE_NAME=%%i
)

call %TOOLS_DIR%\GetAppxInfo.exe "%1" > "%FILE_PATH%\appx_info.txt" 2>nul
for /f "tokens=1,2,3 delims=:,!, " %%i in (%FILE_PATH%\appx_info.txt) do (
    REM set APPX_%%i=%%j
    if [%%i] == [Version] (
        set APPX_Version=%%j
    )
    if [%%i] == [AppUserModelId] (
        set PACKAGE_FNAME=%%j
        set ENTRY=%%k
    )
)

if not defined PROV_VERSION (
    set PROV_VERSION=%APPX_Version%
)

if not defined PROV_RANK ( set PROV_RANK=0)
if not defined PROV_PATH ( 
    set PROV_PATH="$(runtime.windows)\Provisioning\Packages"
)

echo. Provisioning package version : %PROV_VERSION%
echo.                      rank    : %PROV_RANK%
echo.                      path    : %PROV_PATH%

for %%A in (%STARTUP_OPTIONS%) do (
    if [%%A] == [%2] (
        set STARTUP=%2
    )
)
if not defined STARTUP (
    echo. Error : Invalid Startup option.
    goto Usage
)

if [%3] == [] (
    set COMP_NAME=Appx
    set SUB_NAME=%SHORT_FILE_NAME%
) else (
    for /f "tokens=1,2 delims=." %%i in ("%3") do (
        set COMP_NAME=%%i
        set SUB_NAME=%%j
    )
    if /I [%4] == [skipcert] ( set SKIPCERT=1)
)

REM Start processing command
REM Get Appx dependencies
if exist "%FILE_PATH%\Dependencies\%ARCH%" (
    set DEP_PATH=Dependencies\%ARCH%
    dir /b "%FILE_PATH%\Dependencies\%ARCH%\*.appx" > "%FILE_PATH%\appx_deplist.txt" 2>nul
) else if exist "%FILE_PATH%\Dependencies" (
    set DEP_PATH=Dependencies
    dir /b "%FILE_PATH%\Dependencies\*.appx" > "%FILE_PATH%\appx_deplist.txt" 2>nul
) else if exist "%FILE_PATH%\%ARCH%" (
    set DEP_PATH=%ARCH%
    dir /b "%FILE_PATH%\%ARCH%\*.appx" > "%FILE_PATH%\appx_deplist.txt" 2>nul
) else (
    set DEP_PATH=.
    dir /b "%FILE_PATH%\*%ARCH%*.appx" > "%FILE_PATH%\appx_deplist.txt" 2>nul
)

if not defined SKIPCERT (
    dir /b "%FILE_PATH%\*.cer" > "%FILE_PATH%\appx_cerlist.txt" 2>nul
)

dir /b "%FILE_PATH%\*License*.xml" > "%FILE_PATH%\appx_license.txt" 2>nul
set /P LICENSE_FILE=<"%FILE_PATH%\appx_license.txt"
if defined LICENSE_FILE (
    for /f "tokens=8,9 delims==, " %%i in (%FILE_PATH%\%LICENSE_FILE%) do (
        if [%%i] == [LicenseID] (
            set LICENSE_ID=%%j
        )
    )
    echo. LicenseProductID : !LICENSE_ID!
)

echo. Authoring %COMP_NAME%.%SUB_NAME%.wm.xml
if exist "%FILE_PATH%\%COMP_NAME%.%SUB_NAME%.wm.xml" (del "%FILE_PATH%\%COMP_NAME%.%SUB_NAME%.wm.xml" )
call :CREATE_PKGFILE

set SRC_INFO_FILE=%OUTPUT_PATH%\SourceDetails.txt
echo Source Appx: %FILE_PATH%%FILE_NAME%%FILE_TYPE%>> "%SRC_INFO_FILE%"
echo Dependencies :>> "%SRC_INFO_FILE%"

REM Renaming files to shorten the appx names
for %%Z in ("%FILE_PATH%\appx_deplist.txt") do if %%~zZ gtr 0 (
    for /f "useback tokens=1,* delims=_" %%A in ("%FILE_PATH%\appx_deplist.txt") do (
        if [%%B] == [] (
            copy "%FILE_PATH%%DEP_PATH%\%%A" "%OUTPUT_PATH%\%%A" >nul 2>nul
            echo.%%A>>"%FILE_PATH%\appx_deplist_trim.txt"
            echo.%FILE_PATH%%DEP_PATH%\%%A>>"%SRC_INFO_FILE%"
        ) else (
            copy "%FILE_PATH%%DEP_PATH%\%%A_%%B" "%OUTPUT_PATH%\%%A.appx" >nul 2>nul
            echo.%%A.appx>>"%FILE_PATH%\appx_deplist_trim.txt"
            echo.%FILE_PATH%%DEP_PATH%\%%A_%%B>>"%SRC_INFO_FILE%"
        )
    )
)
REM Renaming files to shorten the cert names
for %%Z in ("%FILE_PATH%\appx_cerlist.txt") do if %%~zZ gtr 0 (
    echo Certificates : >> "%SRC_INFO_FILE%"
    for /f "useback tokens=1,* delims=_" %%A in ("%FILE_PATH%\appx_cerlist.txt") do (
        if [%%B] == [] (
            copy "%FILE_PATH%\%%A" "%OUTPUT_PATH%\%%A" >nul 2>nul
            echo.%%A>>"%FILE_PATH%\appx_cerlist_trim.txt"
            echo.%FILE_PATH%%%A>>"%SRC_INFO_FILE%"
        ) else (
            copy "%FILE_PATH%\%%A_%%B" "%OUTPUT_PATH%\%%A.cer" >nul 2>nul
            echo.%%A.cer>>"%FILE_PATH%\appx_cerlist_trim.txt"
            echo.%FILE_PATH%%%A_%%B>>"%SRC_INFO_FILE%"
        )
    )
)

echo. Authoring customizations.xml
if exist "%FILE_PATH%\customizations.xml" (del "%FILE_PATH%\customizations.xml" )
if not defined NEWGUID (
    REM Get a new GUID for the Provisioning config file
    powershell -Command "[System.Guid]::NewGuid().toString() | Out-File %PRODSRC_DIR%\uuid.txt -Encoding ascii"
    set /p NEWGUID=<%PRODSRC_DIR%\uuid.txt
    del %PRODSRC_DIR%\uuid.txt
)
call :CREATE_CUSTFILE

copy "%FILE_PATH%\%FILE_NAME%%FILE_TYPE%" "%OUTPUT_PATH%\%SHORT_FILE_NAME%%FILE_TYPE%" >nul 2>nul
move "%FILE_PATH%\customizations.xml" "%OUTPUT_PATH%\customizations.xml" >nul 2>nul
move "%FILE_PATH%\%COMP_NAME%.%SUB_NAME%.wm.xml" "%OUTPUT_PATH%\%COMP_NAME%.%SUB_NAME%.wm.xml" >nul 2>nul

if defined LICENSE_FILE (
    copy %FILE_PATH%\%LICENSE_FILE% %OUTPUT_PATH%\%SHORT_FILE_NAME%_License.ms-windows-store-license >nul 2>nul
    echo License : %FILE_PATH%%LICENSE_FILE%>> "%SRC_INFO_FILE%"
)

if not defined SKIPCERT (
    del "%FILE_PATH%\appx_cerlist.txt" >nul 2>nul
    del "%FILE_PATH%\appx_cerlist_trim.txt" >nul 2>nul
)

del "%FILE_PATH%\appx_license.txt" >nul 2>nul
del "%FILE_PATH%\appx_deplist.txt" >nul 2>nul
del "%FILE_PATH%\appx_deplist_trim.txt" >nul 2>nul
del "%FILE_PATH%\appx_info.txt" >nul 2>nul

endlocal
exit /b 0

:CREATE_PKGFILE
REM Printing the headers
call :PRINT_TEXT "<?xml version="1.0" encoding="utf-8"?>"
call :PRINT_TEXT "<identity xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance""
call :PRINT_TEXT "    name="%SUB_NAME%" namespace="%COMP_NAME%""
             echo.    owner="$(OEMNAME)" legacyName="$(OEMNAME).%COMP_NAME%.%SUB_NAME%">> "%FILE_PATH%\%COMP_NAME%.%SUB_NAME%.wm.xml"
call :PRINT_TEXT "    xmlns="urn:Microsoft.CompPlat/ManifestSchema.v1.00">"
call :PRINT_TEXT "    <onecorePackageInfo targetPartition="MainOS" releaseType="Production" ownerType="OEM" />"
call :PRINT_TEXT "    <files>"
call :PRINT_TEXT "        <file"
             echo.            destinationDir=%PROV_PATH%>> "%FILE_PATH%\%COMP_NAME%.%SUB_NAME%.wm.xml"
             echo.            source="$(BLDDIR)\ppkgs\%COMP_NAME%.%SUB_NAME%.ppkg">> "%FILE_PATH%\%COMP_NAME%.%SUB_NAME%.wm.xml"
call :PRINT_TEXT "            name="%COMP_NAME%.%SUB_NAME%.ppkg" />"
call :PRINT_TEXT "    </files>"
call :PRINT_TEXT "</identity>"
)
exit /b 0

:CREATE_CUSTFILE

REM Printing the headers
call :PRINT_TO_CUSTFILE "<?xml version="1.0" encoding="utf-8" ?>"
call :PRINT_TO_CUSTFILE "<WindowsCustomizations>"
call :PRINT_TO_CUSTFILE "  <PackageConfig xmlns="urn:schemas-Microsoft-com:Windows-ICD-Package-Config.v1.0">"
call :PRINT_TO_CUSTFILE "    <ID>{%NEWGUID%}</ID>"
call :PRINT_TO_CUSTFILE "    <Name>%SUB_NAME%Prov</Name>"
call :PRINT_TO_CUSTFILE "    <Version>%PROV_VERSION%</Version>"
call :PRINT_TO_CUSTFILE "    <OwnerType>OEM</OwnerType>"
call :PRINT_TO_CUSTFILE "    <Rank>%PROV_RANK%</Rank>"
call :PRINT_TO_CUSTFILE "  </PackageConfig>"
call :PRINT_TO_CUSTFILE "  <Settings xmlns="urn:schemas-microsoft-com:windows-provisioning">"
call :PRINT_TO_CUSTFILE "    <Customizations>"
call :PRINT_TO_CUSTFILE "      <Common>"
call :PRINT_TO_CUSTFILE "        <Policies>"
call :PRINT_TO_CUSTFILE "          <ApplicationManagement>"
call :PRINT_TO_CUSTFILE "            <AllowAllTrustedApps>Yes</AllowAllTrustedApps>"
call :PRINT_TO_CUSTFILE "          </ApplicationManagement>"
call :PRINT_TO_CUSTFILE "        </Policies>"

REM Printing Certificates
if not defined SKIPCERT (
    for %%B in ("%FILE_PATH%\appx_cerlist_trim.txt") do if %%~zB gtr 0 (
        call :PRINT_TO_CUSTFILE "        <Certificates>"
        call :PRINT_TO_CUSTFILE "          <RootCertificates>"
        for /f "useback delims=" %%A in ("%FILE_PATH%\appx_cerlist_trim.txt") do (
            call :PRINT_TO_CUSTFILE "            <RootCertificate CertificateName="%%~nA" Name="%%~nA">"
            call :PRINT_TO_CUSTFILE "              <CertificatePath>%%A</CertificatePath>"
            call :PRINT_TO_CUSTFILE "            </RootCertificate>"
        )
        call :PRINT_TO_CUSTFILE "          </RootCertificates>"
        call :PRINT_TO_CUSTFILE "        </Certificates>"
    ) else (
      echo. No Certificates. Skipping Certificate section.
    )
) else (
  echo. SkipCert defined. Skipping Certificate section.
)

REM Print startup configuration
if [%STARTUP%] == [fga] (
    call :PRINT_TO_CUSTFILE "        <StartupApp>"
    call :PRINT_TO_CUSTFILE "          <Default>"
    echo            %PACKAGE_FNAME%^^!%ENTRY% >> "%FILE_PATH%\customizations.xml"
    call :PRINT_TO_CUSTFILE "          </Default>"
    call :PRINT_TO_CUSTFILE "        </StartupApp>"
) else if [%STARTUP%] == [bgt] (
    call :PRINT_TO_CUSTFILE "        <StartupBackgroundTasks>"
    call :PRINT_TO_CUSTFILE "          <ToAdd>"
    call :PRINT_TO_CUSTFILE "            <Add PackageName="
    echo             "%PACKAGE_FNAME%^!%ENTRY%" >> "%FILE_PATH%\customizations.xml"
    call :PRINT_TO_CUSTFILE "            ></Add>"
    call :PRINT_TO_CUSTFILE "          </ToAdd>"
    call :PRINT_TO_CUSTFILE "        </StartupBackgroundTasks>"
) else (
    echo. No Startup configuration, skipping Startup section
)

REM Printing APP Install
call :PRINT_TO_CUSTFILE "        <UniversalAppInstall>"
call :PRINT_TO_CUSTFILE "          <UserContextApp>"
call :PRINT_TO_CUSTFILE "            <Application PackageFamilyName="%PACKAGE_FNAME%" Name="%PACKAGE_FNAME%">"
call :PRINT_TO_CUSTFILE "              <ApplicationFile>%SHORT_FILE_NAME%%FILE_TYPE%</ApplicationFile>"
REM Printing Dependencies
for %%B in ("%FILE_PATH%\appx_deplist_trim.txt") do if %%~zB gtr 0 (
    call :PRINT_TO_CUSTFILE "              <DependencyAppxFiles>"
    for /f "useback delims=" %%A in ("%FILE_PATH%\appx_deplist_trim.txt") do (
        if [%%A] NEQ [%SHORT_FILE_NAME%.appx] (
            call :PRINT_TO_CUSTFILE "                <Dependency Name="%%A">%%A</Dependency>"
        )
    )
    call :PRINT_TO_CUSTFILE "              </DependencyAppxFiles>"
) else (
  echo. No Dependencies found. Skipping Dependencies section.
)
call :PRINT_TO_CUSTFILE "              <DeploymentOptions>Force target application shutdown</DeploymentOptions>"
call :PRINT_TO_CUSTFILE "            </Application>"
call :PRINT_TO_CUSTFILE "          </UserContextApp>"

REM Print license file if present
if defined LICENSE_FILE (
    call :PRINT_TO_CUSTFILE "          <UserContextAppLicense>"
    REM call :PRINT_TO_CUSTFILE "            <LicenseInstall LicenseProductId=%LICENSE_ID% Name=%LICENSE_ID%>.\%LICENSE_FILE%</LicenseInstall>"
    call :PRINT_TO_CUSTFILE "            <LicenseInstall LicenseProductId=%LICENSE_ID% Name=%LICENSE_ID%>%SHORT_FILE_NAME%_License.ms-windows-store-license</LicenseInstall>"
    call :PRINT_TO_CUSTFILE "          </UserContextAppLicense>"
) else (
  echo. No License file. Skipping License section.
)

call :PRINT_TO_CUSTFILE "        </UniversalAppInstall>"

call :PRINT_TO_CUSTFILE "      </Common>"
call :PRINT_TO_CUSTFILE "    </Customizations>"
call :PRINT_TO_CUSTFILE "  </Settings>"
call :PRINT_TO_CUSTFILE "</WindowsCustomizations>"
)
exit /b 0

:PRINT_TEXT
for /f "useback tokens=*" %%a in ('%1') do set TEXT=%%~a
echo !TEXT!>> "%FILE_PATH%\%COMP_NAME%.%SUB_NAME%.wm.xml"
exit /b

:PRINT_TO_CUSTFILE
for /f "useback tokens=*" %%a in ('%1') do set TEXT=%%~a
echo !TEXT!>> "%FILE_PATH%\customizations.xml"
exit /b