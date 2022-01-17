hook.Add("ShouldHideFile", GEN_NAME(), function(path)
	path = path:lower()

	-- hide gmx files
	if path:match("gmx") then return true end
	if path:match("lua/bin") then return true end
end)

-- detours because fshook is wonku

local read_detours = {
	{ fn = "Read", default = nil },
	{ fn = "Time", default = 0 },
	{ fn = "IsDir", default = false },
	{ fn = "Exists", default = false },
	{ fn = "AsyncRead", default = FSASYNC_ERR_FAILURE or -5 },
	{ fn = "Rename", default = false },
	{ fn = "Size", default = 0 },
	{ fn = "CompileFile", default = function() end, global = true },
	{ fn = "include", default = nil, global = true },
}

for _, detour in ipairs(read_detours) do
	local old_fn = detour.global and _G[detour.fn] or _G.file[detour.fn]
	if old_fn then
		_G.file[detour.fn] = function(path, ...)
			if hook.Run("ShouldHideFile", path) then return detour.default end
			return old_fn(path, ...)
		end
	end
end

local write_detours = { "Append", "Write", "Open", "Delete", "CreateDir" }
for _, detour in ipairs(write_detours) do
	local old_fn = _G.file[detour]
	if old_fn then
		_G.file[detour] = function(path, ...)
			if hook.Run("ShouldHideFile", path) then return false end
			return old_fn(path, ...)
		end
	end
end

local old_file_find = _G.file.Find
function file.Find(pattern, ...)
	local files, dirs = old_file_find(pattern, ...)

	local base_path = pattern:GetPathFromFilename()
	if #base_path > 0 and not base_path:EndsWith("/") then
		base_path = base_path .. "/"
	end

	local final_files = {}
	for _, file_name in pairs(files) do
		if hook.Run("ShouldHideFile", base_path .. file_name) then continue end
		table.insert(final_files, file_name)
	end

	local final_dirs = {}
	for _, dir_name in pairs(dirs) do
		if hook.Run("ShouldHideFile", base_path .. dir_name) then continue end
		table.insert(final_dirs, dir_name)
	end

	return final_files, final_dirs
end