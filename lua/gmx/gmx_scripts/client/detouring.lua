local table_copy = table.Copy
local DETOUR_OPTS = "flLnSu"

local detour_cache = {}
local function init_detour(fn)
	detour_cache[fn] = detour_cache[fn] or {}
	return fn
end

-- hide our detours
local old_debug_getinfo = init_detour(debug.getinfo)
local function new_debug_getinfo(fn, fields, ...)
	if isfunction(fn) and detour_cache[old_debug_getinfo][fn] then
		local cache = detour_cache[old_debug_getinfo][fn]
		if not fields or #fields == 0 then
			local ret = table_copy(cache)
			ret.activelines = nil
			return ret
		end

		local ret = {}
		if fields:match("f") then ret.func = cache.func end
		if fields:match("l") then ret.currentline = cache.currentline end
		if fields:match("L") then ret.activelines = cache.activelines end
		if fields:match("S") then
			ret.linedefined = cache.linedefined
			ret.lastlinedefined = cache.lastlinedefined
			ret.source = cache.source
			ret.short_src = cache.short_src
			ret.what = cache.what
		end

		if fields:match("n") then ret.namewhat = cache.namewhat end
		if fields:match("u") then
			ret.nups = cache.nups
			ret.nparams = cache.nparams
			ret.isvararg = cache.isvararg
		end

		return ret
	else
		return old_debug_getinfo(fn, fields, ...)
	end
end

local old_debug_getupvalue = init_detour(debug.getupvalue)
local function new_debug_getupvalue(fn, index, ...)
	if isfunction(fn) and detour_cache[old_debug_getupvalue][fn] then
		if detour_cache[old_debug_getupvalue][fn][index] then
			return unpack(detour_cache[old_debug_getupvalue][fn][index])
		end

		return nil, nil
	else
		return old_debug_getupvalue(fn, index, ...)
	end
end

local function DETOUR(container, fn_name, old_fn, new_fn)
	if not container then container = _G end
	container[old_fn] = new_fn

	local info = old_debug_getinfo(old_fn, DETOUR_OPTS)
	detour_cache[old_debug_getinfo][new_fn] = info

	for i = 1, info.nups do
		local name, value = old_debug_getupvalue(old_fn, _)
		detour_cache[old_debug_getupvalue][new_fn] = detour_cache[old_debug_getupvalue][new_fn] or {}
		detour_cache[old_debug_getupvalue][new_fn][i] = { name, value }
	end
end

-- dont reveal ourselves
DETOUR(debug, "getinfo", old_debug_getinfo, new_debug_getinfo)
DETOUR(debug, "getupvalue", old_debug_getupvalue, new_debug_getupvalue)