::Build-packages windows
@echo off
setlocal

set __PackageRID=win7-x64

:Arg_Loop
:: Since the native build requires some configuration information before msbuild is called, we have to do some manual args parsing
if [%1] == [] goto :PackageBuild
set __PackageRID=%1

:init-tools
call %~dp0init-tools.cmd %*
if NOT [%ERRORLEVEL%]==[0] exit /b 1

:PackageBuild
call msbuild /flp:v=diag "%~dp0\pkg\Libuv\Libuv.builds" /p:PackageRID=%__PackageRID% 2>&1
if NOT [%ERRORLEVEL%]==[0] (
  echo "Check msbuild path."
  exit /b %ERRORLEVEL%
)
