local tag = "gmx_autorun"
local next_check = 0
local next_sound = 0
local sounds = {
	"says youre a pussy",
	"id like to apologize to anyone ive not offended yet",
	"im here to intercourse your dad",
}

local function chatsounds_say(text)
	if not _G.chatsounds then return end

	local api = _G.chatsounds.Module("API")
	pcall(api.PlaySound, text)
end

hook.Add("Tick", tag, function(self)
	if CurTime() < next_check then return end
	if not engine.ActiveGamemode():match("sandbox") then return end

	local lp = LocalPlayer()
	if lp:IsValid() and not lp:Alive() then
		RunConsoleCommand("aowl", "revive")

		if CurTime() > next_sound then
			chatsounds_say(sounds[math.random(#sounds)])
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

local ALWAYS_MUTE = {
	["STEAM_0:0:238852761"] = true, -- OPCamTick, never shuts his mouth legit.
}
timer.Create("GMXMuteAlways", 5, 0, function()
	for _, ply in ipairs(player.GetAll()) do
		if not ply:IsMuted() and ALWAYS_MUTE[ply:SteamID() or ""] then
			ply:SetMuted(true)
		end
	end
end)