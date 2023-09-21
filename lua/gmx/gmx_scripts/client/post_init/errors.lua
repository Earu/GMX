local MsgC = _G.MsgC
local COLOR_RED = Color(255, 0, 0)

DETOUR(nil, "ErrorNoHalt", ErrorNoHalt, function(...)
	MsgC(COLOR_RED, ...)
end)

DETOUR(nil, "ErrorNoHaltWithStack", ErrorNoHaltWithStack, function(...)
	MsgC(COLOR_RED, ...)
end)