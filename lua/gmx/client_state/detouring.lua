local unpack = _G.unpack
local print = _G.print
local ipairs = _G.ipairs
local type = _G.type

local detour_cache = {}
local function DETOUR(container, fn_name, old_fn, new_fn)
	if not container then container = _G end
	if type(container) ~= "table" or not container[fn_name] or type(old_fn) ~= "function" or type(new_fn) ~= "function" then
		print("!!!!!!! BAD DETOUR: ", container, fn_name, old_fn, new_fn)
		return
	end

	container[fn_name] = new_fn
	detour_cache[new_fn] = old_fn
end

local detours = {
	{ FunctionName = "getinfo",    OriginalFunction = _G.debug.getinfo,       Container = _G.debug, CheckRet = true },
	{ FunctionName = "getupvalue", OriginalFunction = _G.debug.getupvalue,    Container = _G.debug    },
	{ FunctionName = "dump",       OriginalFunction = _G.string.dump,         Container = _G.string   },
	{ FunctionName = "tostring",   OriginalFunction = _G.tostring,            Container = _G       },
	{ FunctionName = "funcinfo",   OriginalFunction = _G.jit.util.funcinfo,   Container = _G.jit.util },
	{ FunctionName = "funcbc",     OriginalFunction = _G.jit.util.funcbc,     Container = _G.jit.util },
	{ FunctionName = "funck",      OriginalFunction = _G.jit.util.funck,      Container = _G.jit.util },
	{ FunctionName = "funcuvname", OriginalFunction = _G.jit.util.funcuvname, Container = _G.jit.util },
}

for _, detour in ipairs(detours) do
	local function new_fn(fn, ...)
		if detour_cache[fn] then
			local rets = { detour.OriginalFunction(detour_cache[fn], ...) }
			if detour.CheckRet and rets[1] and rets[1].func then
				rets[1].func = new_fn
			end

			return unpack(rets)
		else
			return detour.OriginalFunction(fn, ...)
		end
	end

	DETOUR(detour.Container, detour.FunctionName, detour.OriginalFunction, new_fn)
end