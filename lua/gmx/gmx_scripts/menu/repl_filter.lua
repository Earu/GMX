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
	["pac3/libraries/luadata.lua"] = true, -- old data format, not lua imp
	["glib/lua/decompiler/opcode.lua"] = true, -- decompiler, not lua impl
}

local cache = {}
local CERTAINTY_THRESHOLD = 0.75
local function check_lua_impl(path, str)
	if WHITELIST[path] then return false end

	local start_pos, end_pos = path:find("lua/")
	if start_pos and end_pos then
		path = path:sub(end_pos + 1)
	end

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

gmx.NextGComputeCommandAllowed = false
gmx.AddClientInitScript([[
	local function is_gcompute_cmd(msg)
		if msg:match("^[%!%.%/]") then
			local cmd = msg:sub(2):Split(" ")[1]:lower():Trim()
			return cmd == "pm" or cmd == "psc"
		end

		return false
	end

	-- before networked, only trust easychat
	HOOK("ECShouldSendMessage", function(msg)
		if not is_gcompute_cmd(msg) then return end
		MENU("gmx.NextGComputeCommandAllowed = true")
		MENU_HOOK("GMXNotify", "Temporarily allowing GCompute command")
	end)
]], true)

-- LuaCmd => SendLuas
-- @repl_0 => command
-- <0:0:80006525|Earu><cmd:lsc> => command
-- <0:0:80006525|Earu><spooky.lua> => file
local DENY_CODE = "error(\'DENIED\', 0)"
local STEAM_ID_WHITELIST = {
	["0:0:80006525"] = true,
}

local function update_whitelist(str, allow)
	if not str then return end
	local steam_id = str:match("%d+:%d+:%d+")
	if not steam_id then return end

	gmx.Print("Repl", "Updating whitelist for ", steam_id, allow)
	STEAM_ID_WHITELIST[steam_id:gsub("STEAM_", ""):Trim()] = allow and true or nil
end

gmx.ReplFilterCache = {}
local function store_code(path, str, method)
	table.insert(gmx.ReplFilterCache, { Path = path, Lua = str, Method = method, Date = os.date("%x %X") })
	hook.Run("GMXReplFilterCacheChanged")
end

hook.Add("GMXReload", "gmx_repl_filter", function()
	hook.Run("GMXReplFilterCacheChanged")
end)

hook.Add("RunOnClient", "gmx_repl_filter", function(path, str)
	-- remove .p, .pm, .psc commands from gcompute
	if path == "@repl_0" then
		if gmx.NextGComputeCommandAllowed then
			gmx.NextGComputeCommandAllowed = false
			return str
		end

		store_code(path, str, "GCompute")
		gmx.Print("Blocked gcompute command")
		return DENY_CODE
	end

	-- blocks SendLua
	if path == "LuaCmd" then
		store_code(path, str, "SendLua")
		if not gmx.IsHostWhitelisted() then
			gmx.Print(("Blocked SendLua %s"):format(str))
			return false
		end
	end

	local found_steam_id = path:match("[0-9]%:[0-9]%:[0-9]+")
	if found_steam_id and not STEAM_ID_WHITELIST[found_steam_id] then
		if path:match("^%[STEAM_[0-9]%:[0-9]%:[0-9]+%]") then
			store_code(path, str, "GCompute IDE")
			gmx.Print(("Blocked GCompute script by %s"):format(found_steam_id))
			return DENY_CODE
		end

		-- detect luadev .l, .lm, .lsc commands and checks if ran by me or not
		local luadev_cmd = path:match("%<[0-9]%:[0-9]%:[0-9]+|.+%>%<cmd%:([a-zA-Z]+)%>")
		if luadev_cmd then
			store_code(path, str, ("LuaDev Command: %s"):format(luadev_cmd))
			gmx.Print(("Blocked command \"%s\" by %s"):format(luadev_cmd, found_steam_id))
			return DENY_CODE
		end

		-- detect luadev ran files
		local file_name = path:match("^%<[0-9]%:[0-9]%:[0-9]+|.+%>%<([^%<%>]+)%>")
		if file_name then
			store_code(path, str, ("LuaDev File: %s"):format(file_name))
			gmx.Print(("Blocked file \"%s\" by %s"):format(file_name, found_steam_id))
			return DENY_CODE
		end
	end

	-- starfall, its more annoying to block it than not...
	if path:StartWith("SF") then
		store_code(path, str, "Starfall")
	end

	if check_lua_impl(path, str) then
		store_code(path, str, "Lua Impl")
		gmx.Print(("Blocked potential lua implementation \"%s\""):format(path))
		return false
	end
end)

concommand.Remove("gmx_repl_allow")
concommand.Add("gmx_repl_allow", function(_, _, _, str)
	update_whitelist(str, true)
end)

concommand.Remove("gmx_repl_deny")
concommand.Add("gmx_repl_deny", function(_, _, _, str)
	update_whitelist(str, false)
end)