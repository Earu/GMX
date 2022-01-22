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
	local start_pos, end_pos = path:match("lua/")
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
	hook.Add("ECShouldSendMessage", GMX_HANDLE, function(_, msg)
		if not is_gcompute_cmd(msg) then return end
		LocalPlayer():ConCommand("]] .. gmx.ComIdentifier .. [[ gmx.NextGComputeCommandAllowed = true")
	end)
]])

-- LuaCmd => SendLuas
-- @repl_0 => command
-- <0:0:80006525|Earu><cmd:lsc> => command
-- <0:0:80006525|Earu><spooky.lua> => file
local DENY_CODE = "error(\'DENIED\', 0)"
local MY_STEAM_ID = "0:0:80006525"
hook.Add("RunOnClient", "gmx_repl_filter", function(path, str)
	-- remove .p, .pm, .psc commands from gcompute
	if path == "@repl_0" then
		if gmx.NextGComputeCommandAllowed then
			gmx.NextGComputeCommandAllowed = false
			return str
		end

		gmx.Print("Blocked gcompute command")
		return DENY_CODE
	end

	-- blocks SendLua
	if path == "LuaCmd" then
		gmx.Print(("Blocked SendLua %s"):format(str))
		return false
	end

	local found_steam_id = path:match("[0-9]%:[0-9]%:[0-9]+")
	if found_steam_id and found_steam_id ~= MY_STEAM_ID then
		-- detect luadev .l, .lm, .lsc commands and checks if ran by me or not
		local luadev_cmd = path:match("%<[0-9]%:[0-9]%:[0-9]+|.+%>%<cmd%:([a-zA-Z]+)%>")
		if luadev_cmd then
			gmx.Print(("Blocked command \"%s\" by %s"):format(luadev_cmd, found_steam_id))
			return DENY_CODE
		end

		-- detect luadev ran files
		local file_name = path:match("%<[0-9]%:[0-9]%:[0-9]+|.+%>%<([a-zA-Z0-9%.%_%s]+)%>")
		if file_name then
			gmx.Print(("Blocked file \"%s\" by %s"):format(file_name, found_steam_id))
			return DENY_CODE
		end
	end

	-- fuck starfall
	if path:StartWith("SF") then
		gmx.Print(("Blocked starfall chip \"%s\""):format(path))
		return DENY_CODE
	end

	if check_lua_impl(path, str) then
		gmx.Print(("Blocked potential lua implementation \"%s\""):format(path))
		return false
	end
end)