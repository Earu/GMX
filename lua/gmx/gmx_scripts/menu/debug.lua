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

local RED_COLOR = Color(199, 116, 78)
local VALUE_SPACING_MAX, INFO_SPACING_MAX = 40, 24
function PrintTable(tbl)
	if not istable(tbl) then
		print(tbl)
		return
	end

	MsgC(gmx.Colors.TextAlternative, "-- " .. tostring(tbl) .. "\n")
	MsgC(gmx.Colors.Accent, "{\n")

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

		local value_color = gmx.Colors.AccentAlternative
		if isstring(value) then
			value_color = gmx.Colors.Accent
		elseif isnumber(value) or isbool(value) then
			value_color = RED_COLOR
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

		MsgC(gmx.Colors.Accent, "\t[", gmx.Colors.Text, key_name, gmx.Colors.Accent, "]", gmx.Colors.Text, spacing_value .. " = ", value_color, value_str, gmx.Colors.TextAlternative, spacing_info .. " -- " .. comment .. "\n")
	end

	MsgC(gmx.Colors.Accent, "}\n")
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
	local keyword = match:sub(start_pos, end_pos)
	local color = (keyword == "true" or keyword == "false") and RED_COLOR or gmx.Colors.AccentAlternative
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

local function markup_with_color(color, remove_string_markers)
	return function(match)
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
function PrintFunction(fn)
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

	-- syntax
	fn_source = fn_source
		:gsub("[%(%)%{%}%.%=%,%+%;%%%!%~%&%|%#%:0-9]", markup_with_color(gmx.Colors.Accent))
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
		fn_source = fn_source
			:gsub(pattern_body, markup_keyword)
			:gsub(pattern_start, markup_keyword)
			:gsub(pattern_end, markup_keyword)
	end

	-- strings literals
	fn_source = fn_source
		:gsub("'.-'", markup_with_color(gmx.Colors.Accent))
		:gsub("\".-\"", markup_with_color(gmx.Colors.Accent))
		:gsub("[^%-]%[%[.-%]%]", markup_with_color(gmx.Colors.Accent))

	-- comments
	fn_source = fn_source
		:gsub("%-%-[^%[%]]-\n", markup_with_color(gmx.Colors.BackgroundStrip, true))
		:gsub("%/%/.-\n", markup_with_color(gmx.Colors.BackgroundStrip, true))
		:gsub("%-%-%[%[.-%]%]", markup_with_color(gmx.Colors.BackgroundStrip, true))
		:gsub("%/%*.-%*%/", markup_with_color(gmx.Colors.BackgroundStrip, true))

	local start_pos, end_pos
	repeat
		local new_start_pos, new_end_pos = fn_source:find("%<color%=%d+%,%d+%,%d+%>(.-)%<%/color%>", end_pos and end_pos + 1 or 1)
		if new_start_pos then
			MsgC(gmx.Colors.Text, fn_source:sub(end_pos and end_pos + 1 or 1, new_start_pos - 1))
		else
			MsgC(gmx.Colors.Text, fn_source:sub(end_pos and end_pos + 1 or 1))
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
GMX_DBG_PRINT = print

hook.Add("GMXInitialized", "gmx_crash_report", function()
	local dump_path = file.Find("crashes/*.txt", "BASE_PATH", "datedesc")[1]
	if not dump_path then
		gmx.Print("Crash Report", "no file")
		return
	end

	dump_path =  "crashes/" .. dump_path

	if file.Size(dump_path, "BASE_PATH") == 0 then
		gmx.Print("Crash Report", dump_path, "empty file")
		return
	end

	gmx.Print("Crash Report", dump_path .. "\n" .. file.Read(dump_path, "BASE_PATH"))
	MsgN()
end)

local time_out_state = false
local last_tick = -1
function gmx.IsClientTimingOut()
	if last_tick == -1 then return false end
	return time_out_state, SysTime() - last_tick
end

FilterIncomingMessage(net_Tick, function(net_chan, read, write)
	local tick = read:ReadLong()
	local host_frame_time = read:ReadUInt(16)
	local host_frame_time_deviation = read:ReadInt(16)

	write:WriteUInt(net_Tick, NET_MESSAGE_BITS)
	write:WriteLong(tick)
	write:WriteUInt(host_frame_time, 16)
	write:WriteInt(host_frame_time_deviation, 16)

	last_tick = SysTime()

	return true
end)

hook.Add("GMXHostDisconnected", "gmx_client_time_out", function()
	time_out_state = false
	last_tick = -1

	RunGameUICommand("engine net_showmsg 0")
	RunGameUICommand("engine net_showpeaks none")
end)

RunGameUICommand("engine net_showmsg 0")
RunGameUICommand("engine net_showpeaks none")

local time_out_start_time = -1
hook.Add("Think", "gmx_client_time_out", function()
	if last_tick == -1 then return end

	local is_timing_out = SysTime() - last_tick > 1
	if is_timing_out ~= time_out_state then
		time_out_state = is_timing_out
		if is_timing_out then
			time_out_start_time = SysTime()

			gmx.Print("TimeOut", "client is timing out, enabling debugging!")

			RunGameUICommand("engine net_showmsg 1")
			RunGameUICommand("engine net_showpeaks 2000")
		else
			gmx.Print("TimeOut", time_out_start_time ~= -1 and ("client recovered (%fs)!"):format(SysTime() - time_out_start_time) or "client recovered!")

			RunGameUICommand("engine net_showmsg 0")
			RunGameUICommand("engine net_showpeaks none")
		end

		hook.Run("GMXClientTimeOut", time_out_state)
	end
end)