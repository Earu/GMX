local function error_filtering(_, read, write)
	local bits = read:ReadUInt(20)
	local msg_type = read:ReadByte()

	-- lua error, don't send to server
	if msg_type == 2 then
		--local err = read:ReadString()
		--write:WriteString(err)
		return true
	end

	write:WriteUInt(clc_GMod_ClientToServer, NET_MESSAGE_BITS)
	write:WriteUInt(bits, 20)
	write:WriteByte(msg_type)

	local remaining_bits = bits - 8
	if msg_type == 0 then
		local id = read:ReadWord()
		remaining_bits = remaining_bits - 16

		write:WriteWord(id)

		if remaining_bits > 0 then
			local data = read:ReadBits(remaining_bits)
			write:WriteBits(data)
		end
	elseif msg_type == 4 then
		local count = remaining_bits / 16
		for i = 1, count do
			local id = read:ReadUInt(16)
			write:WriteUInt(id, 16)
		end
	end
end

FilterOutgoingMessage(clc_GMod_ClientToServer, error_filtering)

local COLOR_RED = Color(255, 0, 0, 255)
local ERROR_NOTIFICATION_TIME = 10

local prev_error = {}
hook.Add("OnLuaError", "gmx_client_errors", function(err, realm, stack, addon_title, addon_id)
	if not addon_id then addon_id = 0 end

	if prev_error
		and prev_error.Expiration and prev_error.Expiration > CurTime()
		and prev_error.Realm == realm
		and prev_error.AddonTitle == addon_title
		and prev_error.AddonID == addon_id
	then
		return
	end

	if isstring(addon_title) then
		err = ("[%s | %s] error: %s"):format(addon_title, realm, err)
	else
		err = ("[%s] error: %s"):format(realm, err)
	end

	gmx.Notification(err, ERROR_NOTIFICATION_TIME, COLOR_RED)

	prev_error = {
		AddonID = addon_id,
		AddonTitle = addon_title,
		Realm = realm,
		Expiration = CurTime() + ERROR_NOTIFICATION_TIME,
	}
end)