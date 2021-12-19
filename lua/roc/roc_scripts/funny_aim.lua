local tag = "funny_aim"

local FOV = 45
local preserve = 1
local ignoreblocked = 1
local singletarget = 0
local targetnonanons = 0
local targetnpcs = 0
local targetplayers = 1
local aimprioritize = 1
local noscope = 0

local midx = ScrW() * .5
local midy = ScrH() * .5
local realang = Angle(0, 0, 0)
local lastang = Angle(0, 0, 0)
local newtarget = false
local scopeoffset = 0
local friends = {}

-- getting all members of the nonanon groups to mark them for later
local nonanonp = {}

local function sorter(v1, v2)
	if aimprioritize == 1 then
		if v1[5] > v2[5] then
			return true
		elseif v1[5] == v2[5] then
			if v1[6] < v2[6] then
				return true
			end
		end
	else
		if v1[3] < v2[3] then
			return true
		end
	end
end

local disfromaim = {}

local function isinfov(dist)
	if dist <= FOV then
		return true
	else
		return false
	end
end

local function angledifference(a, b)
	return math.abs(a.y - b.y)
end

local function rollover(n, min, max)
	while true do
		if n > max then
			n = min + n - max
		elseif n < min then
			n = max - min - n
		else
			return n
		end
	end
end

local function calcaim(v)
	local hat = v:LookupBone("ValveBiped.Bip01_Head1")
	local spine = v:LookupBone("ValveBiped.Bip01_Spine2")
	local origin = v:GetPos() + v:OBBCenter()
	local hatpos = Vector(0, 0, 0)
	if hat then
		hatpos = v:GetBonePosition(hat)
	elseif spine then
		hatpos = v:GetBonePosition(spine)
	else
		hatpos = origin
	end
	local scrpos = hatpos:ToScreen()
	local tracedat = {}
	tracedat.start = LocalPlayer():GetShootPos()
	tracedat.endpos = hatpos
	tracedat.mask = MASK_SHOT
	tracedat.filter = LocalPlayer()
	local trac = util.TraceLine(tracedat)
	local dmg = 0
	--local angdis = angledistance(LocalPlayer():GetShootPos():Distance(LocalPlayer():GetEyeTrace().HitPos), LocalPlayer():GetShootPos():Distance(hatpos), LocalPlayer():GetEyeTrace().HitPos:Distance(hatpos))
	local angdis = angledifference(LocalPlayer():EyeAngles(), (hatpos - LocalPlayer():GetShootPos()):Angle())
	local distocenter = math.abs(rollover(angdis, -180, 180))
	local distoplayer = LocalPlayer():GetPos():Distance(v:GetPos())
	if isinfov(distocenter) and ((trac.Entity == NULL or trac.Entity == v) or ignoreblocked == 0) then
		table.insert(disfromaim, {v,  scrpos, distocenter, hatpos, dmg, distoplayer})
	end
end

local function aimsnap()
	disfromaim = {}
	surface.SetDrawColor(Color(255,255,255))
	local targets = {}
	if targetplayers == 1 then
		targets = player.GetAll()
	end
	if targetnpcs == 1 then
		for k, v in pairs(ents.GetAll()) do
			if v:IsNPC() then
				table.insert(targets, v)
			end
		end
	end
	for k, v in pairs(targets) do
		if (v:Health() > 0 or singletarget == 1) and v:IsValid() then
			if v ~= LocalPlayer() and v:IsPlayer() then
				if not (v:GetFriendStatus() == "friend" or table.HasValue(friends, v)) then
					if not table.HasValue(nonanonp, v:SteamID64()) or targetnonanons == 1 then
						calcaim(v)
					end
				end
			elseif v:IsNPC() then
				if v:Health() > 0 and v:IsValid() then
					calcaim(v)
				end
			end
		end
	end

	table.sort(disfromaim, sorter)
	surface.SetDrawColor(Color(0 , 255, 0))
	if disfromaim[1] then
		surface.DrawLine(midx, midy, disfromaim[1][2].x, disfromaim[1][2].y)
	end
end

realang = LocalPlayer():EyeAngles()
lastang = LocalPlayer():EyeAngles()
newtarget = true

hook.Add("CreateMove", tag, function(cmd)
	if preserve then
		realang = realang + cmd:GetViewAngles() - lastang
	else
		realang = cmd:GetViewAngles()
	end
	--cmd:SetViewAngles(realang)
	if disfromaim[1] and LocalPlayer():Alive() and disfromaim[1][1]:IsValid() then
		local wep = LocalPlayer():GetActiveWeapon()
		if wep.Clip1 and wep:Clip1() > 0 then
			local targetang = (disfromaim[1][4] - LocalPlayer():GetShootPos()):Angle()
			targetang:Normalize()
			if newtarget then
				if targetang.y - cmd:GetViewAngles().y > 0 then scopeoffset = 3 else scopeoffset = -3 end
				newtarget = false
			end
			realang.y = math.NormalizeAngle(realang.y)

			if noscope == 1 then
				if cmd:KeyDown(IN_ATTACK) or math.abs(cmd:GetViewAngles().y - targetang.y) < 6 then
					cmd:SetViewAngles(targetang)
				else
					cmd:SetViewAngles(Angle(targetang.p, cmd:GetViewAngles().y - scopeoffset, 0))
				end
			else
				cmd:SetViewAngles(targetang)
			end

			if preserve == 1 then
				local move = Vector(cmd:GetForwardMove(), cmd:GetSideMove(), cmd:GetUpMove())
				move:Rotate(Angle(0, (cmd:GetViewAngles() - realang).y, (cmd:GetViewAngles() - realang).r))
				cmd:SetForwardMove(move.x)
				cmd:SetSideMove(move.y)
				cmd:SetUpMove(move.z)
			end

			lastang = cmd:GetViewAngles()
		else
			newtarget = true
			if preserve == 1 then
				cmd:SetViewAngles(realang)
			end
		end
	else
		newtarget = true
		if preserve == 1 then
			cmd:SetViewAngles(realang)
		end
	end
	lastang = cmd:GetViewAngles()
end)

if preserve == 1 then
	hook.Add("CalcView", tag, function(ply, pos, ang, fov)
		view = {}
		view.origin = pos
		view.angles = realang
		view.fov = fov
		--view.vm_angles = Angle(ang.p, (realang.y * 2) - ang.y, ang.r)
		view.vm_angles = ang
		return view
	end)
end

LocalPlayer():SetEyeAngles(realang)
hook.Add("HUDPaint", tag, aimsnap)
