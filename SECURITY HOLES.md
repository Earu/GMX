# SECURITY HOLES

*Security Issues that I've found and need fixing*

1) **menu.lua needs to have its actual content hidden away, replaced by the original**
	- Save the original in gmx and replace in calls to file.Read, file.Size etc?
	- Change the path to the original version? Need to call original fs functions for this?

2) **The file system needs to be detoured before anything in init is ran, so that an override of the default gmod lua files cant tell**
	- This can be done, detouring.lua does not rely on anything part of the modules loaded in init.lua

3) **Need to make sure that adding content to init.lua does not reveal us**
	- Length of the string ran somehow (?):
		- Probably not as the function running init.lua is ran on the engine side where lua scripts don't have any access
	- Checking extra local variables in an overriden init.lua files:
		- Most likely yes, need to cleanup behind ourselves => How do I override hooks without revealing myself?
		- Is the timer enough on its own? What about registry finding us?
		- We can run our own version of init.lua and all the default gmod modules, any override by any addon is then removed
			- However this is also how we can get detected as well... What do?

4) **Scattered lua implementation**
	- Bypasses repl_filter checks

5) **Potential jit.util checks with fast addresses etc...**
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

## References for future AC
- you can also check commandnumber of usercmd, and if it ever goes lower the player is cheating
tick count of usercmd is used for lag compensation
and typically only increases
i've heard that during lag it will decrease, but i'm not sure

- i know specifically you can make a check for ttt
and anyone using world clicker angles

- ![](https://i.imgur.com/P0w8FRs.png)