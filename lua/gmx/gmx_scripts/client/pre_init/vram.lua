local debug_getinfo = _G.debug.getinfo
local pairs = _G.pairs
local ipairs = _G.ipairs
local table_insert = _G.table.insert
local table_sort = _G.table.sort
local string_format = _G.string.format
local timer_Simple = _G.timer.Simple

-- functions that allocate VRAM (textures / materials / render targets / meshes /
-- font atlases). calling these with unique names inside hooks or loops, or building
-- meshes without ever :Destroy()-ing them, is the classic way GMod leaks VRAM, so we
-- tally every call and attribute it to the script that made it.
local VRAM_FUNCTIONS = {
	{ Container = nil,        Name = "Material" },
	{ Container = nil,        Name = "CreateMaterial" },
	{ Container = nil,        Name = "GetRenderTarget" },
	{ Container = nil,        Name = "GetRenderTargetEx" },
	{ Container = nil,        Name = "Mesh",       Label = "Mesh" }, -- allocates an IMesh vertex buffer
	{ Container = _G.surface, Name = "CreateFont", Label = "surface.CreateFont" },
}

-- stats[label] = { total = <number>, paths = { [script_path] = <count> } }
local stats = {}

-- our own frames share this source (the whole pre-init chunk runs as one script),
-- so we skip them when walking the stack to find the real caller.
local SELF_SOURCE = debug_getinfo(1, "S").source
local MAX_STACK_WALK = 16

local function resolve_script_path()
	for level = 2, MAX_STACK_WALK do
		local info = debug_getinfo(level, "S")
		if not info then break end

		if info.what ~= "C" and info.source ~= SELF_SOURCE then
			return info.short_src or info.source or "unknown"
		end
	end

	return "unknown"
end

local function record_call(label)
	local stat = stats[label]
	if not stat then
		stat = { total = 0, paths = {} }
		stats[label] = stat
	end

	local path = resolve_script_path()
	stat.paths[path] = (stat.paths[path] or 0) + 1
	stat.total = stat.total + 1
end

for _, entry in ipairs(VRAM_FUNCTIONS) do
	local container = entry.Container or _G
	local old_fn = container[entry.Name]
	if old_fn then
		local label = entry.Label or entry.Name
		DETOUR(entry.Container, entry.Name, old_fn, function(...)
			record_call(label)
			return old_fn(...)
		end)
	end
end

timer_Simple(30, function()
	print("\n===== GMX VRAM ALLOCATION BREAKDOWN =====")

	local labels = {}
	for label in pairs(stats) do
		table_insert(labels, label)
	end

	if #labels == 0 then
		print("No VRAM-allocating calls recorded yet.")
		return
	end

	table_sort(labels, function(a, b) return stats[a].total > stats[b].total end)

	for _, label in ipairs(labels) do
		local stat = stats[label]
		print(string_format("\n%s ", label), string_format("(%d calls)", stat.total))

		local rows = {}
		for path, count in pairs(stat.paths) do
			table_insert(rows, { path = path, count = count })
		end

		table_sort(rows, function(a, b) return a.count > b.count end)

		for _, row in ipairs(rows) do
			print(string_format("    %8d  %s", row.count, row.path))
		end
	end

	print("\n=========================================")
	stats = {}
end)
