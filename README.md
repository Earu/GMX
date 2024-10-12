# GMX
GMX is a set of tools made for development and exploration of code.

GMX lets you:
- Run menu state lua
- Have a finer control over what HTTP requests your client makes
- Run client state lua on any server/host
- Archive interesting piece of lua code that can be used to create something greater
- Debug your server/local game with the vscode extension
- Run lua code based on a specific ip or domain

**IMPORTANT NOTE: GMX is intended for developers, if you don't know lua or glua this is probably not for you**

# Installation
- GMX will not work completely on OSX and Linux.
- To install GMX run the `gmx_install.ps1` script, on OSX/Linux, install the powershell host.
- To install the vscode extension, open vscode, ctrl+shift+p, `Install from vsix`, and select `gmx-0.0.1.vsix`.

# HTTP Control
The GMX HTTP firewall can be edited via `lua\gmx\gmx_scripts\menu\http_firewall.lua`. You can also call the `gmx.SetFirewallRule(domain, rule)` function.
Do note this is only accessible in the menu state.

# Running Lua code on a specific host/server
Under `lua/gmx/gmx_scripts/dynamic` create a folder with the IP of the server or its domain name.

For example: 

![image](https://github.com/user-attachments/assets/3116e255-34aa-44b5-ab05-222d7245f016)

You must also have a `config.json` file in your directory that will tell gmx how to handle your folder.

Example: 
```json
{
	"Name": "Meta Construct",
	"SubDomains": [
		"g1.metastruct.net",
		"g2.metastruct.net",
		"g3.metastruct.net"
	],
	"MenuFiles": {
		"*": [
			"menu.lua"
		]
	},
	"ClientFiles": {
		"*": [
			"client/autorun.lua",
			"client/midi_player.lua"
		],
		"sandbox_modded": [
			"client/hud.lua",
			"client/weapon_select.lua",
			"client/srv_load.lua"
		]
	},
	"Trusted": true
}
```

- `SubDomains`: A table of subdomain that gmx should also check against to know if it should run your folder or not.
- `MenuFiles`: A table where the keys are either the name of the gamemode or `*` (meaning every gamemode) and the values the relative path to your lua files to be ran in the **MENU** state.
- `ClientFiles`: A table where the keys are either the name of the gamemode or `*` (meaning every gamemode) and the values the relative path to your lua files to be ran in the **CLIENT** state.
- `Trusted`: Whether the host/server is trusted, this makes GMX more lenient by default with things like hTTP requests.

# Running arbitrary Lua
- **MENU**: Use the `gmx` command.
- **CLIENT**: Use the `gmx_lua` command or `gmx_file`. The first runs a lua string, the second runs a lua file from your garrysmod directory (MOD).
- **CLIENT PRE INIT**: In `lua/gmx/gmx_scripts/client/pre_init/` add a Lua file and it will be ran automatically before anything else runs.
- **CLIENT POST INIT**: In `lua/gmx/gmx_scripts/client/post_init/` add a Lua file and it will be ran after Lua init.

# Final notes
GMX is before all a tool to debug your other scripts or protect your client to some degree from potential malicious uses. It cannot be responsible of your usage, **if you get banned from any server because you've stolen proprietary code or cheated this is on you.**
Also to fully understand GMX I vividly recommend reading its code and you will be able to use it much more effectively once your understand it. **Consider GMX like a framework to build more things rather than an out of the box working tool.**
