gmx = {}

local HEADER_COLOR = Color(255, 157, 0)
local BODY_COLOR = Color(255, 196, 0)
local EXTRA_COLOR = Color(255, 255, 255)
function gmx.Print(...)
	local args = {}
	for key, arg in pairs({ ... }) do
		args[key] = tostring(arg)
	end

	MsgC(HEADER_COLOR, "[GMX] ", BODY_COLOR, args[1] .. "\t", EXTRA_COLOR, table.concat(args, "\t", 2)  .. "\n")
end

if jit.arch ~= "x64" then
	gmx.Print("GMX is not supported on this architecture (" .. jit.arch .. ").")
	return
else
	MsgC(HEADER_COLOR, [[

============================================================
=                     G     M     X                        =
============================================================]] .. "\n")
end

require("rocx")

concommand.Remove("gmx")
concommand.Add("gmx", function(_, _, _, cmd)
	cmd = cmd:Trim()
	if #cmd == 0 then
		PrintTable(gmx)
		return
	end

	if cmd == "reload" then
		hook.Run("GMXReload")
		include("gmx/gmx.lua")
		return
	end

	if file.Exists(cmd, "MOD") then
		gmx.Print("Menu running:", cmd)
		local lua = file.Read(cmd, "MOD")
		RunString(lua, "gmx")

		return
	end

	gmx.Print("Menu running:", cmd)
	local err = RunString([[print(select(1, ]] .. cmd .. [[))]], "gmx", false)
	if err then
		RunString(cmd, "gmx")
	end
end)

concommand.Remove("gmx_file")
concommand.Add("gmx_file", function(_, _, _, path)
	if file.Exists(path, "MOD") then
		local lua = file.Read(path, "MOD")
		RunOnClient(lua)
		gmx.Print("Client running:", path)
	else
		gmx.Print("No such file:", path)
	end
end)

concommand.Remove("gmx_lua")
concommand.Add("gmx_lua", function(_, _, _, lua)
	RunOnClient(lua)
	gmx.Print("Client running:", lua)
end)

