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

require("roc")

concommand.Add("gmx", function()
	PrintTable(gmx)
end)

concommand.Add("gmx_reload", function()
	include("gmx/gmx.lua")
end)

concommand.Add("gmx_file", function(_, _, _, path)
	if file.Exists(path, "MOD") then
		local lua = file.Read(path, "MOD")
		RunOnClient("", "", lua)
		gmx.Print("Client running: " .. path)
	else
		gmx.Print("No such file: " .. path)
	end
end)

concommand.Add("gmx_lua", function(_, _, _, lua)
	RunOnClient("", "", lua)
	gmx.Print("Client running: " .. lua)
end)

concommand.Add("gmx_file_menu", function(_, _, _, path)
	if file.Exists(path, "MOD") then
		local lua = file.Read(path, "MOD")
		RunStringEx(lua)
		gmx.Print("Menu running: " .. path)
	else
		gmx.Print("No such file: " .. path)
	end
end)

concommand.Add("gmx_lua_menu", function(_, _, _, lua)
	RunStringEx(lua)
	gmx.Print("Menu running: " .. lua)
end)

gmx.GEN_CODE = [[
	local BASE = "123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	local function GEN_NAME()
		local len = math.random(16, 32)
		local ret = ""
		for _ = 0, len do
			ret = ret .. BASE[math.random(#BASE)]
		end

		return ret
	end
]]

if not gmx.ComIdentifier then
	RunStringEx(gmx.GEN_CODE .. "gmx.ComIdentifier = GEN_NAME()")
	concommand.Add(gmx.ComIdentifier, function(_, _, _, lua)
		RunStringEx(lua)
	end)
end

gmx.InitScripts = {}
function gmx.AddClientInitScript(code)
	table.insert(gmx.InitScripts, code)
end

gmx.AddClientInitScript(gmx.GEN_CODE .. "\n" .. [[
	local hook_name = GEN_NAME()
	hook.Add("InitPostEntity", hook_name, function()
		hook.Remove("InitPostEntity", hook_name)
		LocalPlayer():ConCommand("]] .. gmx.ComIdentifier .. [[ hook.Run('ClientFullyInitialized')")
	end)
]])

hook.Add("RunOnClient", "gmx_client_init_scripts", function(path, str)
	if path == "lua/includes/init.lua" then
		return str .. "\n" .. table.concat(gmx.InitScripts, "\n")
	end
end)

gmx.ScriptsPath = "gmx/gmx_scripts/"
gmx.MenuScripts = {
	"acs.lua",
	"repl_filter.lua",
	"editor.lua",
	"external_console.lua",
	"errors.lua",
}

gmx.ClientScripts = {
	"lua_cache.lua",
	--"command_filter.v1.lua",
	"command_filter.v2.lua",
}

for _, file_name in ipairs(gmx.MenuScripts) do
	include(gmx.ScriptsPath .. "/menu/" .. file_name)
	gmx.Print("Running \"" .. file_name .. "\"")
end

hook.Add("ClientFullyInitialized", "gmx_client_scripts", function()
	gmx.Print("Client fully initialized")

	for _, file_name in ipairs(gmx.ClientScripts) do
		local code = file.Read("lua/" .. gmx.ScriptsPath .. "/client/" .. file_name, "MOD")
		RunOnClient("", "", code)
		gmx.Print("Running \"" .. file_name .. "\" on client")
	end
end)

-- auto reload
local has_io_events = pcall(require, "io_events")
if has_io_events then
	hook.Remove("FileChanged", "gmx_auto_reload")
	hook.Add("FileChanged", "gmx_auto_reload", function(path, event_type)
		if path ~= "lua/gmx/gmx.lua" or event_type ~= "CHANGED" then return end

		gmx.Print("Reloading everything")
		include("gmx/gmx.lua")
	end)
end