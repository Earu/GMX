local tag = "gmx_autorun"
local next_check = 0
local next_sound = 0
hook.Add("Tick", tag, function(self)
	if CurTime() < next_check then return end
	if not engine.ActiveGamemode():match("sandbox") then return end

	local lp = LocalPlayer()
	if lp:IsValid() and not lp:Alive() then
		RunConsoleCommand("aowl", "revive")

		if CurTime() > next_sound then
			RunConsoleCommand("saysound", "hurt#1")
			next_sound = CurTime() + 2
		end
	end

	next_check = CurTime() + 0.25
end)

-- remove that, its annoying
function system.FlashWindow()
end

local function detour_libs()
	if rtchat then
		rtchat.old_QueueMessage = rtchat.old_QueueMessage or rtchat.QueueMessage

		function rtchat.QueueMessage(txt)
			local hex = txt:gsub(".", function(char) return ("%2x"):format(char:byte()) end)
			rtchat.old_QueueMessage(hex)
		end
	end

	local log_level_mapping = {
		[NOTIFY_GENERIC] = "info",
		[NOTIFY_ERROR] = "error",
		[NOTIFY_UNDO] = "warn",
		[NOTIFY_HINT] = "info",
		[NOTIFY_CLEANUP] = "warn",
	}

	local function notification_add_legacy(msg, notify_type)
		local log_level = log_level_mapping[notify_type or NOTIFY_GENERIC] or "info"
		local log_fn = _G.metalog and _G.metalog[log_level] or function(id, channel, ...) print(id, channel, ...) end
		log_fn("Notification", log_level, msg)
	end

	local function notification_add_progress(notify_id, msg)
		local log_fn = _G.metalog and _G.metalog.info or function (id, channel, ...) print(id, channel, ...) end
		log_fn("Notification", tostring(notify_id), msg)
	end

	local function notification_kill() end

	timer.Create("gmx_notification_detour", 1, 0, function()
		if not _G.notification then return end

		local already_detoured = true
		if _G.notification.AddLegacy ~= notification_add_legacy then
			_G.notification.AddLegacy = notification_add_legacy
			already_detoured = false
		end

		if _G.notification.AddProgress ~= notification_add_progress then
			_G.notification.AddProgress = notification_add_progress
			already_detoured = false
		end

		if _G.notification.Kill ~= notification_kill then
			_G.notification.Kill = notification_kill
			already_detoured = false
		end

		if already_detoured then
			timer.Remove("gmx_notification_detour")
		end
	end)
end

hook.Add("ECPostLoadModules", tag, detour_libs)
hook.Add("InitPostEntity", tag, detour_libs)