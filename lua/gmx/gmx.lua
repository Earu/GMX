local HEADER_COLOR = Color(255, 157, 0)
local BODY_COLOR = Color(255, 196, 0)
function gmx_print(...)
	local args = {}
	for key, arg in pairs({ ... }) do
		args[key] = tostring(arg)
	end

	MsgC(HEADER_COLOR, "[GMX] ", BODY_COLOR, table.concat(args, "\t") .. "\n")
end

if jit.arch ~= "x64" and not system.IsWindows() then
	gmx_print("GMX is not supported on this platform.")
	return
else
	MsgC(HEADER_COLOR, [[

============================================================
=                     G     M     X                        =
============================================================]] .. "\n")
end

require("roc")

concommand.Add("gmx_reload", function()
	include("lua/gmx/gmx.lua")
end)

concommand.Add("gmx_file", function(_, _, _, path)
	if file.Exists(path, "MOD") then
		local lua = file.Read(path, "MOD")
		RunOnClient("", "", lua)
		gmx_print("Client running: " .. path)
	else
		gmx_print("No such file: " .. path)
	end
end)

concommand.Add("gmx_lua", function(_, _, _, lua)
	RunOnClient("", "", lua)
	gmx_print("Client running: " .. lua)
end)

concommand.Add("gmx_file_menu", function(_, _, _, path)
	if file.Exists(path, "MOD") then
		local lua = file.Read(path, "MOD")
		RunStringEx(lua)
		gmx_print("Menu running: " .. path)
	else
		gmx_print("No such file: " .. path)
	end
end)

concommand.Add("gmx_lua_menu", function(_, _, _, lua)
	RunStringEx(lua)
	gmx_print("Menu running: " .. lua)
end)

GEN_CODE = [[
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

if not _G.GMX_COM_ID then
	RunStringEx(GEN_CODE .. "_G.GMX_COM_ID = GEN_NAME()")
	concommand.Add(_G.GMX_COM_ID, function(_, _, _, lua)
		RunStringEx(lua)
	end)
end

hook.Add("RunOnClient", "client_state_init", function(path, str)
	if path == "lua/includes/init.lua" then
		local init_script = str .. "\n" .. GEN_CODE .. "\n" .. [[
			local hook_name = GEN_NAME()
			hook.Add("InitPostEntity", hook_name, function()
				hook.Remove("InitPostEntity", hook_name)
				LocalPlayer():ConCommand("]] .. _G.GMX_COM_ID .. [[ hook.Run('ClientFullyInitialized')")
			end)
		]]

		local custom_init_scripts = {}
		hook.Run("PostClientLuaInit", custom_init_scripts)
		for _, custom_init_script in pairs(custom_init_scripts) do
			init_script = init_script .. "\n" .. custom_init_script
		end

		return init_script
	end
end)

local MENU_SCRIPTS = {
	"acs.lua",
	"repl_filter.lua",
	"editor.lua",
	"external_console.lua",
	"errors.lua",
}

local SCRIPTS_PATH = "gmx/gmx_scripts/"
for _, file_name in ipairs(MENU_SCRIPTS) do
	include(SCRIPTS_PATH .. file_name)
	gmx_print("Running \"" .. file_name .. "\"")
end

local CLIENT_SCRIPTS = {
	"lua_cache.lua",
	--"command_filter.v1.lua",
	"command_filter.v2.lua",
}
hook.Add("ClientFullyInitialized", "block_server_cmds", function()
	gmx_print("Client fully initialized")

	for _, file_name in ipairs(CLIENT_SCRIPTS) do
		local code = file.Read("lua/" .. SCRIPTS_PATH .. file_name, "MOD")
		RunOnClient("", "", code)
		gmx_print("Running \"" .. file_name .. "\" on client")
	end
end)

local has_io_events = pcall(require, "io_events")
if has_io_events then
	hook.Remove("FileChanged", "reload_gmx")
	hook.Add("FileChanged", "reload_gmx", function(path, event_type)
		if path ~= "lua/gmx/gmx.lua" or event_type ~= "CHANGED" then return end

		gmx_print("Reloading everything")
		include("gmx/gmx.lua")
	end)
end