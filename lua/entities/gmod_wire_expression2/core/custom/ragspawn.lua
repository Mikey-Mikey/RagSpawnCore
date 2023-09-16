local e2_rags_per_second = CreateConVar("sbox_E2_maxRagsPerSecond", 4, FCVAR_NONE, "", 1)

E2Lib.RegisterExtension("ragspawncore", false, "E2 functions that allow the spawning of ragdolls.")

local ragspawncore = {}

registerCallback("construct", function(self)
	self.entity.ragSpawnUndo = 1
	self.player.ragsBursted = 0
	self.entity.ragsToUndo = {}
	timer.Create("wire_expression2_ragburst_clear", 1.0, 0, function()
		if self.player then
			self.player.ragsBursted = 0
		end
	end)
end)

for i,ply in ipairs(player.GetAll()) do
	ply.lastRagSpawntime = 0
end

hook.Add("PlayerInitialSpawn", "ragspawncore_plyinitspawn", function(ply, trans)
	ply.lastRagSpawntime = 0
end)

local function RagCanSpawn(ply)
	return ply.ragsBursted < GetConVar("sbox_E2_maxRagsPerSecond"):GetFloat() and true or false
end

__e2setcost(1)

e2function number ragCanSpawn()
	return RagCanSpawn(self.player) and 1 or 0
end

e2function number ragSpawnRate()
	return 1000 / e2_rags_per_second:GetFloat() -- In milliseconds
end

e2function void ragSpawnUndo(number state)
	self.entity.ragSpawnUndo = state == 1
end

function RagSpawn(model, pos, ang, frozen, chip)
	local ent = ents.Create("prop_ragdoll")
	ent:SetModel(model)

	if pos then
		ent:SetPos(pos)
	else
		ent:SetPos(chip.entity:GetPos())
	end

	if ang then
		ent:SetAngles(ang)
	else
		ent:SetAngles(Angle(0,0,0))
	end

	ent:Spawn()
	ent:Activate()

	if frozen ~= nil then
		for i = 0, ent:GetPhysicsObjectCount() - 1 do
			local bone = ent:GetPhysicsObjectNum(i)
			bone:EnableMotion(not frozen)
		end
	end

	if ( IsValid( chip.player ) ) then
		gamemode.Call( "PlayerSpawnedRagdoll", chip.player, model, ent )
	end
	return ent
end

__e2setcost(40)

e2function entity ragSpawn(string model, vector pos, angle ang, number frozen)
	if RagCanSpawn(self.player) then
		
		local ent = RagSpawn(model, pos, ang, frozen == 1 and true or false, self)
		if self.entity.ragSpawnUndo then
			undo.Create("E2 Spawned Ragdoll")
			undo.AddEntity(ent)
			undo.SetPlayer(self.player)
			undo.Finish("E2 Spawned Ragdoll")
		else
			self.entity.ragsToUndo[#self.entity.ragsToUndo + 1] = ent
		end

		self.player.ragsBursted = self.player.ragsBursted + 1

		self.player.lastRagSpawntime = CurTime()
		return ent
	end
end

e2function entity ragSpawn(string model, vector pos, number frozen)
	if RagCanSpawn(self.player) then
		
		local ent = RagSpawn(model, pos, nil, frozen == 1 and true or false, self)
		if self.entity.ragSpawnUndo then
			undo.Create("E2 Spawned Ragdoll")
			undo.AddEntity(ent)
			undo.SetPlayer(self.player)
			undo.Finish("E2 Spawned Ragdoll")
		else
			self.entity.ragsToUndo[#self.entity.ragsToUndo + 1] = ent
		end

		self.player.ragsBursted = self.player.ragsBursted + 1

		self.player.lastRagSpawntime = CurTime()
		return ent
	end
end

e2function entity ragSpawn(string model, number frozen)
	if RagCanSpawn(self.player) then
		
		local ent = RagSpawn(model, nil, nil, frozen == 1 and true or false, self)
		if self.entity.ragSpawnUndo then
			undo.Create("E2 Spawned Ragdoll")
			undo.AddEntity(ent)
			undo.SetPlayer(self.player)
			undo.Finish("E2 Spawned Ragdoll")
		else
			self.entity.ragsToUndo[#self.entity.ragsToUndo + 1] = ent
		end

		self.player.ragsBursted = self.player.ragsBursted + 1

		self.player.lastRagSpawntime = CurTime()
		return ent
	end
end

registerCallback("destruct", function(self)
	for k,v in ipairs(self.entity.ragsToUndo) do
		SafeRemoveEntity(v)
	end
end)
