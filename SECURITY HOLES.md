# SECURITY HOLES

*Security Issues that I've found and need fixing*

1) **Scattered lua implementation**
	- Bypasses repl_filter checks

2) **Sourcenet not working**
	- ConCommands are not blocked anymore
	- Errors are sent to the server
	- Custom scripts might not run in some cases because host is not properly detected

3) **HTTP calls**
	- Needs back and forth between client and menu state, even though everything is hidden behind random tokens, guessing the correct one could grant access to the current session
	- Since latest gmod update client state uses curl instead of ISteamHTTP meaning each single thing using HTTP needs to be detoured, its possible to forget a function or to wrongly detour it

4) **Crash Mitigation regarding util.GetModelMeshes**
	- Creates files in DATA folder making it detectable through client state

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

## References for future AC
- you can also check commandnumber of usercmd, and if it ever goes lower the player is cheating
tick count of usercmd is used for lag compensation
and typically only increases
i've heard that during lag it will decrease, but i'm not sure

- i know specifically you can make a check for ttt
and anyone using world clicker angles

- ![](https://i.imgur.com/P0w8FRs.png)