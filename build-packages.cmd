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

if not defined VisualStudioVersion (
  if defined VS140COMNTOOLS (
    call "%VS140COMNTOOLS%\VsDevCmd.bat"
    goto :Run
  )
  echo Error: Visual Studio 2015 required.
  echo        Please see https://github.com/dotnet/corefx/blob/master/Documentation/project-docs/developer-guide.md for build instructions.
  exit /b 1
)

:Run
call %~dp0init-tools.cmd
if NOT [%ERRORLEVEL%]==[0] exit /b 1

:PackageBuild
call %~dp0Tools\msbuild.cmd /flp:v=diag "%~dp0pkg\Libuv\Libuv.builds" /p:PackageRID=%__PackageRID% /p:ConfigurationGroup=%BUILD_TYPE%
if NOT [%ERRORLEVEL%]==[0] exit /b 1
