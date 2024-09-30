FindMetaTable("Vector").__tostring = function(self)
	return ("Vector (%d, %d, %d)"):format(self.x, self.y, self.z)
end

FindMetaTable("Angle").__tostring = function(self)
	return ("Angle (%d, %d, %d)"):format(self.pitch, self.yaw, self.roll)
end

FindMetaTable("Color").__tostring = function(self)
	return ("Color (%d, %d, %d, %d)"):format(self.r, self.g, self.b, self.a)
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

local function compute_spacing_print_pos(tbl, compute_keys, max_spacing)
	local min = 0
	for key, value in pairs(tbl) do
		local len = #tostring(key) + 2 -- '[' + ']'
		if isstring(key) then
			len = len + 2 -- ""
		end

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

local DBG = gmx.Module("Debug")
local LITERAL_COLOR = Color(199, 116, 78)
local STR_LITERAL_COLOR = Color(162, 255, 150)
local VALUE_SPACING_MAX, INFO_SPACING_MAX = 40, 30
function DBG.PrintTable(tbl)
	if not istable(tbl) then
		print(tbl)
		return
	end

	local final_args = {
		gmx.Colors.TextAlternative, "-- " .. tostring(tbl) .. "\n",
		gmx.Colors.Accent, "{\n",
	}

	local min_equal_pos = compute_spacing_print_pos(tbl, true, VALUE_SPACING_MAX)
	local tbl_keys = table.GetKeys(tbl)
	table.sort(tbl_keys, function(a, b) return tostring(a) < tostring(b) end)

	for _, key in ipairs(tbl_keys) do
		local value = tbl[key]
		local comment = type(value)
		local value_str = tostring(value)
		local args = { gmx.Colors.AccentAlternative, value_str }

		if isfunction(value) then
			local info = debug.getinfo(value)
			if info.short_src == "[C]" then
				comment = "Native"
			else
				local fn_source, file_path = get_function_source(value)
				if file_path ~= "Native" and file_path ~= "Anonymous" then
					local fn_params = fn_source:Split("\n")[1]:match("function.*%((.*)%)")

					args = { gmx.Colors.Accent, "function", gmx.Colors.Text, " (", fn_params, ")" }
					value_str = "function (" .. fn_params .. ")"
				else
					args = { gmx.Colors.Accent, value_str }
				end

				comment = info.short_src .. ":" .. info.linedefined
			end
		elseif isstring(value) then
			value_str = "\"" .. value_str .. "\""
			args = { STR_LITERAL_COLOR, value_str }
		elseif isnumber(value) or isbool(value) then
			args = { LITERAL_COLOR, value_str }
		elseif IsColor(value) or type(value) == "Vector" or type(value) == "Angle" then
			local type_name = IsColor(value) and "Color" or type(value)
			args = { gmx.Colors.AccentAlternative, type_name, gmx.Colors.Text, " (" }
			value_str = type_name .. " ("

			local col_components = { value:Unpack() }
			for i, col_component in ipairs(col_components) do
				table.insert(args, LITERAL_COLOR)
				table.insert(args, tostring(col_component))
				table.insert(args, gmx.Colors.Text)

				value_str = value_str .. tostring(col_component)

				if i < #col_components then
					table.insert(args, ", ")
					value_str = value_str .. ", "
				end
			end

			table.insert(args, gmx.Colors.Text)
			table.insert(args, ")")
			value_str = value_str .. ")"

			if type_name == "Color" then
				comment = { "Color (", value, "███", gmx.Colors.TextAlternative, ")" }
			end
		elseif istable(value) then
			if table.Count(value) == 0 then
				value_str = "{}"
				args = { gmx.Colors.Text, value_str }
				comment = "table (empty)"
			end
		end

		local spacing_info = ""
		if #value_str < INFO_SPACING_MAX then
			spacing_info = (" "):rep(INFO_SPACING_MAX - #value_str)
		end

		local key_name = tostring(key)
		local key_len = #key_name + 2 + (isstring(key) and 2 or 0)
		local spacing_value = ""
		if key_len < min_equal_pos then
			spacing_value = (" "):rep(min_equal_pos - key_len)
		end

		local line_args = {}
		if isstring(key) then
			line_args = {
				gmx.Colors.Accent, "\t[", gmx.Colors.Text, "\"", key_name, "\"", gmx.Colors.Accent, "]",
				gmx.Colors.Text, spacing_value .. " = "
			}
		else
			line_args = {
				gmx.Colors.Accent, "\t[", LITERAL_COLOR, key_name, gmx.Colors.Accent, "]",
				gmx.Colors.Text, spacing_value .. " = "
			}
		end

		line_args = table.Add(line_args, args)
		line_args = table.Add(line_args, { gmx.Colors.TextAlternative, spacing_info .. " -- "})

		if isstring(comment) then
			table.insert(line_args, comment .. "\n")
		elseif istable(comment) then
			line_args = table.Add(line_args, comment)
			table.insert(line_args, "\n")
		end

		final_args = table.Add(final_args, line_args)
	end

	table.insert(final_args, gmx.Colors.Accent)
	table.insert(final_args, "}\n")

	MsgC(unpack(final_args))
end

local function markup_keyword(match)
	local start_pos, end_pos = match:find("[a-zA-Z]+")
	local keyword = match:sub(start_pos, end_pos)
	local color = (keyword == "true" or keyword == "false") and LITERAL_COLOR or gmx.Colors.Accent
	return ("%s<color=%d,%d,%d>%s</color>%s"):format(
		match:sub(1, start_pos - 1),
		color.r, color.g, color.b,
		keyword,
		match:sub(end_pos + 1, #match)
	)
end

local function sanitize_content(match, remove_string_markers)
	local ret = match:gsub("%<color%=%d+%,%d+%,%d+%>", ""):gsub("%<%/color%>", "")
	if remove_string_markers then
		ret = ret:gsub("[\"']", "")
	end

	return ret
end

local function markup_with_color(color_to_use, remove_string_markers, color_literals)
	return function(match)
		local color = color_to_use
		if color_literals and match:match("[0-9]") and #match == 1 then
			color = LITERAL_COLOR
		end

		return ("<color=%d,%d,%d>%s</color>"):format(
			color.r, color.g, color.b,
			sanitize_content(match, remove_string_markers)
		)
	end
end

local LUA_KEYWORDS = {
	"if", "then", "else", "elseif", "end", "do", "for", "while", "in",
	"function", "local", "repeat", "until", "return", "not", "or", "and",
	"false", "true"
}
local BASE_LUA_KEYWORD_PATTERN = "[\n\t%s%)%(%{%}%,%<%>]"
function DBG.PrintCode(code)
	local args = {}

	-- syntax
	code = code
		:gsub("[%(%)%{%}%.%=%,%+%;%%%!%~%&%|%#%:0-9]", markup_with_color(gmx.Colors.Accent, false, true))
		:gsub("[^%[]%[[^%[]",function(match) -- table indexing [
			return match[1] .. markup_with_color(gmx.Colors.Accent, true)(match[2]) .. match[3]
		end)
		:gsub("[^%]]%][^%]]",function(match) -- table indexing ]
			return match[1] .. markup_with_color(gmx.Colors.Accent, true)(match[2]) .. match[3]
		end)

	-- keywords
	for _, keyword in ipairs(LUA_KEYWORDS) do
		local pattern_body = ("%s%s%s"):format(BASE_LUA_KEYWORD_PATTERN, keyword, BASE_LUA_KEYWORD_PATTERN)
		local pattern_start = ("^%s%s"):format(keyword, BASE_LUA_KEYWORD_PATTERN)
		local pattern_end = ("%s%s$"):format(BASE_LUA_KEYWORD_PATTERN, keyword)
		code = code
			:gsub(pattern_body, markup_keyword)
			:gsub(pattern_start, markup_keyword)
			:gsub(pattern_end, markup_keyword)
	end

	-- strings literals
	code = code
		:gsub("'.-'", markup_with_color(STR_LITERAL_COLOR))
		:gsub("\".-\"", markup_with_color(STR_LITERAL_COLOR))
		:gsub("[^%-]%[%[.-%]%]", markup_with_color(STR_LITERAL_COLOR))

	-- comments
	code = code
		:gsub("%-%-[^%[%]]-\n", markup_with_color(gmx.Colors.BackgroundStrip, true))
		:gsub("%/%/.-\n", markup_with_color(gmx.Colors.BackgroundStrip, true))
		:gsub("%-%-%[%[.-%]%]", markup_with_color(gmx.Colors.BackgroundStrip, true))
		:gsub("%/%*.-%*%/", markup_with_color(gmx.Colors.BackgroundStrip, true))

	local start_pos, end_pos
	repeat
		local new_start_pos, new_end_pos = code:find("%<color%=%d+%,%d+%,%d+%>(.-)%<%/color%>", end_pos and end_pos + 1 or 1)
		if new_start_pos then
			args = table.Add(args, { gmx.Colors.Text, code:sub(end_pos and end_pos + 1 or 1, new_start_pos - 1) })
		else
			args = table.Add(args, { gmx.Colors.Text, code:sub(end_pos and end_pos + 1 or 1) })
		end

		if new_start_pos and new_end_pos then
			local r, g, b = 255, 255, 255
			local chunk = code:sub(new_start_pos, new_end_pos)
			chunk:gsub("%<color%=(%d+)%,(%d+)%,(%d+)%>", function(input_r, input_g, input_b)
				r, g, b = tonumber(input_r) or 255, tonumber(input_g) or 255, tonumber(input_b) or 255
			end)

			chunk = sanitize_content(chunk)
			args = table.Add(args, { Color(r, g, b, 255), chunk })
		end

		start_pos, end_pos = new_start_pos, new_end_pos
	until not start_pos and not end_pos

	table.insert(args, "\n")
	MsgC(unpack(args))
end

function DBG.PrintFunction(fn)
	if not isfunction(fn) then
		print(fn)
		return
	end

	local fn_source, file_path, start_line, end_line = get_function_source(fn)
	local fn_address = tostring(fn):gsub("function%:%s", "")
	MsgC(gmx.Colors.TextAlternative, ("-- %s\n"):format(fn_address))
	if file_path ~= "Native" and file_path ~= "Anonymous" then
		MsgC(gmx.Colors.TextAlternative, ("-- %s:%d-%d\n"):format(file_path, start_line, end_line))
	else
		MsgC(gmx.Colors.TextAlternative, ("-- %s\n"):format(file_path))
	end

	if file_path == "Native" or file_path == "Anonymous" then return end

	DBG.PrintCode(fn_source)
end

debug.setmetatable(function() end, {
	src = function(self) return get_function_source(self) end,
	psrc = function(self) DBG.PrintFunction(self) end,
})

function DBG.PrintVector(vec)
	MsgC(gmx.Colors.AccentAlternative, "Vector", gmx.Colors.Text, " (",
		LITERAL_COLOR, vec.x, gmx.Colors.Text, ", ",
		LITERAL_COLOR, vec.y, gmx.Colors.Text, ", ",
		LITERAL_COLOR, vec.z, gmx.Colors.Text, ")\n"
	)
end

function DBG.PrintAngle(ang)
	MsgC(gmx.Colors.AccentAlternative, "Angle", gmx.Colors.Text, " (",
		LITERAL_COLOR, ang.pitch, gmx.Colors.Text, ", ",
		LITERAL_COLOR, ang.yaw, gmx.Colors.Text, ", ",
		LITERAL_COLOR, ang.roll, gmx.Colors.Text, ")\n"
	)
end

function DBG.PrintColor(col)
	MsgC(gmx.Colors.TextAlternative, "-- Color (", col, "███", gmx.Colors.TextAlternative, ")\n")
	MsgC(gmx.Colors.AccentAlternative, "Color", gmx.Colors.Text, " (",
		LITERAL_COLOR, col.r, gmx.Colors.Text, ", ",
		LITERAL_COLOR, col.g, gmx.Colors.Text, ", ",
		LITERAL_COLOR, col.b, gmx.Colors.Text, ", ",
		LITERAL_COLOR, col.a, gmx.Colors.Text, ")\n"
	)
end

function DBG.PrintString(str)
	MsgC(gmx.Colors.TextAlternative, ("-- %d bytes\n"):format(#str), STR_LITERAL_COLOR, "\"" .. str .. "\"\n")
end

function DBG.PrintLiteral(literal)
	if isnumber(literal) or literal == true or literal == false then
		MsgC(LITERAL_COLOR, tostring(literal) .. "\n")
	else
		print(literal)
	end
end

function DBG.PrintNil()
	MsgC(gmx.Colors.Accent, "nil\n")
end

function DBG.Print(...)
	local args = {...}
	if not next(args) then
		DBG.PrintNil()
		return
	end

	for _, arg in pairs(args) do
		if isfunction(arg) then
			DBG.PrintFunction(arg)
		elseif type(arg) == "Vector" then
			DBG.PrintVector(arg)
		elseif type(arg) == "Angle" then
			DBG.PrintAngle(arg)
		elseif istable(arg) then
			if IsColor(arg) then
				DBG.PrintColor(arg)
				continue
			end

			DBG.PrintTable(arg)
		elseif isstring(arg) then
			DBG.PrintString(arg)
		elseif isnumber(arg) or arg == true or arg == false then
			DBG.PrintLiteral(arg)
		else
			print(arg)
		end
	end
end