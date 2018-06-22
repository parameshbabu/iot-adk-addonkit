@echo off

goto START

:Usage
echo Usage: importcfg [Product] [Filename]
echo    ProductName....... Required, Name of the product
echo....Filename.......... Required, The path for the CUSConfig.zip file to be imported
echo    [/?]...................... Displays this usage string.
echo    Example:
echo        exportidm SampleA C:\Downloads\CUSConfig.zip

exit /b 1

:START
if not defined PKGBLD_DIR (
    echo Environment not defined. Call setenv
    exit /b 1
)
REM Input validation
if [%1] == [/?] goto Usage
if [%1] == [-?] goto Usage
if [%1] == [] goto Usage
if [%2] == [] goto Usage

if not exist %SRC_DIR%\Products\%1 (
   echo %1 not found. Available products listed below
   dir /b /AD %SRC_DIR%\Products
   goto Usage
)

powershell -executionpolicy unrestricted  -Command ("%TOOLS_DIR%\ImportConfig.ps1 %*")
exit /b

