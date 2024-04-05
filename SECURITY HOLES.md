# SECURITY HOLES

*Security Issues that I've found and need fixing*

1) **Scattered lua implementation**
	- Bypasses repl_filter checks

2) **HTTP calls**
	- Needs back and forth between client and menu state, even though everything is hidden behind random tokens, guessing the correct one could grant access to the current session
	- Since latest gmod update client state uses curl instead of ISteamHTTP meaning each single thing using HTTP needs to be detoured, its possible to forget a function or to wrongly detour it

3) **debug.getregistry**
	- As of lately `debug.getregistry` does not provide a way to override `hook.Call` anymore, also it seems any detour past `includes/init.lua` gets picked up by anti-cheats. Be extremely careful of anything ran through `RunOnClient` as it can easily be picked up.

## Patched
- **Running concommands and known cvar to detect whether someone has the RunOnClient function**
	- Deny access to said concommands
- **Checking for modules or unusual folder/files in the lua folder with the file system library**
	- Detour the fs library
- **Checking for detours with jit.util lib, string.dump and/or debug lib**
	- Detour these and hide the detours
- **Leaving globals on the stack**
	- Make everything local and run only via RunOnClient or in init.lua
- **Leaving hooks that are non standard**
	- Detour the hook library
- **Custom lua impl that bypasses RunString and such**
	- Check for op codes
- **Potential errors of custom scripts getting networked to the server**
	- Hidden with luaerror
- **Potential abuse via ConCommand ran on the server**
	- Blocked with sourcenet
- **Potential HTTP call toward a backdoored endpoint**
	- Blocked with http_filter
- **Potential ACs requesting data from client and detecting us**
	- Fixed with knowledged gathered from scripthook
- **REPL lua RCE**
	- Fixed with RunOnClient hook (rocx)
- **Checking menu.lua**
	- Fixed by detouring fs before init.lua
- **Checking init.lua**
	- Fixed by scoping the added code
- **jit.util fast address stuff**
	- Not usable to detect gmx