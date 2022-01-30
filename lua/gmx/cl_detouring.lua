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
	if detour_cache[old_debug_getinfo][fn] then
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

-- hide the upvalues of the detour
local old_debug_getupvalue = init_detour(debug.getupvalue)
local function new_debug_getupvalue(fn, index, ...)
	if detour_cache[old_debug_getupvalue][fn] then
		if detour_cache[old_debug_getupvalue][fn][index] then
			return unpack(detour_cache[old_debug_getupvalue][fn][index])
		end

		return nil, nil
	else
		return old_debug_getupvalue(fn, index, ...)
	end
end

-- hide the bytecode of the detour
local old_string_dump = init_detour(string.dump)
local function new_string_dump(fn, dbg_info, ...)
	if detour_cache[old_string_dump][fn] then
		return detour_cache[old_string_dump][fn][dbg_info and 1 or 2]
	else
		return old_string_dump(fn, dbg_info, ...)
	end
end

-- tostring shows the address of a function
local old_tostring = init_detour(tostring)
local function new_tostring(obj, ...)
	if isfunction(obj) and detour_cache[old_tostring][obj] then
		return detour_cache[old_tostring][obj]
	else
		return old_tostring(obj, ...)
	end
end

-- TODO: jit.util

local function DETOUR(container, fn_name, old_fn, new_fn)
	if not container then container = _G end
	container[fn_name] = new_fn

	--debug.getinfo
	local info = old_debug_getinfo(old_fn, DETOUR_OPTS)
	detour_cache[old_debug_getinfo][new_fn] = info

	-- debug.getupvalue
	for i = 1, info.nups do
		local name, value = old_debug_getupvalue(old_fn, i)
		detour_cache[old_debug_getupvalue][new_fn] = detour_cache[old_debug_getupvalue][new_fn] or {}
		detour_cache[old_debug_getupvalue][new_fn][i] = { name, value }
	end

	-- string.dump
	local fn_dump_dbg = old_string_dump(old_fn, true)
	local fn_dump = old_string_dump(old_fn, false)
	detour_cache[old_string_dump][new_fn] = { fn_dump_dbg, fn_dump }

	-- tostring
	detour_cache[old_tostring][new_fn] = old_tostring(old_fn)
end

-- dont reveal ourselves
DETOUR(debug, "getinfo", old_debug_getinfo, new_debug_getinfo)
DETOUR(debug, "getupvalue", old_debug_getupvalue, new_debug_getupvalue)
DETOUR(string, "dump", old_string_dump, new_string_dump)
DETOUR(nil, "tostring", old_tostring, new_tostring)