local PLY_ConCommand = _G.FindMetaTable("Player").ConCommand
local WORLD = _G.game.GetWorld()

local function CMD(cmd)
	PLY_ConCommand(WORLD, cmd)
end

local string_gsub = _G.string.gsub
local string_sub = _G.string.sub
local string_format = _G.string.format
local math_ceil = _G.math.ceil
local table_concat = _G.table.concat
local pairs = _G.pairs
local tostring = _G.tostring

local LEN_NAME = #"{COM_IDENTIFIER}" + 1 -- +1 for space
local SUFFIX_LEN = #"@END"
local MAX_LEN = 250
local function MENU(code)
	local data = string_gsub(code, "[\n\r]", "")
	local max = MAX_LEN - LEN_NAME
	local len = #data

	if len + SUFFIX_LEN <= max then
		CMD("{COM_IDENTIFIER} " .. data .. "@END")
		return
	end

	local chunk_count = math_ceil(len / max)
	for i = 0, chunk_count do
		local chunk = string_sub(data, i * max, (i + 1) * max)
		print(chunk)
		CMD("{COM_IDENTIFIER} " .. chunk)
	end

	CMD("{COM_IDENTIFIER} @END")
end

local function MENU_HOOK(name, ...)
	local args = { ... }
	for k, v in pairs(args) do
		args[k] = string_format("\"%s\"", tostring(v))
	end

	local code = [[hook.Run("]] .. name .. [[", ]] .. table_concat(args, ", ") .. [[)]]
	if TABLE_COUNT(args) == 0 then
		code = [[hook.Run("]] .. name .. [[")]]
	end

	MENU(code)
end