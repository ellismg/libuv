::Build-native windows
@echo off
setlocal

set BUILD_TYPE=Debug
set HOST_OS=Windows_NT

set __binDir=%~dp0\bin
set __srcDir=%~dp0\src\libuv
set __TargetArch=x64
set __TargetOS=Windows_NT
set __binRuntimeDir=%~dp0\bin\%__TargetOS%.%__TargetArch%.%BUILD_TYPE%
set __buildOutputDir=%~dp0\src\libuv\%BUILD_TYPE%
:: All CI machines use this
set GYP_MSVS_VERSION=2015

:Arg_Loop
:: Since the native build requires some configuration information before msbuild is called, we have to do some manual args parsing
if [%1] == [] goto :ToolsVersion
if /i [%1] == [Release]     ( set BUILD_TYPE=release&&shift&goto Arg_Loop)
if /i [%1] == [Debug]       ( set BUILD_TYPE=debug&&shift&goto Arg_Loop)
if /i [%1] == [arm]         ( set __TargetArch=arm&&set __VCBuildArch=x86_arm&&set __SDKVersion="-DCMAKE_SYSTEM_VERSION=10.0"&&shift&goto Arg_Loop)
if /i [%1] == [x86]         ( set __TargetArch=x86&&set __VCBuildArch=x86&&shift&goto Arg_Loop)
if /i [%1] == [x64]         ( set __TargetArch=x64&&set __VCBuildArch=x86_amd64&&shift&goto Arg_Loop)
if /i [%1] == [arm64]       ( set __TargetArch=arm64&&set __VCBuildArch=arm64&&shift&goto Arg_Loop)

shift
goto :Arg_Loop

:: update sub module if required
set _TMP=
for /f "delims=" %%a in ('dir /b %__srcDir%') do set _TMP=%%a

IF {%_TMP%}=={} (
  echo "Updating submodule"
  set _update_submodule = "git submodule update --init --recursive"
  echo %_update_submodule%
  call %_update_submodule%
) ELSE (
  echo "Submodule already updated."
)

:ToolsVersion
:: Determine the tools version to pass to cmake/msbuild
if not defined VisualStudioVersion (
    if defined VS140COMNTOOLS (
        goto :VS2015
    ) 
    goto :MissingVersion
) 
if "%VisualStudioVersion%"=="14.0" (
    goto :VS2015
) 

:MissingVersion
:: Can't find VS 2015+
echo Error: Visual Studio 2015 required  
echo        Please see https://github.com/dotnet/corefx/blob/master/Documentation/project-docs/developer-guide.md for build instructions.
exit /b 1

:VS2015
:: Setup vars for VS2015
set __VSVersion=vs2015
set __PlatformToolset=v140
if NOT "%__TargetArch%" == "arm64" ( 
    :: Set the environment for the native build
    call "%VS140COMNTOOLS%\..\..\VC\vcvarsall.bat" %__VCBuildArch%
)
goto :SetupDirs

: Check for Python Installation
python --version 1>NUL 2>NUL
IF %ERRORLEVEL% == 1 (
echo "Install Python on path for Windows build."
exit /b %ERRORLEVEL%
)

:SetupDirs
:: Setup to cmake the native components
echo Commencing build of native components
echo.

echo %__srcDir%\vcbuild.bat %BUILD_TYPE% %__TargetArch% shared
call %__srcDir%\vcbuild.bat %BUILD_TYPE% %__TargetArch% shared

IF EXIST %__binDir% (
    rmdir /s /q  %__binDir% 2>&1
    IF %ERRORLEVEL% == 1 (
    echo "Unable to delete BinDir"
    )
)
mkdir %__binDir%
echo xcopy /E %__binRuntimeDir% %__buildOutputDir% 2>&1
xcopy /E %__binRuntimeDir% %__buildOutputDir% 2>&1
IF %ERRORLEVEL% == 1 (
  echo "Unable to copy output of submodule build"
  exit /b %ERRORLEVEL%
)
