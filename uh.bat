@echo off
setlocal EnableDelayedExpansion

echo unreal helper v1.1
echo.

rem ============================================================= SETUP
for %%f in ("*.uproject") do set PROJECT_NAME=%%f
if not defined PROJECT_NAME (
	echo could not find a ".uproject" file
	exit /b
)

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

if not defined UE4_DIR (
	for /f "tokens=2* skip=1" %%t in (
		'reg query "HKLM\Software\EpicGames\Unreal Engine\%UNREAL_VERSION%" /v InstalledDirectory'
	) do set UE4_DIR=%%u
)
echo UE4_DIR: %UE4_DIR%

if not defined VS_DIR (
	for /d %%d in ("%programfiles(x86)%\Microsoft Visual Studio\*") do if exist "%%d\Community" ( set VS_DIR=%%d )
)
echo VS_DIR: %VS_DIR%
set VS_PATH=%VS_DIR%\Community\Common7\IDE\devenv

echo.

set UE4EDITOR=%UE4_DIR%\Engine\Binaries\Win64\UE4Editor.exe
set BATCH_FILES_DIR=%UE4_DIR%\Engine\Build\BatchFiles

set IS_DEBUGGING=
set ACTION=%1
set TAIL_PARAMS=%*
call set TAIL_PARAMS=%%TAIL_PARAMS:*%1=%%

if "%ACTION%" EQU "h" ( goto ACTION_HELP )
if "%ACTION%" EQU "help" ( goto ACTION_HELP )
if "%ACTION%" EQU "c" ( goto ACTION_CLEAN )
if "%ACTION%" EQU "clean" ( goto ACTION_CLEAN )
if "%ACTION%" EQU "e" ( goto ACTION_OPEN_EDITOR )
if "%ACTION%" EQU "editor" ( goto ACTION_OPEN_EDITOR )
if "%ACTION%" EQU "de" ( goto ACTION_DEBUG_EDITOR )
if "%ACTION%" EQU "debug-editor" ( goto ACTION_DEBUG_EDITOR )
if "%ACTION%" EQU "s" ( goto ACTION_OPEN_SOLUTION )
if "%ACTION%" EQU "solution" ( goto ACTION_OPEN_SOLUTION )
if "%ACTION%" EQU "b" ( goto ACTION_BUILD )
if "%ACTION%" EQU "build" ( goto ACTION_BUILD )
if "%ACTION%" EQU "r" ( goto ACTION_RUN )
if "%ACTION%" EQU "run" ( goto ACTION_RUN )
if "%ACTION%" EQU "dr" ( goto ACTION_DEBUG_RUN )
if "%ACTION%" EQU "debug-run" ( goto ACTION_DEBUG_RUN )
if "%ACTION%" EQU "p" ( goto ACTION_PACKAGE )
if "%ACTION%" EQU "package" ( goto ACTION_PACKAGE )
if "%ACTION%" EQU "gcc" ( goto ACTION_GENERATE_COMPILE_COMMANDS )
if "%ACTION%" EQU "generate-compile-commands" ( goto ACTION_GENERATE_COMPILE_COMMANDS )

if defined ACTION (
	echo unknown action "%ACTION%" && echo try invoking with "help" subcommand
) else (
	echo for more options, invoke with "help" subcommand
)
exit /b

:ACTION_HELP
rem ============================================================= HELP ACTION
echo HELP
echo - h help : show this help
echo - e editor [map] : open editor, optionally directly opening `map`
echo - de debug-editor [map] : same as `editor` but debugging through visual studio
echo - s solution : open visual studio solution
echo - c clean : clean build artifacts
echo - b build : build C++ project sources
echo - r run [instance-count] [map] : run game without opening the editor
echo                                : optionally running `instance-count` game instances
echo                                : optionally directly running `map`
echo                                : also, instead of a map name, it's possible to pass `client`
echo                                : in order to just connect to an already running host
echo - dr debug-run [instance-count] [map] : same as `run` but debugging the host instance through visual studio
echo - p package [platform=Win64] : package project for `platform`
echo - gcc generate-compile-commands : generate "compile_commands.json" file for use with clangd server
exit /b

:ACTION_CLEAN
rem ============================================================= CLEAN ACTION
set CLI=call "%BATCH_FILES_DIR%\Clean.bat" "%PROJECT_NAME%Editor" Win64 Development "%UPROJECT_PATH%" %TAIL_PARAMS%
if defined VERBOSE ( echo %CLI% && echo. )
echo CLEANING...
echo.
%CLI%
rmdir /s /q Build
rmdir /s /q Binaries
exit /b

:ACTION_OPEN_EDITOR
rem ============================================================= OPEN EDITOR ACTION
set TARGET_MAP=%~2
if defined TARGET_MAP (
	rem call set TAIL_PARAMS=%%TAIL_PARAMS:*%2=%%
)
set CLI="%UE4EDITOR%" "%UPROJECT_PATH%" "%TARGET_MAP%" %TAIL_PARAMS%
if defined IS_DEBUGGING (
	set CLI="%VS_PATH%" /debugexe %CLI%
) else (
	set CLI=start "" %CLI%
)
if defined VERBOSE ( echo %CLI% && echo. )
if defined IS_DEBUGGING ( echo DEBUG OPENING EDITOR... ) else ( echo OPENING EDITOR... )
%CLI%
exit /b

