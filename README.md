# GMX
GMX is a set of tools made for development and exploration of code.

# Installation
To install GMX run the `gmx_install.ps1` script, on OSX/Linux, install the powershell host.

# Running arbitrary Lua
- **MENU**: Use the `gmx` command.
- **CLIENT**: Use the `gmx_lua` command or `gmx_file`. The first runs a lua string, the second runs a lua file from your garrysmod directory (MOD).
- **CLIENT PRE INIT**: In `lua/gmx/gmx_scripts/client/pre_init/` add a Lua file and it will be ran automatically before anything else runs.
- **CLIENT POST INIT**: In `lua/gmx/gmx_scripts/client/post_init/` add a Lua file and it will be ran after Lua init.