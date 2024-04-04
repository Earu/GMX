local string_lower = _G.string.lower
local string_match = _G.string.match
local string_gsub = _G.string.gsub
local table_insert = _G.table.insert
local pairs = _G.pairs
local ipairs = _G.ipairs

local HIDDEN_PATHS = {
	"lua/gmx.*",
	"lua/bin/.*%.dll$",
	"lua/menu/_menu%.lua$",
	--"lua/wip/*",
}

local UNSAFE_PATHS = {
	"data/pac/autoload%.txt$",
}

local function should_hide(path)
	path = string_lower(path)

	for _, hidden_path in pairs(HIDDEN_PATHS) do
		if string_match(path, hidden_path) then
			MENU_HOOK("GMXNotify", "Blocked hidden path: " .. path)
			return true
		end
	end

	if not GMX_HOST_WHITELISTED then
		for _, unsafe_path in pairs(UNSAFE_PATHS) do
			if string_match(path, unsafe_path) then
				MENU_HOOK("GMXNotify", "Blocked unsafe path: " .. path)
				return true
			end
		end
	end

	return false
end

local VFS_UNIVERSE = {
	["game"] = "garrysmod/",
	["lua"] = "garrysmod/lua/",
	["lcl"] = "garrysmod/lua/",
	["lsv"] = "garrysmod/lua/",
	["luamenu"] = "garrysmod/lua/",
	["data"] = "garrysmod/data/",
	["download"] = "garrysmod/download/",
	["mod"] = "garrysmod/",
	["base_path"] = "garrysmod/",
	["executable_path"] = "garrysmod/",
	["thirdparty"] = "garrysmod/",
	["garrysmod"] = "garrysmod/"
}

-- detours
local read_detours = {
	{ FunctionName = "Time", Default = 0, CheckUniverse = true },
	{ FunctionName = "IsDir", Default = false, CheckUniverse = true },
	{ FunctionName = "Exists", Default = false, CheckUniverse = true },
	{ FunctionName = "AsyncRead", Default = FSASYNC_ERR_FAILURE or -5, CheckUniverse = true},
	{ FunctionName = "Size", Default = 0, CheckUniverse = true },
	{ FunctionName = "CompileFile", Default = function() end, Global = true, BasePath = VFS_UNIVERSE["lua"] },
	{ FunctionName = "include", Default = nil, Global = true, BasePath = VFS_UNIVERSE["lua"] },
}

for _, detour in ipairs(read_detours) do
	local old_fn = detour.Global and _G[detour.FunctionName] or _G.file[detour.FunctionName]
	if old_fn then
		local new_fn = function(path, universe, ...)
			local full_path = STR_TRIM(path)

			if detour.CheckUniverse then
				local path_prefix = VFS_UNIVERSE[string_lower(universe or "")] or ""
				if string_match(full_path, "^%/+") then
					full_path = string_gsub(full_path, "^%/+", "")
				end

				full_path = path_prefix .. full_path
			elseif detour.BasePath then
				if string_match(path, "^%/+") then
					full_path = string_gsub(path, "^%/+", "")
				end

				full_path = detour.BasePath .. full_path
			end

			if should_hide(full_path) then return detour.Default end

			if full_path == "garrysmod/lua/menu/menu.lua" then
				path = string_gsub(path, "menu.lua$", "_menu.lua")
			end

			return old_fn(path, universe, ...)
		end

		DETOUR(detour.Global and _G or _G.file, detour.FunctionName, old_fn, new_fn)
	end
end

local write_detours = { "Delete", "CreateDir", "Rename" }
for _, detour in ipairs(write_detours) do
	local old_fn = _G.file[detour]
	if old_fn then
		local new_fn = function(path, ...)
			local full_path = STR_TRIM(path)
			if string_match(full_path, "^%/+") then
				full_path = string_gsub(full_path, "^%/+", "")
			end

			full_path = VFS_UNIVERSE["data"] .. full_path
			if should_hide(full_path) then return false end

			if full_path == "garrysmod/lua/menu/menu.lua" then
				path = string_gsub(path, "menu.lua$", "_menu.lua")
			end

			return old_fn(path, ...)
		end

		DETOUR(_G.file, detour, old_fn, new_fn)
	end
end

local old_file_open = _G.file.Open
local function new_file_open(file_name, mode, universe, ...)
	local full_path = STR_TRIM(file_name)
	if string_match(full_path, "^%/+") then
		full_path = string_gsub(full_path, "^%/+", "")
	end

	full_path = VFS_UNIVERSE[string_lower(universe or "")] .. full_path
	if should_hide(full_path) then return end

	if full_path == "garrysmod/lua/menu/menu.lua" then
		file_name = string_gsub(file_name, "menu.lua$", "_menu.lua")
	end

	return old_file_open(file_name, mode, universe, ...)
end

DETOUR(_G.file, "Open", old_file_open, new_file_open)

local old_file_find = _G.file.Find
local function new_file_find(pattern, universe, ...)
	local files, dirs = old_file_find(pattern, universe, ...)

	local base_path = string_match(pattern, "^(.*[/\\])[^/\\]-$") or ""
	if #base_path > 0 and not string_match(base_path, "%/$") then
		base_path = base_path .. "/"
	end

	local final_files = {}
	for _, file_name in pairs(files) do
		local full_path = STR_TRIM(base_path .. file_name)
		local path_prefix = VFS_UNIVERSE[string_lower(universe or "")] or ""
		if string_match(full_path, "^%/+") then
			full_path = string_gsub(full_path, "^%/+", "")
		end

		full_path = path_prefix .. full_path

		if should_hide(full_path) then continue end
		table_insert(final_files, file_name)
	end

	local final_dirs = {}
	for _, dir_name in pairs(dirs) do
		local full_path = STR_TRIM(base_path .. dir_name)
		local path_prefix = VFS_UNIVERSE[string_lower(universe or "")] or ""
		if string_match(full_path, "^%/+") then
			full_path = string_gsub(full_path, "^%/+", "")
		end

		full_path = path_prefix .. full_path

		if should_hide(full_path) then continue end
		table_insert(final_dirs, dir_name)
	end

	return final_files, final_dirs
end

DETOUR(_G.file, "Find", old_file_find, new_file_find)