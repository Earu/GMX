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
	local GTERM_PATH = "C:/Users/Earu/source/repos/GTerm/bin/Release/GTerm.exe"
	gterm_pid = Process.Start(GTERM_PATH)
end