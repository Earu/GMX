require("sourcenet")

local HEADER_COLOR = Color(255, 0, 0)
local BODY_COLOR = Color(197, 53, 17)
local function roc_print(...)
	MsgC(HEADER_COLOR, "[ROC] ", BODY_COLOR, ...)
	MsgN()
end

local is_net_attached = false
local function AttachNetChannel(net_chan)
	if is_net_attached then return false end
	if not net_chan then return false end

	Attach__CNetChan_Shutdown(net_chan)
	Attach__CNetChan_ProcessMessages()
	is_net_attached = true

	return true
end

local function DetachNetChannel(net_chan)
	if not is_net_attached then return false end
	if not net_chan then return false end

	Detach__CNetChan_Shutdown(net_chan)
	Detach__CNetChan_ProcessMessages()
	is_net_attached = false

	return true
end

if not AttachNetChannel(CNetChan()) then
	hook.Add("Think", "block_incoming_cmds", function() -- Wait until channel is created
		if CNetChan() and AttachNetChannel(CNetChan()) then
			hook.Remove("Think", "block_incoming_cmds")
		end
	end)
end

hook.Add("PreNetChannelShutdown", "block_incoming_cmds", function(net_chan, reason)
	DetachNetChannel(net_chan)
end)

local function copy_buffer_end(dest, src)
	local bits_left = src:GetNumBitsLeft()
	if bits_left < 1 then return end

	local data = src:ReadBits(bits_left)
	dest:WriteBits(data)
end

local NET_MESSAGE_BITS = 6
local WHITELIST = {
	dsp_player = true,
	gmod_toolmode = true,
}

local NET_STRINGCMD = 4
hook.Add("PreProcessMessages", "block_incoming_cmds", function(net_chan, read, write, local_chan)
	local is_local = net_chan == local_chan
	if not is_local then return false end

	while read:GetNumBitsLeft() >= NET_MESSAGE_BITS do
		local msg_type = read:ReadUInt(NET_MESSAGE_BITS)
		if msg_type ~= NET_STRINGCMD then return false end -- we don't care, just let source do its thing

		local success, _ = pcall(function()
			local cmd = read:ReadString()
			local real_cmd = cmd:Split(" ")[1]:lower():Trim()
			if WHITELIST[real_cmd] then
				write:WriteUInt(NET_STRINGCMD, NET_MESSAGE_BITS)
				write:WriteString(cmd)
				return
			end

			roc_print("Blocking incoming server command " .. cmd)
		end)

		if not success then
			roc_print("Failed to filter message " .. msg_type)
		end

		-- copy the rest of the buffer, to not lose any remaining messages
		copy_buffer_end(write, read)
		return true
	end
end)