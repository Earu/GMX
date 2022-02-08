local BAD_PATHS = {
	".*gmx.*",
	"lua/bin/.*luaerror.*%.dll$",
	"lua/bin/.*http_filter.*%.dll$",
	"lua/bin/.*proc.*%.dll$",
	"lua/bin/.*rocx.*%.dll$",
	"lua/bin/.*sourcenet.*%.dll$",
	"lua/bin/.*stringtable.*%.dll$",
	"lua/bin/.*zip.*%.dll$",
	"lua/bin/.*xconsole.*%.dll$",
}

local function should_hide(path)
	path = path:lower()

	for _, bad_path in pairs(BAD_PATHS) do
		if path:match(bad_path) then
			MENU_HOOK("GMXNotify", "Blocked bad path: " .. path)
			return true
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
	{ FunctionName = "Read", Default = "", CheckUniverse = true },
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
			local full_path = path:Trim()

			if detour.CheckUniverse then
				local path_prefix = VFS_UNIVERSE[(universe or ""):lower()] or ""
				if full_path:match("^%/+") then
					full_path = full_path:gsub("^%/+", "")
				end

				full_path = path_prefix .. full_path
			elseif detour.BasePath then
				if full_path:match("^%/+") then
					full_path = path:gsub("^%/+", "")
				end

				full_path = detour.BasePath .. full_path
			end

			if should_hide(full_path) then return detour.Default end
			return old_fn(path, universe, ...)
		end

		DETOUR(detour.Global and _G or _G.file, detour.FunctionName, old_fn, new_fn)
	end
end

local write_detours = { "Append", "Write", "Open", "Delete", "CreateDir", "Rename" }
for _, detour in ipairs(write_detours) do
	local old_fn = _G.file[detour]
	if old_fn then
		local new_fn = function(path, ...)
			local full_path = path:Trim()
			if full_path:match("^%/+") then
				full_path = full_path:gsub("^%/+", "")
			end

			full_path = VFS_UNIVERSE["data"] .. full_path
			if should_hide(full_path) then return false end

			return old_fn(path, ...)
		end

		DETOUR(_G.file, detour, old_fn, new_fn)
	end
end

local old_file_find = _G.file.Find
local function new_file_find(pattern, universe, ...)
	local files, dirs = old_file_find(pattern, universe, ...)

	local base_path = pattern:GetPathFromFilename()
	if #base_path > 0 and not base_path:EndsWith("/") then
		base_path = base_path .. "/"
	end

	local final_files = {}
	for _, file_name in pairs(files) do
		local full_path = (base_path .. file_name):Trim()
		local path_prefix = VFS_UNIVERSE[(universe or ""):lower()] or ""
		if full_path:match("^%/+") then
			full_path = full_path:gsub("^%/+", "")
		end

		full_path = path_prefix .. full_path

		if should_hide(full_path) then continue end
		table.insert(final_files, file_name)
	end

	local final_dirs = {}
	for _, dir_name in pairs(dirs) do
		local full_path = (base_path .. dir_name):Trim()
		local path_prefix = VFS_UNIVERSE[(universe or ""):lower()] or ""
		if full_path:match("^%/+") then
			full_path = full_path:gsub("^%/+", "")
		end

		full_path = path_prefix .. full_path

		if should_hide(full_path) then continue end
		table.insert(final_dirs, dir_name)
	end

	return final_files, final_dirs
end

DETOUR(_G.file, "Find", old_file_find, new_file_find)