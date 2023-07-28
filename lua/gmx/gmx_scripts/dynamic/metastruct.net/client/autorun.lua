local tag = "gmx_autorun"
local next_check = 0
local next_sound = 0
hook.Add("Tick", tag, function(self)
	if CurTime() < next_check then return end

	local lp = LocalPlayer()
	if lp:IsValid() and not lp:Alive() then
		RunConsoleCommand("aowl", "revive")

		if CurTime() > next_sound then
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

if file.Exists("lua/bin/gmcl_browser_fix_win64.dll", "MOD") then
	require("browser_fix")
end

if file.Exists("lua/bin/gmcl_win_toast_win64.dll", "MOD") then
	require("win_toast")
	local base_dir = "windows_mentions"

	local function get_avatar(id64, success_callback, err_callback)
		http.Fetch("http://steamcommunity.com/profiles/" .. id64 .. "?xml=1", function(content, size)
			local ret = content:match("<avatarIcon><!%[CDATA%[(.-)%]%]></avatarIcon>")
			success_callback(ret)
		end, err_callback)
	end

	hook.Add("ECPlayerMention", tag, function(ply, msg)
		if not IsValid(ply) then
			WinToast.Show("Console / Invalid Player", msg)

			return
		end

		if ply:IsBot() then
			WinToast.Show(EasyChat.GetProperNick(ply), msg)

			return
		end

		local id64 = ply:SteamID64()
		local avatar_path = ("%s/%s.jpg"):format(base_dir, id64)

		if file.Exists(avatar_path, "DATA") then
			WinToast.Show(EasyChat.GetProperNick(ply), msg, avatar_path)
		else
			local function fallback()
				WinToast.Show(EasyChat.GetProperNick(ply), msg)
			end

			get_avatar(id64, function(avatar_url)
				http.Fetch(avatar_url, function(body)
					if not file.Exists(base_dir, "DATA") then
						file.CreateDir(base_dir)
					end

					file.Write(avatar_path, body)
					WinToast.Show(EasyChat.GetProperNick(ply), msg, avatar_path)
				end, fallback)
			end, fallback)
		end
	end)

	hook.Add("PSA", tag, function(msg)
		WinToast.Show("[PSA]", msg, "meta_avatar.jpg")
	end)

	hook.Add("AowlCountdown", tag, function(_, time, msg)
		WinToast.Show(("[Countdown - %ds]"):format(time), msg, "meta_avatar.jpg")
	end)
end

local function play_cs(text)
	net.Start("chatsounds_cmd")
		net.WriteString(text:sub(1, 60000))
	net.SendToServer()
end

local gmx_next_press = 0
hook.Add("PlayerUsedByPlayer", tag, function(me, ply)
	if CurTime() <= gmx_next_press then return end

	ply.gmx_pressed_me = ply.gmx_pressed_me and (ply.gmx_pressed_me + 1) or 1

	if ply.gmx_pressed_me >= 3 then
		if luadev and luadev.RunOnServer then
			local can_alien = util.TraceLine({ start = me:EyePos(), endpos = me:EyePos() + Vector(0, 0, 1000) }).Hit
			if not can_alien then
				play_cs("vortigaunt speech")

				luadev.RunOnServer([[
					local me = player.GetBySteamID("STEAM_0:0:80006525")
					local target = player.GetBySteamID("]] .. ply:SteamID() .. [[")
					if not IsValid(me) or not IsValid(target) then return end

					local spawn_pos = me:GetPos() + Vector(0, 0, 1000)
					if util.IsInWorld(spawn_pos) then
						local ufo = ents.Create("ufo")
						ufo:SetPos(spawn_pos)

						function ufo:GetClosestPlayer()
							if not IsValid(target) then
								ufo:Remove()
								return nil
							end

							return target
						end

						local old_touch = ufo.Touch
						function ufo:Touch(ent)
							if ent == target then
								old_touch(self, ent)
							end
						end

						ufo:CPPISetOwner(me)
						ufo:SetPos(spawn_pos)
						ufo:Spawn()

						local old_beam_touch = ufo.Beam.Touch
						function ufo.Beam:Touch(ent)
							if ent == target then
								old_touch(self, ent)
							end

						end

						SafeRemoveEntityDelayed(ufo, 20)
						hook.Add("PlayerDeath", ufo, function(_, victim, inflictor, attacker)
							if victim == target then
								ufo:Remove()
							end
						end)
					end
				]], "GMX")

				return
			end

			play_cs("prepare for launch in 3 2 1")
			luadev.RunOnServer([[timer.Simple(5, function()
				local ply = player.GetBySteamID("]] .. ply:SteamID() .. [[")
				ply:SetVelocity(Vector(0, 0, 10000))

				timer.Simple(1, function()
					if not ply:IsValid() then return end

					local explosion = ents.Create("env_explosion")
					explosion:SetPos(ply:GetPos())
					explosion:Spawn()
					explosion:Fire("explode")

					ply:Kill()
				end)
			end)]], "GMX")

			timer.Simple(5, function()
				play_cs("team rocket blasting off again")
			end)
		end

		gmx_next_press = CurTime() + 10
		ply.gmx_pressed_me = 0
	elseif ply.gmx_pressed_me == 2 then
		gmx_next_press = CurTime() + 2
		play_cs("kleiner stop")
	else
		gmx_next_press = CurTime() + 2
		play_cs("alyx no")
	end
end)