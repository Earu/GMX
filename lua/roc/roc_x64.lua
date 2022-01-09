if jit.arch ~= "x64" then return end

require("roc")

local HEADER_COLOR = Color(255, 0, 0)
local BODY_COLOR = Color(197, 53, 17)
function roc_print(...)
	local args = {}
	for key, arg in pairs({ ... }) do
		args[key] = tostring(arg)
	end

	MsgC(HEADER_COLOR, "[ROC] ", BODY_COLOR, table.concat(args, "\t") .. "\n")
end

concommand.Add("roc_file", function(_, _, _, path)
	if file.Exists(path, "GAME") then
		local lua = file.Read(path, "GAME")
		RunOnClient("", "", lua)
		roc_print("Client running: " .. path)
	end
end)

concommand.Add("roc_lua", function(_, _, _, lua)
	RunOnClient("", "", lua)
	roc_print("Client running: " .. lua)
end)

concommand.Add("roc_file_menu", function(_, _, _, path)
	if file.Exists(path, "GAME") then
		local lua = file.Read(path, "GAME")
		RunStringEx(lua)
		roc_print("Menu running: " .. path)
	end
end)

concommand.Add("roc_lua_menu", function(_, _, _, lua)
	RunStringEx(lua)
	roc_print("Menu running: " .. lua)
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

if not _G.ROC_COM_NAME then
	RunStringEx(GEN_CODE .. "_G.ROC_COM_NAME = GEN_NAME()")
	concommand.Add(_G.ROC_COM_NAME, function(_, _, _, lua)
		RunStringEx(lua)
	end)
end

local LUAJIT_OP_CODES = {
	"ISLT", "ISGE", "ISLE", "ISGT", "ISEQV", "ISNEV", "ISEQS", "ISNES", "ISEQN", "ISNEN", "ISEQP",
	"ISNEP", "ISTC",  "ISFC", "IST", "ISF", "MOV", "NOT", "UNM", "LEN", "ADDVN", "SUBVN", "MULVN",
	"DIVVN", "MODVN", "ADDNV", "SUBNV", "MULNV", "DIVNV", "MODNV", "ADDVV", "SUBVV", "MULVV", "DIVVV",
	"MODVV", "POW", "CAT", "KSTR", "KCDATAKSHORTKNUM", "KPRI", "KNIL", "UGET", "USETV", "USETS", "USETN",
	"USETP", "UCLO", "FNEW", "TNEW", "TDUP", "GGET", "GSET", "TGETV", "TGETS", "TGETB", "TSETV", "TSETS",
	"TSETB", "TSETM", "CALLM", "CALL", "CALLMTCALLT", "ITERC", "ITERN", "VARG", "ISNEXTRETM", "RET", "RET0",
	"RET1", "FORI", "JFORI", "FORL", "IFORL", "JFORL", "ITERL", "IITERLJITERLLOOP", "ILOOP", "JLOOP", "JMP",
	"FUNCF", "IFUNCFJFUNCFFUNCV", "IFUNCVJFUNCVFUNCC", "FUNCCW"
}

local WHITELIST = {
	["lua/pac3/libraries/luadata.lua"] = true
}

local cache = {}
local CERTAINTY_THRESHOLD = 0.75
local function check_lua_impl(path, str)
	if WHITELIST[path] then return false end
	if cache[path] then return cache[path] end

	local count = 0
	for _, op_code in ipairs(LUAJIT_OP_CODES) do
		if str:upper():find(op_code, 1, true) then
			count = count + 1
		end
	end

	local res = (count / #LUAJIT_OP_CODES) > CERTAINTY_THRESHOLD
	cache[path] = res
	return res
end

-- LuaCmd => SendLuas
-- @repl_0 => command
-- <0:0:80006525|Earu><cmd:lsc> => command
-- <0:0:80006525|Earu><spooky.lua> => file
local DENY_CODE = "error(\'DENIED\', 0)"
local MY_STEAM_ID = "0:0:80006525"
hook.Add("RunOnClient", "lua_filter", function(path, str)
	-- remove .p, .pm, .psc commands from gcompute
	if path == "@repl_0" then
		roc_print("Blocked gcompute command")
		return DENY_CODE
	end

	-- blocks SendLua
	if path == "LuaCmd" then
		roc_print(("Blocked SendLua %s"):format(str))
		return false
	end

	local found_steam_id = path:match("[0-9]%:[0-9]%:[0-9]+")
	if found_steam_id and found_steam_id ~= MY_STEAM_ID then
		-- detect luadev .l, .lm, .lsc commands and checks if ran by me or not
		local luadev_cmd = path:match("%<[0-9]%:[0-9]%:[0-9]+|.+%>%<cmd%:([a-zA-Z]+)%>")
		if luadev_cmd then
			roc_print(("Blocked command \"%s\" by %s"):format(luadev_cmd, found_steam_id))
			return DENY_CODE
		end

		-- detect luadev ran files
		local file_name = path:match("%<[0-9]%:[0-9]%:[0-9]+|.+%>%<([a-zA-Z0-9%.%_%s]+)%>")
		if file_name then
			roc_print(("Blocked file \"%s\" by %s"):format(file_name, found_steam_id))
			return DENY_CODE
		end
	end

	-- fuck starfall
	if path:StartWith("SF") then
		roc_print(("Blocked starfall chip \"%s\""):format(path))
		return DENY_CODE
	end

	if check_lua_impl(path, str) then
		roc_print(("Blocked potential lua implementation \"%s\""):format(path))
		return false
	end

	if path == "lua/includes/init.lua" then
		local init_script = str .. "\n" .. GEN_CODE .. "\n" .. [[
			local hook_name = GEN_NAME()
			hook.Add("InitPostEntity", hook_name, function()
				hook.Remove("InitPostEntity", hook_name)
				LocalPlayer():ConCommand("]] .. _G.ROC_COM_NAME .. [[ hook.Run('ClientFullyInitialized')")
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
	"editor.lua",
	"external_console.lua",
}

local SCRIPTS_PATH = "roc/roc_scripts/"
for _, file_name in ipairs(MENU_SCRIPTS) do
	include(SCRIPTS_PATH .. file_name)
	roc_print("Running \"" .. file_name .. "\"")
end

local CLIENT_SCRIPTS = {
	"lua_cache.lua",
	--"command_filter.v1.lua",
	"command_filter.v2.lua",
	"misc.lua",
}
hook.Add("ClientFullyInitialized", "block_server_cmds", function()
	roc_print("Client fully initialized")

	for _, file_name in ipairs(CLIENT_SCRIPTS) do
		local code = file.Read("lua/" .. SCRIPTS_PATH .. file_name, "GAME")
		RunOnClient("", "", code)
		roc_print("Running \"" .. file_name .. "\" on client")
	end
end)

local has_io_events = pcall(require, "io_events")
if has_io_events then
	hook.Remove("FileChanged", "reload_roc")
	hook.Add("FileChanged", "reload_roc", function(path, event_type)

		if path ~= "lua/roc/roc_x64.lua" or event_type ~= "CHANGED" then return end
		roc_print("Reloading everything")
		include("roc/roc_x64.lua")
	end)
end