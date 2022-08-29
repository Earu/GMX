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

local ascii = "[GMX REDACTED]"
local function detour_rtchat()
	if not rtchat then return end
	rtchat.old_QueueMessage = rtchat.old_QueueMessage or rtchat.QueueMessage

	function rtchat.QueueMessage(txt)
		rtchat.old_QueueMessage(ascii)
	end
end

hook.Add("ECPostLoadModules", tag, detour_rtchat)
hook.Add("InitPostEntity", tag, detour_rtchat)

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