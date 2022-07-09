# unreal-helper
Unreal helpers batch file.
Place `uh.bat` on the same folder of your `*.uproject` project file and it will detect
both the Unreal version used and its install directory.

## subcommands
```
- h help : show this help
- e editor [map] : open editor, optionally directly opening `map`
- de debug-editor [map] : same as `editor` but debugging through visual studio
- s solution : open visual studio solution
- c clean : clean build artifacts
- b build : build C++ project sources
- r run [instance-count] [map] : run game without opening the editor
                               : optionally running `instance-count` game instances
                               : optionally directly running `map`
                               : also, instead of a map name, it's possible to pass `client`
                               : in order to just connect to an already running host
- dr debug-run [instance-count] [map] : same as `run` but debugging the host instance through visual studio
- p package [platform=Win64] : package project for `platform`
- gcc generate-compile-commands : generate "compile_commands.json" file for use with clangd server
```
