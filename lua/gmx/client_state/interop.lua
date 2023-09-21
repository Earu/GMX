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
--local table_insert = _G.table.insert
local pairs = _G.pairs
local tostring = _G.tostring
--local tonumber = _G.tonumber

--[[local utf8 = _G.utf8
if not _G.utf8 then
	require("utf8")
	utf8 = _G.utf8
	_G.utf8 = nil
end

local cypher_offset = tonumber("{CYPHER_OFFSET}") --or 0
local function cypher(str)
	local t = {}
	for _, code in utf8.codes(str) do
		table_insert(t, code - cypher_offset)
	end

	return table_concat(t, ".")
end]]--

local LEN_NAME = #"{COM_IDENTIFIER}" + 1 -- +1 for space
local SUFFIX_LEN = #"@END"
local MAX_LEN = 200
local cur_id = 0
local function MENU(code)
	local id = cur_id % 9000
	cur_id = cur_id + 1

	local data = string_gsub(code, "[\n\r]", "") --cypher(string_gsub(code, "[\n\r]", ""))
	local max = MAX_LEN - LEN_NAME
	local len = #data

	if len + SUFFIX_LEN <= max then
		CMD("{COM_IDENTIFIER} @" .. id .. " " .. data .. "@END")
		return
	end

	local chunk_count = math_ceil(len / max)
	for i = 1, chunk_count do
		local chunk = string_sub(data, (i - 1) * max, i * max)
		CMD("{COM_IDENTIFIER} @" .. id .. " " .. chunk)
	end

	local final_chunk = string_sub(data, chunk_count * max)
	CMD("{COM_IDENTIFIER} @" .. id .. " " .. final_chunk .. "@END")
end

local function MENU_HOOK(name, ...)
	local args = { ... }
	for k, v in pairs(args) do
		args[k] = string_format("%q", tostring(v))
	end

	local code = [[hook.Run("]] .. name .. [[", ]] .. table_concat(args, ", ") .. [[)]]
	if TABLE_COUNT(args) == 0 then
		code = [[hook.Run("]] .. name .. [[")]]
	end

	MENU(code)
end