require("xconsole")
require("proc")

local gterm_pid = 0
local function is_gterm_running()
	if gterm_pid == 0 then
		local procs = Process.FindPIDs("GTerm.exe")
		if #procs > 0 then
			gterm_pid = procs[1]
			return true
		else
			return false
		end
	else
		return Process.IsRunning(gterm_pid)
	end
end

if not is_gterm_running() then
	local GTERM_PATH = "C:/Users/Earu/source/repos/GTerm/bin/x64/Release/GTerm.exe"
	local success, pid = Process.Start(GTERM_PATH, "--startasgmod 0")
	if success then gterm_pid = pid end
end

hook.Add("Think", "external_console", function()
	local key_name = input.LookupBinding("toggleconsole")
	if not key_name then return end

	local key_code = input.GetKeyCode(key_name)
	if input.IsButtonDown(key_code) and is_gterm_running() then
		Process.BringToFront(gterm_pid)
	end
end)