local BASE = "123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
function gmx.GenerateUID(len)
	len = len or 8

	local ret = ""
	for _ = 0, len do
		ret = ret .. BASE[math.random(#BASE)]
	end

	return ret
end

if gmx.ComIdentifier then
	concommand.Remove(gmx.ComIdentifier)
end

gmx.ComIdentifier = gmx.GenerateUID()

local cur_msg = ""
concommand.Add(gmx.ComIdentifier, function(_, _, _, data)
	if data:match("%@END$") then
		cur_msg = cur_msg .. data:gsub("%@END$", "")
		RunString(util.Base64Decode(cur_msg), "gmx_interop")
		cur_msg = ""
	else
		cur_msg = cur_msg .. data
	end
end)

function gmx.PrepareCode(code, deps)
	if not code then code = "" end
	if not deps then deps = {} end

	local outs = {}
	for _, dep in ipairs(deps) do
		local path = ("lua/gmx/client_state/%s.lua"):format(dep)
		if file.Exists(path, "MOD") then
			local content = file.Read(path, "MOD"):gsub("{COM_IDENTIFIER}", gmx.ComIdentifier)
			table.insert(outs, content)
		end
	end

	table.insert(outs, code)
	return table.concat(outs, "\n")
end

function gmx.RunOnClient(code, deps)
	local final_code = gmx.PrepareCode(code, deps)
	RunOnClient(final_code)
end

local cur_data_req_id = 0
local data_req_callbacks = {}
function gmx.RequestClientData(code, callback)
	if not IsInGame() then callback() return end

	data_req_callbacks[cur_data_req_id] = callback

	gmx.RunOnClient([[local ret = select(1, ]] .. code .. [[) MENU_HOOK("ClientDataRequest", ]] .. cur_data_req_id .. [[, ret)]], { "util", "interop" })
	cur_data_req_id = cur_data_req_id + 1
end

hook.Add("ClientDataRequest", "gmx_client_data_requests", function(id, data)
	local callback_id = tonumber(id) or -1
	if callback_id == -1 then return end
	if not data_req_callbacks[callback_id] then return end

	data_req_callbacks[callback_id](data)
end)

gmx.ScriptsPath = "gmx/gmx_scripts"
gmx.PreInitScripts = {}
gmx.PostInitScripts = {}
gmx.ScriptLookup = { Pre = {}, Post = {} }

function gmx.AddClientInitScript(code, after_init, identifier)
	if not after_init then
		if identifier then
			gmx.ScriptLookup.Pre[identifier] = code
		else
			table.insert(gmx.PreInitScripts, code)
		end
	else
		if identifier then
			gmx.ScriptLookup.Post[identifier] = code
		else
			table.insert(gmx.PostInitScripts, code)
		end
	end
end

function gmx.RemoveClientInitScript(after_init, identifier)
	if not after_init then
		gmx.ScriptLookup.Pre[identifier] = nil
	else
		gmx.ScriptLookup.Post[identifier] = nil
	end
end

local init_scripts_path = ("lua/%s/client"):format(gmx.ScriptsPath)
function gmx.LoadClientInitScripts(after_init)
	local path = init_scripts_path .. (after_init and "/post_init/" or "/pre_init/")
	for _, file_name in pairs(file.Find(path .. "*.lua", "MOD")) do
		local code = file.Read(path .. file_name, "MOD")
		gmx.Print(("Adding \"%s\" to client %s-init"):format(file_name, after_init and "post" or "pre"))
		gmx.AddClientInitScript(code, after_init)
	end
end

-- pre-init
do
	gmx.AddClientInitScript(gmx.PrepareCode(nil, {
		"util",
		"detouring",
		"interop"
	}), false)

	gmx.LoadClientInitScripts(false)
end

-- post-init
do
	gmx.AddClientInitScript(gmx.PrepareCode([[
		local called = false
		HOOK("InitPostEntity", function()
			if called then return end
			MENU_HOOK('ClientFullyInitialized', GetHostName():sub(1, 15))
			called = true
		end)

		timer.Simple(20, function()
			if called then return end
			MENU_HOOK('ClientFullyInitialized', GetHostName():sub(1, 15))
			called = true
		end)
	]], {
		-- the order matter
		"util",
		"detouring",
		"interop",
		"hooking"
	}), true)

	gmx.LoadClientInitScripts(true)
end

local init_scripts_ran = false
hook.Add("RunOnClient", "gmx_client_init_scripts", function(path, str)
	if not init_scripts_ran and path:EndsWith("lua/includes/init.lua") then
		init_scripts_ran = true

		local pre_init_scripts = {}
		table.Add(pre_init_scripts, gmx.PreInitScripts)
		table.Add(pre_init_scripts, table.ClearKeys(gmx.ScriptLookup.Pre))

		local post_init_scripts = {}
		table.Add(post_init_scripts, gmx.PostInitScripts)
		table.Add(post_init_scripts, table.ClearKeys(gmx.ScriptLookup.Post))

		return ("do\n%s\nend\n%s\ndo\n%s\nend"):format(
			table.concat(pre_init_scripts, "\n"),
			str,
			table.concat(post_init_scripts, "\n")
		)
	end
end)

hook.Add("ClientStateDestroyed", "gmx_client_init_scripts", function()
	init_scripts_ran = false
end)

local menu_scripts_path = ("%s/menu/"):format(gmx.ScriptsPath)
for _, file_name in pairs(file.Find("lua/" .. menu_scripts_path .. "*.lua", "MOD")) do
	include(menu_scripts_path .. file_name)
	gmx.Print(("Running \"%s\""):format(file_name))
end

hook.Run("GMXInitialized")

hook.Add("ClientFullyInitialized", "gmx_client_fully_init", function()
	gmx.Print("Client fully initialized")
end)

hook.Add("GMXNotify", "gmx_logs", gmx.Print)