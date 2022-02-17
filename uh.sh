#!/usr/bin/env sh

set -e

# ============================================================= SETUP

PROJECT_NAME=$(ls *.uproject | head -n 1 | xargs basename -s .uproject)
if test -z $PROJECT_NAME
then
	echo "could not find a '.uproject' file"
	exit
fi

echo "PROJECT_NAME: $PROJECT_NAME"

UNREAL_VERSION=$(grep "EngineAssociation" $PROJECT_NAME.uproject | cut -d '"' -f 4)
echo "UNREAL_VERSION: $UNREAL_VERSION"

PROJECT_DIR=$PWD
UPROJECT_PATH="$PROJECT_DIR/$PROJECT_NAME.uproject"

if test -z $UE4_DIR
then
	echo '$UE4_DIR not defined'
	exit
fi

echo "UE4_DIR: $UE4_DIR"

UE4EDITOR="$UE4_DIR/Engine/Binaries/Linux/UE4Editor"
BATCH_FILES_DIR="$UE4_DIR/Engine/Build/BatchFiles/Linux"

INSTALL_TARGET="/usr/local/bin/uh"

ACTION=$1
TAIL_PARAMS="${@:2}"

# ============================================================= HELP ACTION
if test "$ACTION" = "h" || test "$ACTION" = "help"
then
	echo "HELP"
	echo

	echo "available subcommands:"
	echo "- h help : show this help"
	echo "- install : install this script to '$INSTALL_TARGET'"
	echo "- o open : open project"
	echo "- c clean : clean build artifacts"
	echo "- b build : build C++ project sources"
	echo "- r run : run project without opening the editor"
	echo "- p package [platform=Linux] : package project for 'platform'"
	echo "- gcc generate-compile-commands : generate 'compile_commands.json' file for use with clangd server"

	exit
fi

# ============================================================= INSTALL ACTION
if test "$ACTION" = "install"
then
	echo "INSTALLING UNREAL HELPER TO '$INSTALL_TARGET'..."

	sudo cp $0 $INSTALL_TARGET
	sudo chmod +x $INSTALL_TARGET

	exit
fi

# ============================================================= CLEAN ACTION
if test "$ACTION" = "c" || test "$ACTION" = "clean"
then
	echo "CLEANING..."

	rm -rf Build
	rm -rf Binaries

	exit
fi

# ============================================================= OPEN PROJECT ACTION
if test "$ACTION" = "o" || test "$ACTION" = "open"
then
	TARGET_MAP=$2
	if test -z $TARGET_MAP
	then
		TARGET_MAP=Linux
	else
		TAIL_PARAMS="${@:3}"
	fi

	echo "OPENING..."
	eval "$UE4EDITOR" "$UPROJECT_PATH" "$TARGET_MAP" $TAIL_PARAMS > /dev/null 2> /dev/null &
fi

# ============================================================= BUILD ACTION
if test "$ACTION" = "b" || test "$ACTION" = "build"
then
	echo "BUILDING..."
	chmod +x "$BATCH_FILES_DIR/Build.sh"
	eval "$BATCH_FILES_DIR/Build.sh" "${PROJECT_NAME}Editor" Linux Development "$UPROJECT_PATH" -waitmutex -NoHotReload $TAIL_PARAMS

	exit
fi

# ============================================================= RUN ACTION
if test "$ACTION" = "r" || test "$ACTION" = "run"
then
	TARGET_MAP=$2
	if test -z $TARGET_MAP
	then
		TARGET_MAP=Linux
	else
		TAIL_PARAMS="${@:3}"
	fi

	echo "RUNNING..."
	eval "$UE4EDITOR" "$UPROJECT_PATH" "$TARGET_MAP" -game -log -windowed -resx=960 -resy=540 $TAIL_PARAMS

	exit
fi

# ============================================================= PACKAGE ACTION
if test "$ACTION" = "p" || test "$ACTION" = "package"
then
	TARGET_PLATFORM=$2
	if test -z $TARGET_PLATFORM
	then
		TARGET_PLATFORM=Linux
	else
		TAIL_PARAMS="${@:3}"
	fi

	echo "PACKAGING FOR $TARGET_PLATFORM..."

	eval "$BATCH_FILES_DIR/Build.sh" "${PROJECT_NAME}" Linux Development "$UPROJECT_PATH" -waitmutex -NoHotReload -game -progress -buildscw
	eval "$BATCH_FILES_DIR/../RunUAT.sh" -ScriptsForProject="$UPROJECT_PATH" BuildCookRun -nocompileeditor -installed -nop4 -project="$UPROJECT_PATH" -cook -stage -archive -archivedirectory="$PROJECT_DIR/Build" -package -pak -prereqs -targetplatform=$TARGET_PLATFORM -build -target="$PROJECT_NAME" -clientconfig=Development -serverconfig=Development -crashreporter -utf8output $TAIL_PARAMS

	exit
fi

# ============================================================= GENERATE COMPILE COMMANDS ACTION
if test "$ACTION" = "gcc" || test "$ACTION" = "generate-compile-commands"
then
	echo "not supported on linux??"
	exit

	echo "GENERATING COMPILE COMMANDS..."
	UNREAL_BUILD_TOOL="$UE4_DIR/Engine/Binaries/DotNET/UnrealBuildTool.exe"
	chmod +x "$UNREAL_BUILD_TOOL"
	eval "$UNREAL_BUILD_TOOL" -mode=GenerateClangDatabase -project="$UPROJECT_PATH" -game -engine "${PROJECT_NAME}Editor" Linux Development $TAIL_PARAMS
	mv "$UE4_DIR/compile_commands.json" "$PROJECT_DIR/"

	exit
fi

if test -z $ACTION
then
	echo "for more options invoke with the 'help' subcommand"
else
	echo "unknown action '$ACTION'"
fi
