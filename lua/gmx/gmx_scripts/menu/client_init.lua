local INIT = gmx.Module("ClientInit")
local SCRIPTS_PATH = "gmx/gmx_scripts"
local PRE_INIT_SCRIPTS = {}
local POST_INIT_SCRIPTS = {}
local SCRIPT_LOOKUP = { Pre = {}, Post = {} }

function INIT.AddClientInitScript(code, after_init, identifier)
	if not after_init then
		if identifier then
			SCRIPT_LOOKUP.Pre[identifier] = code
		else
			table.insert(PRE_INIT_SCRIPTS, code)
		end
	else
		if identifier then
			SCRIPT_LOOKUP.Post[identifier] = code
		else
			table.insert(POST_INIT_SCRIPTS, code)
		end
	end
end

function INIT.RemoveClientInitScript(after_init, identifier)
	if not after_init then
		SCRIPT_LOOKUP.Pre[identifier] = nil
	else
		SCRIPT_LOOKUP.Post[identifier] = nil
	end
end

local INIT_SCRIPTS_PATH = ("lua/%s/client"):format(SCRIPTS_PATH)
function INIT.LoadClientInitScripts(after_init)
	local path = INIT_SCRIPTS_PATH .. (after_init and "/post_init/" or "/pre_init/")
	for _, file_name in pairs(file.Find(path .. "*.lua", "MOD")) do
		local code = file.Read(path .. file_name, "MOD")
		gmx.Print(("Adding \"%s\" to client %s-init"):format(file_name, after_init and "post" or "pre"))
		INIT.AddClientInitScript(code, after_init)
	end
end

-- pre-init // SECURE
do
	INIT.AddClientInitScript(gmx.PrependDependencies(nil, {
		"util",
		"detouring",
		"interop"
	}), false)

	INIT.LoadClientInitScripts(false)
end

-- post init // NOT secure
INIT.LoadClientInitScripts(true)

local init_scripts_ran = false
hook.Add("RunOnClient", "gmx_client_init_scripts", function(path, str)
	if not init_scripts_ran and path:EndsWith("lua/includes/init.lua") then
		init_scripts_ran = true
		local constant_declarations = gmx.BuildConstantDeclarations()

		local pre_init_scripts = {}
		table.Add(pre_init_scripts, PRE_INIT_SCRIPTS)
		table.Add(pre_init_scripts, table.ClearKeys(SCRIPT_LOOKUP.Pre))

		local post_init_scripts = {}
		table.Add(post_init_scripts, POST_INIT_SCRIPTS)
		table.Add(post_init_scripts, table.ClearKeys(SCRIPT_LOOKUP.Post))

		local final_code = ("do\n%s\n%s\nend\n%s\ndo\n%s\n%s\nend"):format(
			constant_declarations,
			table.concat(pre_init_scripts, "\n"),
			str,
			constant_declarations,
			table.concat(post_init_scripts, "\n")
		)

		return final_code
	end
end)

hook.Add("GMXHostDisconnected", "gmx_client_init_scripts", function() init_scripts_ran = false end) -- if the server crashes and we instantly reconnect the client state is never destroyed
hook.Add("ClientStateDestroyed", "gmx_client_init_scripts", function() init_scripts_ran = false end)