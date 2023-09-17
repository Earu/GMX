local string_gsub = _G.string.gsub
local string_match = _G.string.match
local string_sub = _G.string.sub
local string_find = _G.string.find
local string_len = _G.string.len
local pairs = _G.pairs

local pattern_escape_replacements = {
	["("] = "%(",
	[")"] = "%)",
	["."] = "%.",
	["%"] = "%%",
	["+"] = "%+",
	["-"] = "%-",
	["*"] = "%*",
	["?"] = "%?",
	["["] = "%[",
	["]"] = "%]",
	["^"] = "%^",
	["$"] = "%$",
	["\0"] = "%z"
}

local function STR_TRIM(s, char)
	if char then
		char = string_gsub(char, ".", pattern_escape_replacements)
	else
		char = "%s"
	end

	return string_match(s, "^" .. char .. "*(.-)" .. char .. "*$") or s
end


local function STR_SPLIT(str, separator, with_pattern)
	if with_pattern == nil then with_pattern = false end

	local ret = {}
	local current_pos = 1

	for i = 1, string_len(str) do
		local start_pos, end_pos = string_find(str, separator, current_pos, not with_pattern)
		if not start_pos then break end
		ret[i] = string_sub(str, current_pos, start_pos - 1)
		current_pos = end_pos + 1
	end

	ret[#ret + 1] = string_sub(str, current_pos)

	return ret
end

local function TABLE_COUNT(t)
	if not t then return 0 end

	local i = 0
	for _, _ in pairs(t) do
		i = i + 1
	end

	return i
end