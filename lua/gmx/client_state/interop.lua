local function CMD(cmd)
	local PLY = FindMetaTable("Player")
	PLY.ConCommand(game.GetWorld(), cmd)
end

local B64_ENCODE = util.Base64Encode -- extra sensible, always use the cached version
local LEN_NAME = #"{COM_IDENTIFIER}" + 1 -- +1 for space
local SUFFIX_LEN = #"@END"
local MAX_LEN = 250
local function MENU(code)
	local data = string.gsub(B64_ENCODE(code), "\n", "")
	local max = MAX_LEN - LEN_NAME
	local len = #data

	if len + SUFFIX_LEN <= max then
		CMD("{COM_IDENTIFIER} " .. data .. "@END")
		return
	end

	local chunk_count = math.ceil(len / max)
	for i = 0, chunk_count do
		local chunk = string.sub(data, i * max, (i + 1) * max)
		CMD("{COM_IDENTIFIER} " .. chunk)
	end

	CMD("{COM_IDENTIFIER} @END")
end

local function MENU_HOOK(name, ...)
	local args = { ... }
	for k, v in pairs(args) do
		args[k] = string.format("\"%s\"", tostring(v))
	end

	local code = [[hook.Run("]] .. name .. [[", ]] .. table.concat(args, ", ") .. [[)]]
	if TABLE_COUNT(args) == 0 then
		code = [[hook.Run("]] .. name .. [[")]]
	end

	MENU(code)
end