@echo off

rem ============================================================= SETUP

for %%f in ("*.uproject") do set PROJECT_NAME=%%f
if defined PROJECT_NAME goto PROJECT_NAME_DEFINED
echo could not find a `.uproject` file
exit /B
:PROJECT_NAME_DEFINED

set PROJECT_NAME=%PROJECT_NAME:~0,-9%
echo PROJECT_NAME: %PROJECT_NAME%

for /f "tokens=2" %%t in (
	'find "EngineAssociation" %PROJECT_NAME%.uproject'
) do set UNREAL_VERSION=%%t

set UNREAL_VERSION=%UNREAL_VERSION:~1,-2%
echo UNREAL_VERSION: %UNREAL_VERSION%

set ROOTDIR=%~dp0
set ROOTDIR=%ROOTDIR:~0,-1%

set PROJECT_DIR=%ROOTDIR%
set UPROJECT_PATH=%PROJECT_DIR%\%PROJECT_NAME%.uproject

if defined UE4_DIR goto UE4_DIR_DEFINED
for /f "tokens=3" %%t in (
	'reg query "HKLM\Software\EpicGames\Unreal Engine\%UNREAL_VERSION%%" /v InstalledDirectory'
) do set UE4_DIR=%%t
:UE4_DIR_DEFINED

echo UE4_DIR: %UE4_DIR%

set UE4EDITOR=%UE4_DIR%\Engine\Binaries\Win64\UE4Editor.exe
set UE4EDITOR_CMD=%UE4_DIR%\Engine\Binaries\Win64\UE4Editor-cmd.exe
set BATCH_FILES_DIR=%UE4_DIR%\Engine\Build\BatchFiles

set ACTION=%1

rem ============================================================= HELP ACTION
if "%ACTION%" EQU "h" set ACTION=help
if "%ACTION%" NEQ "help" goto HELP_END

echo HELP
echo available subcommands:
echo " h help - show this help"
echo " c clean - clean build artifacts"
echo " b build - build C++ project sources"
echo " r run - run project without opening the editor"
echo " p package [platform=Win64] - package project for `platform`"
echo " gcc generate-compile-commands - generate `compile_commands.json` file for use with clangd server"
exit /B

:HELP_END

rem ============================================================= CLEAN ACTION
if "%ACTION%" EQU "c" set ACTION=clean
if "%ACTION%" NEQ "clean" goto CLEAN_END

echo CLEANING...
call %BATCH_FILES_DIR%\Clean.bat %PROJECT_NAME%Editor Win64 Development "%UPROJECT_PATH%"
exit /B

:CLEAN_END

rem ============================================================= BUILD ACTION
if "%ACTION%" EQU "b" set ACTION=build
if "%ACTION%" NEQ "build" goto BUILD_END

echo BUILDING...
call %BATCH_FILES_DIR%\Build.bat %PROJECT_NAME%Editor Win64 Development "%UPROJECT_PATH%" -waitmutex -NoHotReload
exit /B

:BUILD_END

rem ============================================================= RUN ACTION
if "%ACTION%" EQU "r" set ACTION=run
if "%ACTION%" NEQ "run" goto RUN_END

echo RUNNING...
start "" "%UE4EDITOR%" "%UPROJECT_PATH%" -game -log -windowed -resx=1280 -resy=720
exit /B

:RUN_END

rem ============================================================= PACKAGE ACTION
if "%ACTION%" EQU "p" set ACTION=package
if "%ACTION%" NEQ "package" goto PACKAGE_END

set TARGET_PLATFORM=%2
if not defined TARGET_PLATFORM set TARGET_PLATFORM=Win64
echo PACKAGING FOR %TARGET_PLATFORM%...
call %BATCH_FILES_DIR%\RunUAT.bat -ScriptsForProject="%UPROJECT_PATH%" BuildCookRun -nocompileeditor -installed -nop4 -project="%UPROJECT_PATH%" -cook -stage -archive -archivedirectory="%PROJECT_DIR%\Build" -package -pak -prereqs -nodebuginfo -targetplatform=%TARGET_PLATFORM% -build -target=NekoNeko -clientconfig=Development -serverconfig=Development -utf8output
exit /B

:PACKAGE_END

rem ============================================================= GENERATE COMPILE COMMANDS ACTION
if "%ACTION%" EQU "gcc" set ACTION=generate-compile-commands
if "%ACTION%" NEQ "generate-compile-commands" goto GENERATE_COMPILE_COMMANDS_END

echo GENERATING COMPILE COMMANDS
call %UE4_DIR%\Engine\Binaries\DotNET\UnrealBuildTool.exe -mode=GenerateClangDatabase -project=%UPROJECT_PATH% -game -engine %PROJECT_NAME%Editor Development Win64 Development
move %UE4_DIR%\compile_commands.json %PROJECT_DIR%
exit /B

:GENERATE_COMPILE_COMMANDS_END

echo for more options invoke with `help` subcommand
