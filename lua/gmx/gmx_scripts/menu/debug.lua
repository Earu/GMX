local function compute_spacing_print_pos(tbl, compute_keys, max_spacing)
	local min = 0
	for key, value in pairs(tbl) do
		local len = #tostring(key) + 2 -- '[' + ']'
		if not compute_keys then
			len = #tostring(value)
		end

		if len > max_spacing then continue end -- ignore things that are too long

		if len > min then
			min = len
		end
	end

	return min
end

local HEADER_COLOR = Color(255, 157, 0)
local BODY_COLOR = Color(255, 196, 0)
local WHITE_COLOR = Color(255, 255, 255)
local GRAY_COLOR = Color(155, 155, 155)
local VALUE_SPACING_MAX, INFO_SPACING_MAX = 40, 24
function PrintTable(tbl)
	MsgC(GRAY_COLOR, "-- " .. tostring(tbl) .. "\n")
	MsgC(HEADER_COLOR, "{\n")

	local min_equal_pos = compute_spacing_print_pos(tbl, true, VALUE_SPACING_MAX)
	local min_info_pos = compute_spacing_print_pos(tbl, false, INFO_SPACING_MAX)
	for key, value in pairs(tbl) do
		local comment = type(value)
		if isfunction(value) then
			local info = debug.getinfo(value)
			if info.short_src == "[C]" then
				comment = "Native"
			else
				comment = info.short_src .. ":" .. info.linedefined
			end
		end

		local value_color = BODY_COLOR
		if not istable(value) and not isfunction(value) then
			value_color = HEADER_COLOR
		end

		local value_str = tostring(value)
		if isstring(value) then
			value_str = "\"" .. value_str .. "\""
		end

		local spacing_info = ""
		if #value_str < min_info_pos then
			spacing_info = (" "):rep(min_info_pos - #value_str)
		end

		local key_name = tostring(key)
		local key_len = #key_name + 2
		local spacing_value = ""
		if key_len < min_equal_pos then
			spacing_value = (" "):rep(min_equal_pos - key_len)
		end

		MsgC(HEADER_COLOR, "\t[", WHITE_COLOR, key_name, HEADER_COLOR, "]", WHITE_COLOR, spacing_value .. " = ", value_color, value_str, GRAY_COLOR, spacing_info .. " -- " .. comment .. "\n")
	end

	MsgC(HEADER_COLOR, "}\n")
end

FindMetaTable("Vector").__tostring = function(self)
	return ("Vector (%d, %d, %d)"):format(self.x, self.y, self.z)
end

local function get_function_source(fn)
	local info = debug.getinfo(fn)
	if info.short_src == "[C]" then
		return tostring(fn), "Native", -1, -1
	end

	local start_line, end_line = info.linedefined, info.lastlinedefined
	local file_path = info.source:gsub("^@", "")
	local content = file.Read(file_path, "MOD")
	if not content or #content:Trim() == 0 then return tostring(fn), "Anonymous", -1, -1 end

	local lines = ("\n"):Explode(content)
	local fn_source = table.concat(lines, "\n", start_line, end_line)
	return fn_source, file_path, start_line, end_line
end

local function markup_keyword(match)
	local start_pos, end_pos = match:find("[a-zA-Z]+")
	return ("%s<color=%d,%d,%d>%s</color>%s"):format(
		match:sub(1, start_pos - 1),
		BODY_COLOR.r, BODY_COLOR.g, BODY_COLOR.b,
		match:sub(start_pos, end_pos),
		match:sub(end_pos + 1, #match)
	)
end

local function sanitize_content(match)
	local ret = match:gsub("%<color%=%d+%,%d+%,%d+%>", ""):gsub("%<%/color%>", "")
	return ret
end

local LUA_KEYWORDS = {
	"if", "then", "else", "elseif", "end", "do", "for", "while", "in",
	"function", "local", "repeat", "until", "return", "not", "or", "and"
}
local BASE_PATTERN = "[\n\t%s%)%(%{%}%,]"
function PrintFunction(fn)
	local fn_source, file_path, start_line, end_line = get_function_source(fn)
	local header = "-- " .. tostring(fn)
	if file_path ~= "Native" and file_path ~= "Anonymous" then
		header = header .. " (" .. file_path .. ":" .. start_line .. "-" .. end_line .. ")"
	else
		header = header .. " (" .. file_path .. ")"
	end

	MsgC(GRAY_COLOR, header .. "\n")
	if file_path == "Native" or file_path == "Anonymous" then return end

	-- syntax
	fn_source = fn_source:gsub("[%[%(%)%]%{%}%.%=%,%/%*%-%+%;%%%!%~%&%|%#]", function(match)
		return ("<color=%d,%d,%d>%s</color>"):format(
			HEADER_COLOR.r, HEADER_COLOR.g, HEADER_COLOR.b,
			match
		)
	end)

	-- keywords
	for _, keyword in ipairs(LUA_KEYWORDS) do
		local pattern_body = ("%s%s%s"):format(BASE_PATTERN, keyword, BASE_PATTERN)
		local pattern_start = ("^%s%s"):format(keyword, BASE_PATTERN)
		local pattern_end = ("%s%s$"):format(BASE_PATTERN, keyword)
		fn_source = fn_source
			:gsub(pattern_body, markup_keyword)
			:gsub(pattern_start, markup_keyword)
			:gsub(pattern_end, markup_keyword)
	end
	-- strings
	do
		fn_source = fn_source:gsub("[\"\'].-[\"\']", function(match)
			return ("<color=%d,%d,%d>%s</color>"):format(
				HEADER_COLOR.r, HEADER_COLOR.g, HEADER_COLOR.b,
				sanitize_content(match)
			)
		end)

		fn_source = fn_source:gsub("%[%[.-%]%]", function(match)
			return ("<color=%d,%d,%d>%s</color>"):format(
				HEADER_COLOR.r, HEADER_COLOR.g, HEADER_COLOR.b,
				sanitize_content(match)
			)
		end)
	end

	local start_pos, end_pos
	repeat
		local new_start_pos, new_end_pos = fn_source:find("%<color%=%d+%,%d+%,%d+%>(.-)%<%/color%>", end_pos and end_pos + 1 or 1)
		if new_start_pos then
			MsgC(WHITE_COLOR, fn_source:sub(end_pos and end_pos + 1 or 1, new_start_pos - 1))
		else
			MsgC(WHITE_COLOR, fn_source:sub(end_pos and end_pos + 1 or 1))
		end

		if new_start_pos and new_end_pos then
			local r, g, b = 255, 255, 255
			local chunk = fn_source:sub(new_start_pos, new_end_pos)
			chunk:gsub("%<color%=(%d+)%,(%d+)%,(%d+)%>", function(input_r, input_g, input_b)
				r, g, b = tonumber(input_r) or 255, tonumber(input_g) or 255, tonumber(input_b) or 255
			end)

			chunk = sanitize_content(chunk)
			MsgC(Color(r, g, b, 255), chunk)
		end

		start_pos, end_pos = new_start_pos, new_end_pos
	until not start_pos and not end_pos

	MsgC("\n")
end

debug.setmetatable(function() end, {
	src = function(self) return get_function_source(self) end,
	psrc = function(self) PrintFunction(self) end,
})

local function get_first_value(tbl)
	for _, value in pairs(tbl) do
		return value
	end
end

local old_print = print
function print(...)
	local args = {...}
	local args_len = table.Count(args)
	if args_len == 1 then
		local first_arg = get_first_value(args)
		if isfunction(first_arg) then
			PrintFunction(first_arg)
		elseif istable(first_arg) then
			PrintTable(first_arg)
		else
			old_print(first_arg)
		end
	elseif args_len == 0 then
		old_print("nil")
	else
		old_print(...)
	end
end