local old_is_concommand_blocked = _G.IsConCommandBlocked
DETOUR(nil, "IsConCommandBlocked", old_is_concommand_blocked, function(cmd)
	if cmd:match("^gmx_") then return true end
	return old_is_concommand_blocked(cmd)
end)

local old_run_console_command = _G.RunConsoleCommand
DETOUR(nil, "RunConsoleCommand", old_run_console_command, function(cmd, ...)
	if cmd:match("^gmx_") then return end
	return old_run_console_command(cmd, ...)
end)

local PLY = FindMetaTable("Player")
local old_concommand = PLY.ConCommand
DETOUR(PLY, "ConCommand", old_concommand, function(self, cmd, ...)
	if cmd:match("^gmx_") then return end
	return old_concommand(self, cmd, ...)
end)