:ACTION_DEBUG_EDITOR
rem ============================================================= DEBUG EDITOR ACTION
set IS_DEBUGGING=true
goto ACTION_OPEN_EDITOR

:ACTION_OPEN_SOLUTION
rem ============================================================= OPEN SOLUTION ACTION
set CLI="%VS_PATH%" %PROJECT_DIR%\%PROJECT_NAME%.sln
if defined VERBOSE ( echo %CLI% && echo. )
echo OPENING SOLUTION...
%CLI%
exit /b

:ACTION_BUILD
rem ============================================================= BUILD ACTION
set CLI=call "%BATCH_FILES_DIR%\Build.bat" "%PROJECT_NAME%Editor" Win64 Development "%UPROJECT_PATH%" -waitmutex -NoHotReload %TAIL_PARAMS%
if defined VERBOSE ( echo %CLI% && echo. )
echo BUILDING...
echo.
%CLI%
exit /b %ERRORLEVEL%

:ACTION_RUN
rem ============================================================= RUN ACTION
set RESX=960
set RESY=540
set PORT=17777
set GAME_USER_SETTINGS=%PROJECT_DIR%\Saved\Config\Windows\PIEGameUserSettings

set TARGET_MAP=%~2
if defined TARGET_MAP (
	call set TAIL_PARAMS=%%TAIL_PARAMS:*%2=%%
)

set /a INSTANCE_COUNT=TARGET_MAP + 0
if "%INSTANCE_COUNT%" EQU "%TARGET_MAP%" (
	set TARGET_MAP=%~3
	if defined TARGET_MAP (
		call set TAIL_PARAMS=%%TAIL_PARAMS:*%3=%%
	)
)

if "%TARGET_MAP%" EQU "client" (
	set TARGET_MAP=127.0.0.1:%PORT%
) else (
	set TARGET_MAP="%TARGET_MAP%?Listen" -port=%PORT%
)

set SERVER_CLI="%UE4EDITOR%" "%UPROJECT_PATH%" %TARGET_MAP% -game -log -windowed -resx=%RESX% -resy=%RESY% SAVEWINPOS=1 -SessionName=Session GameUserSettingsINI="%GAME_USER_SETTINGS%0.ini" %TAIL_PARAMS%
if defined IS_DEBUGGING (
	set SERVER_CLI="%VS_PATH%" /debugexe %SERVER_CLI%
) else (
	set SERVER_CLI=start "" %SERVER_CLI%
)

set CLIENT_CLI=start "" "%UE4EDITOR%" "%UPROJECT_PATH%" 127.0.0.1:%PORT% -game -log -windowed -resx=%RESX% -resy=%RESY% SAVEWINPOS=1 -SessionName=Session
set /a CLIENT_COUNT=%INSTANCE_COUNT% - 1
if defined VERBOSE (
	echo %SERVER_CLI%
	for /l %%i in (1,1,%CLIENT_COUNT%) do (
		echo %CLIENT_CLI% GameUserSettingsINI="%GAME_USER_SETTINGS%%%i.ini" %TAIL_PARAMS%
	)
	echo.
)
if defined IS_DEBUGGING ( echo DEBUG RUNNING... ) else ( echo RUNNING... )
%SERVER_CLI%
for /l %%i in (1,1,%CLIENT_COUNT%) do (
	%CLIENT_CLI% GameUserSettingsINI="%GAME_USER_SETTINGS%%%i.ini" %TAIL_PARAMS%
)
exit /b

:ACTION_DEBUG_RUN
rem ============================================================= DEBUG RUN ACTION
set IS_DEBUGGING=true
goto ACTION_RUN

:ACTION_PACKAGE
rem ============================================================= PACKAGE ACTION
set TARGET_PLATFORM=%~2
if defined TARGET_PLATFORM (
	call set TAIL_PARAMS=%%TAIL_PARAMS:*%2=%%
) else (
	set TARGET_PLATFORM=Win64
)
set CLI=call "%BATCH_FILES_DIR%\RunUAT.bat" -ScriptsForProject="%UPROJECT_PATH%" BuildCookRun -nocompileeditor -installed -nop4 -project="%UPROJECT_PATH%" -cook -stage -archive -archivedirectory="%PROJECT_DIR%\Build" -package -pak -prereqs -targetplatform=%TARGET_PLATFORM% -build -target="%PROJECT_NAME%" -clientconfig=Development -serverconfig=Development -crashreporter -utf8output %TAIL_PARAMS%
if defined VERBOSE ( echo %CLI% && echo. )
echo PACKAGING FOR %TARGET_PLATFORM%...
echo.
%CLI%
exit /b %ERRORLEVEL%

:ACTION_GENERATE_COMPILE_COMMANDS
rem ============================================================= GENERATE COMPILE COMMANDS ACTION
echo GENERATING COMPILE COMMANDS...
echo.
call "%UE4_DIR%\Engine\Binaries\DotNET\UnrealBuildTool.exe" -mode=GenerateClangDatabase -project="%UPROJECT_PATH%" -game -engine "%PROJECT_NAME%Editor" Win64 Development %TAIL_PARAMS%
move "%UE4_DIR%\compile_commands.json" "%PROJECT_DIR%"
exit /b
