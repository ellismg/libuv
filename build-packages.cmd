::Build-packages windows
@echo off
setlocal

set __PackageRID=win7-x64
set BUILD_TYPE=Debug

:Arg_Loop
if [%1] == [] goto :Args_Done
if /i [%1] == [--configuration] (
  if /i [%2] == [release] ( set BUILD_TYPE=Release&&shift&&shift&&goto Arg_Loop )
  if /i [%2] == [debug]   ( set BUILD_TYPE=Debug&&shift&&shift&&goto Arg_Loop )
  echo "Unknown Configuration: '%2'"
  exit /b 1
)
if /i [%1] == [--runtime-id] ( set __PackageRID=%2&&shift&&shift&&goto Arg_Loop )
echo "Unknown Argument: '%1'
exit /b 1

:Args_Done
call %~dp0init-tools.cmd %*
if NOT [%ERRORLEVEL%]==[0] exit /b 1

:PackageBuild
call msbuild /flp:v=diag "%~dp0\pkg\Libuv\Libuv.builds" /p:PackageRID=%__PackageRID% /p:ConfigurationGroup=%BUILD_TYPE% 2>&1
if NOT [%ERRORLEVEL%]==[0] (
  echo "Check msbuild path."
  exit /b %ERRORLEVEL%
)
