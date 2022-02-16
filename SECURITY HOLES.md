# SECURITY HOLES

*Security Issues that I've found and need fixing*

1) **Scattered lua implementation**
	- Bypasses repl_filter checks

2) **Potential jit.util checks with fast addresses etc...**
	- Experiment

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

## References for future AC
- you can also check commandnumber of usercmd, and if it ever goes lower the player is cheating
tick count of usercmd is used for lag compensation
and typically only increases
i've heard that during lag it will decrease, but i'm not sure

- i know specifically you can make a check for ttt
and anyone using world clicker angles

- ![](https://i.imgur.com/P0w8FRs.png)