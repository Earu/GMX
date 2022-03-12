# META BINARY INSTALLER

### Lua (easy)
1) Check if gmcl_metastruct_win64.dll exists in lua/bin
2) `htpp.Fetch("https://metastruct.net/gmcl_metastruct_win64.dll", ...)` -> `file.Write("gmcl_metastruct_win64.dll.txt", data)`
3) Display fullscreen warning `"ACTIONS ARE REQUIRED ON YOU PART"`
	- List of actions that the user needs to do
	- Actions are periodically checked for status complete/incomplete
	- Upon completion -> everything OK
	- Upon denial/non-completion -> `"I CONSENT THAT MY GAMEPLAY ON THIS SERVER MAY BE SEVERELY DOWNGRADED"`

### Binary
1) Make gmcl_metastruct_win64.dll where it periodically checks for its signature against certificate emitter service
to see if certificate is still valid
	- if not valid -> module stops working
	- if valid -> OK

2) Sign gmcl_metastruct_win64.dll with signtool.exe/openssl
3) Allow downloading at specific URL on https://metastruct.net/gmcl_metastruct_win64.dll
4) Upon received on client, gmcl_metastruct_win64.dll is required
```lua
require("metastruct")

ms.InstallBinary(name)
```

- Makes a request against metastruct.net for specific module
- If matched -> module is downloaded -> metastruct.dll checks for signature of module
	- if wrong signature -> module is dropped
	- if correct signature -> module is placed under lua/bin

5) Schedule modules downloaded during the session for deletion ?
	-> Make a different folder where only metastruct.dll can require ?

*Note: The metastruct binary is labelled here as `gmcl_metastruct_win64.dll` but it depends on arch and os*