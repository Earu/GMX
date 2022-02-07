local LEN_NAME = 8 + 1 -- +1 for space
local SUFFIX_LEN = #";END"
local MAX_LEN = 255
local function PIPE(code)
	local max = MAX_LEN - LEN_NAME
	local len = #code

	if len + SUFFIX_LEN <= max then
		LocalPlayer():ConCommand("{COM_IDENTIFIER} " .. code .. "@END")
		return
	end

	local chunk_count = math.ceil(len + SUFFIX_LEN / max)
	for i = 1, chunk_count do
		local part = code:sub((i - 1) * max, i * max)
		if i == chunk_count then
			part = part .. "@END"
		end

		LocalPlayer():ConCommand("{COM_IDENTIFIER} " .. part)
	end
end

local function MENU_HOOK(name, ...)
	local args = { ... }
	for k, v in pairs(args) do
		args[k] = ("\"%s\""):format(tostring(v))
	end

	PIPE([[hook.Run("]] .. name .. [[", ]] .. table.concat(args, ", ") .. [[)]])
end