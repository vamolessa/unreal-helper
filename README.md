# unreal-helper
Unreal helpers batch file.
Place `uh.bat` on the same folder of your `*.uproject` project file and it will detect
both the Unreal version used and its install directory.

available subcommands:
- `h`, `help` : show help message
- `o`, `open` [map] : open project in the editor, optionally directly opening map `map`
- `od`, `open-debug` [map] : open project while debugging, optionally directly opening map `map`
- `s`, `solution` : open visual studio solution
- `c`, `clean` : clean build artifacts
- `b`, `build` : build C++ project sources
- `r`, `run` [map] : run project without opening the editor, optionally directly running map `map`
- `d`, `debug` [map] : debug project without opening the editor, optionally directly running map `map`
- `p`, `package` [platform=Win64] : package project for `platform`
- `gcc`, `generate-compile-commands` : generate `compile_commands.json` file for use with clangd server
