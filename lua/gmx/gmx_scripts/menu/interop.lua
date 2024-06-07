local INTEROP = gmx.Module("Interop")
local BASE = "123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
function INTEROP.GenerateUID(len)
	len = len or 8

	local ret = ""
	for _ = 0, len do
		ret = ret .. BASE[math.random(#BASE)]
	end

	return ret
end

if INTEROP.ComIdentifier then
	concommand.Remove(INTEROP.ComIdentifier)
else
	-- if we reload keep the same id to not break stuff
	INTEROP.ComIdentifier = INTEROP.GenerateUID()
end

INTEROP.CypherOffset = INTEROP.CypherOffset or math.random(1, 100)

function INTEROP.Decypher(str)
	local t = {}
	local chunks = str:Split(".")
	for _, chunk in ipairs(chunks) do
		local n = tonumber(chunk)
		if not n then continue end

		table.insert(t, string.char(n + INTEROP.CypherOffset))
	end

	return table.concat(t, "")
end

local ERR_COLOR = Color(255, 0, 0)
concommand.Add(INTEROP.ComIdentifier, function(_, _, _, data)
	local secure_id = data:Trim()
	if #secure_id == 0 then return end

	local path = "materials/" .. secure_id .. ".vtf"
	if not file.Exists(path, "DATA") then return end

	local contents = file.Read(path, "DATA")
	file.Delete(path, "DATA")

	if not contents or #contents == 0 then return end

	local code = INTEROP.Decypher(util.Base64Decode(contents))
	local err = RunString(code, "gmx_interop", false)
	if isstring(err) then
		MsgC(ERR_COLOR, "[gmx_interop] ", err, "\n---------------\n", code)
	end
end)

gmx.RegisterConstantProvider("GMX_CODE_IDENTIFIER", INTEROP.ComIdentifier)
gmx.RegisterConstantProvider("GMX_CYPHER_OFFSET", INTEROP.CypherOffset)

local cur_data_req_id = 0
local data_req_callbacks = {}
function INTEROP.RequestClientData(code, callback)
	if not IsInGame() then callback() return end

	data_req_callbacks[cur_data_req_id] = callback

	gmx.RunOnClient([[local ret = select(1, ]] .. code .. [[) MENU_HOOK("ClientDataRequest", ]] .. cur_data_req_id .. [[, ret)]], { "util", "interop" })
	cur_data_req_id = cur_data_req_id + 1
end

hook.Add("ClientDataRequest", "gmx_client_data_requests", function(id, data)
	local callback_id = tonumber(id) or -1
	if callback_id == -1 then return end
	if not data_req_callbacks[callback_id] then return end

	data_req_callbacks[callback_id](data)
end)
