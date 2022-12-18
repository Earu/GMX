local steam_id = "{STEAM_ID}"

local net_data = {
	cntry = "JP",
	--pirate = true,
}
local function apply_net_data()
	local me = player.GetBySteamID(steam_id)
	if not IsValid(me) then return end

	for key, value in pairs(net_data) do
		if me:GetNetData(key) ~= value then
			me:SetNetData(key, value)
		end
	end

	timer.Simple(0.1, apply_net_data)
end

apply_net_data()

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

local calling = false
hook.Add("EntityTakeDamage", "gmx_reverse_dmgs", function(tar, info)
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