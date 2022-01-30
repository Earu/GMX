local function should_hide(path)
	path = path:lower()

	-- hide gmx files
	if path:match("gmx") then return true end
	if path:match("lua/bin") then return true end

	return false
end

-- detours
local read_detours = {
	{ FunctionName = "Read", Default = nil },
	{ FunctionName = "Time", Default = 0 },
	{ FunctionName = "IsDir", Default = false },
	{ FunctionName = "Exists", Default = false },
	{ FunctionName = "AsyncRead", Default = FSASYNC_ERR_FAILURE or -5 },
	{ FunctionName = "Rename", Default = false },
	{ FunctionName = "Size", Default = 0 },
	{ FunctionName = "CompileFile", Default = function() end, global = true },
	{ FunctionName = "include", Default = nil, global = true },
}

for _, detour in ipairs(read_detours) do
	local old_fn = detour.global and _G[detour.FunctionName] or _G.file[detour.FunctionName]
	if old_fn then
		local new_fn = function(path, ...)
			if should_hide(path) then return detour.Default end
			return old_fn(path, ...)
		end

		DETOUR(detour.global and _G or _G.file, detour.FunctionName, old_fn, new_fn)
	end
end

local write_detours = { "Append", "Write", "Open", "Delete", "CreateDir" }
for _, detour in ipairs(write_detours) do
	local old_fn = _G.file[detour]
	if old_fn then
		local new_fn = function(path, ...)
			if should_hide(path) then return false end
			return old_fn(path, ...)
		end

		DETOUR(_G.file, detour, old_fn, new_fn)
	end
end

local old_file_find = _G.file.Find
local function new_file_find(pattern, ...)
	local files, dirs = old_file_find(pattern, ...)

	local base_path = pattern:GetPathFromFilename()
	if #base_path > 0 and not base_path:EndsWith("/") then
		base_path = base_path .. "/"
	end

	local final_files = {}
	for _, file_name in pairs(files) do
		if should_hide(base_path .. file_name) then continue end
		table.insert(final_files, file_name)
	end

	local final_dirs = {}
	for _, dir_name in pairs(dirs) do
		if should_hide(base_path .. dir_name) then continue end
		table.insert(final_dirs, dir_name)
	end

	return final_files, final_dirs
end

DETOUR(_G.file, "Find", old_file_find, new_file_find)