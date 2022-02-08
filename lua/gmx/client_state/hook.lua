local PRIORITY_HOOKS = {}
local function HOOK(event_name, fn)
	if not PRIORITY_HOOKS[event_name] then
		PRIORITY_HOOKS[event_name] = {}
	end

	table.insert(PRIORITY_HOOKS[event_name], fn)
end

local old_hook_call = hook.Call
local function hook_call_detour(event_name, gm, ...)
	if PRIORITY_HOOKS[event_name] then
		for _, fn in ipairs(PRIORITY_HOOKS[event_name]) do
			local ret = fn(...)
			if ret ~= nil then return ret end
		end
	end

	return old_hook_call(event_name, gm, ...)
end

DETOUR(hook, "Call", old_hook_call, hook_call_detour)

local get_registry = debug.getregistry and debug.getregistry or function() return {} end
local cur_reg = get_registry()
local function find_fn_in_register(func)
	for k, v in pairs(cur_reg) do
		if v == func then return k end
	end
end

local hook_call_reg_index = find_fn_in_register(old_hook_call)
DETOUR(cur_reg, hook_call_reg_index, old_hook_call, hook_call_detour)