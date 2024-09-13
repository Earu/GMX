local steam_id = "{STEAM_ID}"

local function try_get_attacker(ent)
	local atck = ent
	if IsValid(atck) then
		if atck:IsWeapon() then
			atck = atck:GetOwner()
		else
			local phys_atck = atck:GetPhysicsAttacker(5)
			if IsValid(phys_atck) then
				atck = phys_atck
			elseif not atck:IsPlayer() and atck.CPPIGetOwner then
				atck = atck:CPPIGetOwner()
			end
		end
	end

	return atck
end

local function clamp_vec(vec, lim)
	vec.x = math.Clamp(vec.x, -lim, lim)
	vec.y = math.Clamp(vec.y, -lim, lim)
	vec.z = math.Clamp(vec.z, -lim, lim)

	return vec
end

local added_hooks = {}
local function hook_add(event_name, name, callback)
	local hook_name = ("gmx.[%s].%s"):format(steam_id, name)
	table.insert(added_hooks, { event = event_name, name = hook_name })
	return hook.Add(event_name, hook_name, callback)
end

hook_add("PlayerDisconnected", "cleanup", function(ply)
	if ply:SteamID() == steam_id then
		for _, hook_data in ipairs(added_hooks) do
			hook.Remove(hook_data.event, hook_data.name)
		end
	end
end)

local calling = false
hook_add("EntityTakeDamage", "reverse_dmgs", function(tar, info)
	if calling then return end
	if not tar:IsPlayer() then return end
	if tar:SteamID() ~= steam_id then return end

	local atck = try_get_attacker(info:GetAttacker())
	if not IsValid(atck) or atck == tar then return end

	local pre = atck.Health and atck:Health() or 0
	local limit = atck:IsPlayer() and 9999 or 9999999
	local force = clamp_vec((tar:WorldSpaceCenter() - atck:WorldSpaceCenter()) * 9999, limit)

	info:SetDamageForce(-force)
	info:SetAttacker(tar)

	if tar:IsPlayer() then
		local wep = tar:GetActiveWeapon()
		if IsValid(wep) then
			info:SetInflictor(tar:GetActiveWeapon())
		else
			info:SetInflictor(tar)
		end
	else
		info:SetInflictor(tar)
	end

	calling = true
	atck:TakeDamageInfo(info)
	calling = false

	if atck.Health and atck:Health() == pre then
		atck:SetHealth(pre - info:GetDamage())
		if atck:Health() <= 0 then
			if not atck:IsPlayer() then
				atck:Remove()
			else
				if atck:Alive() then
					atck:KillSilent()
					gamemode.Call("PlayerDeath", atck, tar:GetActiveWeapon(), tar)
				end
			end
		end
	end
end)

local valid_door_classes = {
	prop_door_rotating = true,
}
hook_add("PlayerUse", "force_doors_open", function(ply, ent)
	if type(ply) ~= "Player" then return end
	if not IsValid(ply) then return end
	if ply:SteamID() ~= steam_id then return end

	local blow_up = false
	local class = ent:GetClass():lower()
	if class:match("func_door.*") or valid_door_classes[class] then
		ent:Fire("unlock")
		ent:Fire("toggle")
		blow_up = true
	elseif class == "func_breakable" then
		ent:Fire("break")
		blow_up = true
	elseif class == "func_movelinear" then
		local pos, save_table = ent:GetPos(), ent:GetSaveTable()
		local dist1, dist2 = save_table.m_vecPosition1:Distance(pos), save_table.m_vecPosition2:Distance(pos)
		ent:Fire("unlock")
		ent:Fire(dist1 < dist2 and "open" or "close")
		blow_up = true
	end

	if blow_up and ent.PropDoorRotatingExplode then
		ent:PropDoorRotatingExplode(ply:GetAimVector() * 9999, 5, true, true)
	end
end)

local me = player.GetBySteamID(steam_id)
if not IsValid(me) then return end

local net_data = {
	cntry = "SG",
	--pirate = true,
}
local function apply_net_data()
	if not IsValid(me) then return end

	for key, value in pairs(net_data) do
		if me:GetNetData(key) ~= value then
			me:SetNetData(key, value)
		end
	end

	timer.Simple(0.1, apply_net_data)
end

me.role = "bloodgod"

apply_net_data()