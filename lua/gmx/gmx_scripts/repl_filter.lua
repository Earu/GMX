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
hook.Add("RunOnClient", "repl_filter", function(path, str)
	-- remove .p, .pm, .psc commands from gcompute
	if path == "@repl_0" then
		gmx_print("Blocked gcompute command")
		return DENY_CODE
	end

	-- blocks SendLua
	if path == "LuaCmd" then
		gmx_print(("Blocked SendLua %s"):format(str))
		return false
	end

	local found_steam_id = path:match("[0-9]%:[0-9]%:[0-9]+")
	if found_steam_id and found_steam_id ~= MY_STEAM_ID then
		-- detect luadev .l, .lm, .lsc commands and checks if ran by me or not
		local luadev_cmd = path:match("%<[0-9]%:[0-9]%:[0-9]+|.+%>%<cmd%:([a-zA-Z]+)%>")
		if luadev_cmd then
			gmx_print(("Blocked command \"%s\" by %s"):format(luadev_cmd, found_steam_id))
			return DENY_CODE
		end

		-- detect luadev ran files
		local file_name = path:match("%<[0-9]%:[0-9]%:[0-9]+|.+%>%<([a-zA-Z0-9%.%_%s]+)%>")
		if file_name then
			gmx_print(("Blocked file \"%s\" by %s"):format(file_name, found_steam_id))
			return DENY_CODE
		end
	end

	-- fuck starfall
	if path:StartWith("SF") then
		gmx_print(("Blocked starfall chip \"%s\""):format(path))
		return DENY_CODE
	end

	if check_lua_impl(path, str) then
		gmx_print(("Blocked potential lua implementation \"%s\""):format(path))
		return false
	end
end)