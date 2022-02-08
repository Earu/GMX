local PRIORITY_HOOKS = {}
local function HOOK(event_name, fn)
	-- can't detour hook.Call in singleplayer/p2p hosting server as
	-- hook.Call doesn't appear in the registry clientside when that's
	-- the case, but it doesn't really matter in a singleplayer game
	-- or p2p when hosting anyway...
	if game.GetIPAddress() == "loopback" then
		hook.Add(event_name, { IsValid = function() return true end }, function(_, ...)
			fn(...)
		end)

		return
	end

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

local function detour_reg_hook_call()
	if not debug.getregistry then
		MENU_HOOK("GMXNotify", "debug.getregistry does not exist?!")
		timer.Simple(0.25, detour_reg_hook_call)
		return
	end

	local hook_call_reg_index = -1
	local cur_reg = debug.getregistry()
	for k, v in pairs(cur_reg) do
		if v == fn then
			hook_call_reg_index = k
			break
		end
	end

	if hook_call_reg_index ~= -1 then
		DETOUR(cur_reg, hook_call_reg_index, old_hook_call, hook_call_detour)
		MENU_HOOK("GMXNotify", "Detoured hook.Call in registry")
	else
		timer.Simple(0.25, detour_reg_hook_call)
	end
end

detour_reg_hook_call()