local detour_cache = {}

local function DETOUR(container, fn_name, old_fn, new_fn)
	if not container then container = _G end
	container[fn_name] = new_fn
	detour_cache[new_fn] = old_fn
end

local detours = {
	{ FunctionName = "getinfo", OriginalFunction = debug.getinfo, Container = debug },
	{ FunctionName = "getupvalue", OriginalFunction = debug.getupvalue, Container = debug },
	{ FunctionName = "dump", OriginalFunction = string.dump, Container = string },
	{ FunctionName = "tostring", OriginalFunction = tostring, Container = _G },
	{ FunctionName = "funcbc", OriginalFunction = jit.util.funcbc, Container = jit.util },
	{ FunctionName = "funcinfo", OriginalFunction = jit.util.funcinfo, Container = jit.util },
	{ FunctionName = "funck", OriginalFunction = jit.util.funck, Container = jit.util },
	{ FunctionName = "funcuvname", OriginalFunction = jit.util.funcuvname, Container = jit.util },
}

for _, detour in ipairs(detours) do
	local new_fn = function(fn, ...)
		if detour_cache[fn] then
			return detour.OriginalFunction(detour_cache[fn], ...)
		else
			return detour.OriginalFunction(fn, ...)
		end
	end

	DETOUR(detour.Container, detour.FunctionName, detour.OriginalFunction, new_fn)
end