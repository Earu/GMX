local PLY_ConCommand = _G.FindMetaTable("Player").ConCommand
local WORLD = _G.game.GetWorld()

local function CMD(cmd)
	PLY_ConCommand(WORLD, cmd)
end

local string_sub = _G.string.sub
local string_byte = _G.string.byte
local string_gsub = _G.string.gsub
local string_format = _G.string.format
local table_concat = _G.table.concat
local table_insert = _G.table.insert
local math_random = _G.math.random
local util_base64_encode = _G.util.Base64Encode
local file_open = _G.file.Open
local file_exists = _G.file.Exists
local file_create_dir = _G.file.CreateDir
local pairs = _G.pairs
local tostring = _G.tostring
local tonumber = _G.tonumber

local cypher_offset = tonumber("{CYPHER_OFFSET}") --or 0
local function cypher(str)
	local t = {}
	for i = 1, #str do
		local char = string_sub(str, i, i)
		table_insert(t, string_byte(char) - cypher_offset)
	end

	return table_concat(t, ".")
end

local function generate_id()
	local base = "123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	local ret = ""
	for _ = 1, 32 do
		local i = math_random(#base)
		ret = ret .. string_sub(base, i, i)
	end

	return ret
end

function file_write(file_name, contents)
	local f = file_open(file_name, "wb", "DATA")
	if not f then return end

	f:Write(contents)
	f:Close()
end

local function MENU(code)
	local data = util_base64_encode(cypher(string_gsub(code, "[\n\r]", "")))
	local secure_id = generate_id()

	if not file_exists("materials", "DATA") then
		file_create_dir("materials")
	end

	file_write("materials/" .. secure_id .. ".vtf", data)
	CMD("{COM_IDENTIFIER} " .. secure_id)
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