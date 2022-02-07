gmx = {}

local HEADER_COLOR = Color(255, 157, 0)
local BODY_COLOR = Color(255, 196, 0)
function gmx.Print(...)
	local args = {}
	for key, arg in pairs({ ... }) do
		args[key] = tostring(arg)
	end

	MsgC(HEADER_COLOR, "[GMX] ", BODY_COLOR, table.concat(args, "\t") .. "\n")
end

if jit.arch ~= "x64" and not system.IsWindows() then
	gmx.Print("GMX is not supported on this platform.")
	return
else
	MsgC(HEADER_COLOR, [[

============================================================
=                     G     M     X                        =
============================================================]] .. "\n")
end

require("rocx")

concommand.Add("gmx", function()
	PrintTable(gmx)
end)

concommand.Add("gmx_reload", function()
	include("gmx/gmx.lua")
end)

concommand.Add("gmx_file", function(_, _, _, path)
	if file.Exists(path, "MOD") then
		local lua = file.Read(path, "MOD")
		RunOnClient(lua)
		gmx.Print("Client running: " .. path)
	else
		gmx.Print("No such file: " .. path)
	end
end)

concommand.Add("gmx_lua", function(_, _, _, lua)
	RunOnClient(lua)
	gmx.Print("Client running: " .. lua)
end)

concommand.Add("gmx_file_menu", function(_, _, _, path)
	if file.Exists(path, "MOD") then
		local lua = file.Read(path, "MOD")
		RunString(lua)
		gmx.Print("Menu running: " .. path)
	else
		gmx.Print("No such file: " .. path)
	end
end)

concommand.Add("gmx_lua_menu", function(_, _, _, lua)
	RunString(lua)
	gmx.Print("Menu running: " .. lua)
end)

local BASE = "123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
function gmx.GenerateUID(len)
	len = len or math.random(8)

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
concommand.Add(gmx.ComIdentifier, function(_, _, _, msg)
	if msg:EndsWith("@END") then
		cur_msg = cur_msg .. msg:gsub("%@END$", "")
		RunString(cur_msg)

		cur_msg = ""
	else
		cur_msg = cur_msg .. msg
	end
end)

gmx.ScriptsPath = "gmx/gmx_scripts/"
gmx.InitScripts = {}

function gmx.AddClientInitScript(code)
	table.insert(gmx.InitScripts, code)
end

gmx.AddClientInitScript(file.Read("lua/gmx/client_state/interop.lua", "MOD"):gsub("{COM_IDENTIFIER}", gmx.ComIdentifier))
gmx.AddClientInitScript(file.Read("lua/gmx/client_state/detouring.lua", "MOD"))
gmx.AddClientInitScript([[
	local GMX_HANDLE = { IsValid = function() return true end }
	hook.Add("InitPostEntity", GMX_HANDLE, function()
		hook.Remove("InitPostEntity", GMX_HANDLE)
		MENU_HOOK('ClientFullyInitialized', game.GetIPAddress(), GetHostName():sub(1, 15))
	end)
]])

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