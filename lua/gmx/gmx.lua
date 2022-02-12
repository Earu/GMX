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

concommand.Add("gmx", function(_, _, _, cmd)
	cmd = cmd:Trim()
	if #cmd == 0 then
		PrintTable(gmx)
		return
	end

	if cmd == "reload" then
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

concommand.Add("gmx_file", function(_, _, _, path)
	if file.Exists(path, "MOD") then
		local lua = file.Read(path, "MOD")
		RunOnClient(lua)
		gmx.Print("Client running:", path)
	else
		gmx.Print("No such file:", path)
	end
end)

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

gmx.ScriptsPath = "gmx/gmx_scripts/"
gmx.InitScripts = {}

function gmx.AddClientInitScript(code)
	table.insert(gmx.InitScripts, code)
end

gmx.AddClientInitScript(gmx.PrepareCode([[
	HOOK("InitPostEntity", function()
		MENU_HOOK('ClientFullyInitialized', game.GetIPAddress(), GetHostName():sub(1, 15))
	end)
]], {
	-- the order matter
	"detouring",
	"interop",
	"hooking"
}))

local init_scripts_path = "lua/" .. gmx.ScriptsPath .. "client/init/"
for _, file_name in pairs(file.Find(init_scripts_path .. "*.lua", "MOD")) do
	local code = file.Read(init_scripts_path .. file_name, "MOD")
	gmx.Print("Adding \"" .. file_name .. "\" to client init")
	gmx.AddClientInitScript(code)
end

local init_scripts_ran = false
hook.Add("RunOnClient", "gmx_client_init_scripts", function(path, str)
	if not init_scripts_ran and path:EndsWith("lua/includes/init.lua") then
		init_scripts_ran = true
		return str .. "\n" .. table.concat(gmx.InitScripts, "\n")
	end
end)

hook.Add("ClientStateDestroyed", "gmx_client_init_scripts", function()
	init_scripts_ran = false
end)

local menu_scripts_path = gmx.ScriptsPath .. "/menu/"
for _, file_name in pairs(file.Find("lua/" .. menu_scripts_path .. "*.lua", "MOD")) do
	include(menu_scripts_path .. file_name)
	gmx.Print("Running \"" .. file_name .. "\"")
end

hook.Add("ClientFullyInitialized", "gmx_client_fully_init", function()
	gmx.Print("Client fully initialized")
end)

hook.Add("GMXNotify", "gmx_logs", gmx.Print)