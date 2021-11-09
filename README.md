# unreal-helper
Unreal helpers batch file.
Place `uh.bat` on the same folder of your `*.uproject` project file and it will detect
both the Unreal version used and its install directory.

available subcommands:
- `h`, `help` : show help message
- `o`, `open` [map] : open project in the editor, optionally directly opening map `map`
- `c`, `clean` : clean build artifacts
- `b`, `build` : build C++ project sources
- `r`, `run` [map] : run project without opening the editor, optionally directly running map `map`
- `p`, `package` [platform] : package project for `platform` (default is `Win64`)
- `gcc`, `generate-compile-commands` : generate `compile_commands.json` file for use with clangd server
