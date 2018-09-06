@echo off

goto START

:Usage
echo Usage: convertpkg [CompName.SubCompName]/[packagefile.pkg.xml]/[All]
echo    packagefile.pkg.xml....... Package definition XML file
echo    CompName.SubCompName...... Package ComponentName.SubComponent Name
echo    All....................... All packages under \Packages directory are built
echo        One of the above should be specified
echo    [/?]...................... Displays this usage string.
echo    Example:
echo        convertpkg sample.pkg.xml
echo        convertpkg Appx.Main
echo        convertpkg All

exit /b 1

:START

pushd
setlocal ENABLEDELAYEDEXPANSION

if not defined PKGBLD_DIR (
    echo Environment not defined. Call setenv
    exit /b 1
)
if not exist %PKGLOG_DIR% ( mkdir %PKGLOG_DIR% )

REM Input validation

if [%1] == [/?] goto Usage
if [%1] == [-?] goto Usage
if [%1] == [] goto Usage

REM Add variables for pkg2wm
set PKGGEN_VAR=_RELEASEDIR=$(_RELEASEDIR);PROD=$(PROD);PRJDIR=$(PRJDIR);COMDIR=$(COMDIR);BSPVER=$(BSPVER)
set PKGGEN_VAR=%PKGGEN_VAR%;BSPARCH=$(BSPARCH);OEMNAME=$(OEMNAME);BUILDTIME=$(BUILDTIME);BLDDIR=%BLD_DIR%
REM if you encounter the following error, add the symbol here
REM (PkgBldr.Common) : error : Undefined variable runtime.clipAppLicenseInstall
set PKGGEN_VAR=%PKGGEN_VAR%;runtime.clipAppLicenseInstall=$(runtime.clipAppLicenseInstall)

if /I [%1] == [All] (

    dir %COMMON_DIR%\Packages\*.pkg.xml /S /b > %PKGLOG_DIR%\packagelist.txt 2>nul
    dir %SRC_DIR%\*.pkg.xml /S /b >> %PKGLOG_DIR%\packagelist.txt 2>nul
    call :SUB_PROCESSLIST %PKGLOG_DIR%\packagelist.txt
    
) else (
    if [%~x1] == [.xml] (
        echo %1 > %PKGLOG_DIR%\packagelist.txt
    ) else (
        if exist "%PKGSRC_DIR%\%1" (
            REM Enabling support for multiple .pkg.xml files in one directory.
            dir "%PKGSRC_DIR%\%1\*.pkg.xml" /S /b > %PKGLOG_DIR%\packagelist.txt 2>nul
        ) else if exist "%COMMON_DIR%\Packages\%1" (
            REM Enabling support for multiple .pkg.xml files in one directory.
            dir "%COMMON_DIR%\Packages\%1\*.pkg.xml" /S /b > %PKGLOG_DIR%\packagelist.txt 2>nul
        ) else if exist "%1" (
            REM Enabling support for multiple .pkg.xml files in one directory.
            dir "%1\*.pkg.xml" /S /b > %PKGLOG_DIR%\packagelist.txt 2>nul
        ) else if exist "%COMMON_DIR%\ProdPackages\%1" (
            REM Nothing to do here. Skip
        ) else (
            REM Check if its in BSP path
            cd /D "%BSPSRC_DIR%"
            dir "%1" /S /B > %PKGLOG_DIR%\packagedir.txt 2>nul
            set /P RESULT=<%PKGLOG_DIR%\packagedir.txt
            if not defined RESULT (
                echo.%CLRRED%Error : %1 not found.%CLREND%
                goto Usage
            ) else (
                if !RESULT! NEQ "" (
                   dir "!RESULT!\*.pkg.xml" /S /B > %PKGLOG_DIR%\packagelist.txt 2>nul
                )
            )
        )
    )
    if exist %PKGLOG_DIR%\packagelist.txt (
        call :SUB_PROCESSLIST %PKGLOG_DIR%\packagelist.txt
    )
)
if exist %PKGLOG_DIR%\packagelist.txt ( del %PKGLOG_DIR%\packagelist.txt )
if exist %PKGLOG_DIR%\packagedir.txt ( del %PKGLOG_DIR%\packagedir.txt )

endlocal
popd
exit /b

REM -------------------------------------------------------------------------------
REM
REM SUB_PROCESSLIST <filename>
REM
REM Processes the file list, calls pkggen /convert:pkg2wm for each item in the list
REM
REM -------------------------------------------------------------------------------
:SUB_PROCESSLIST

if %~z1 gtr 0 (
    echo. %CLRYEL%.pkg.xml files found. Review generated .wm.xml files for correctness%CLREND%
    for /f "delims=" %%i in (%1) do (
       echo. Converting %%~nxi
       set NAME=%%~dpni
       set NAME=!NAME:~0,-4!
       REM echo Name: !NAME!
       call pkggen.exe "%%i" /convert:pkg2wm /output:"!NAME!.wm.xml" /useLegacyName:true /foroempkg:true /variables:"%PKGGEN_VAR%" >nul
       if not errorlevel 0 ( echo.%CLRRED%Error : Failed to create package. See %PKGLOG_DIR%\%%~ni.log%CLREND%)
       REM Rename the pkg.xml file to _pkg.xml file
       move "%%i" "!NAME!._pkg.xml" >nul
    )
) else (
    echo. No .pkg.xml files found.
)

exit /b
