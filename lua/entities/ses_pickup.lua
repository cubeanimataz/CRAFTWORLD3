--CRAFTWORLD 2 (C) JEN WALTER 2019
--This source code file is NOT to be uploaded to other people or on websites, you WILL lose co-owner privileges otherwise!
--FILE: ses_pickup
--PURPOSE: Serves as the item entity ingame.
--PROGRAMMING DIFFICULTY: [||||||    ]Above Medium
--ASK FOR HELP IF YOU ARE STUCK OR ARE NOT SURE WHAT TO DO
--DO NOT REMOVE THESE COMMENTS

AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )


ENT.PrintName		= "Pickup"
ENT.Author			= "Jen Walter [owner and main programmer], Jaiike Synx [co-owner and assistant programmer]"
ENT.Information		= "Item drop from CraftWoRLD 2."
ENT.Category		= "CraftWoRLD 2"

ENT.Editable			= true
ENT.Spawnable			= true
ENT.AdminOnly			= true
ENT.RenderGroup 		= RENDERGROUP_TRANSLUCENT

list.Set( "SENT", "Pickup", {
	Name = "Pickup", 
	Class = "ses_pickup", 
	Category = "CraftWoRLD 2"
} )

function ENT:SpawnFunction( ply, tr, ClassName )

	if ( !tr.Hit ) then return end
	
	local SpawnPos = tr.HitPos + tr.HitNormal * 10
	
	local ent = ents.Create( ClassName )
	ent:SetPos( SpawnPos )
	ent:Spawn()
	
	return ent
	
end

if ( SERVER ) then
function ENT:Set64Health(hp) --why? *sigh* i don't know but don't touch this
	self.Health64 = math.Round(hp)
end
function ENT:Initialize()

		if (GetConVar("craftworld3_pickups"):GetInt() or 1) == 0 then self:Remove() return end
		
		self:SetPos(self:GetPos())
		
		self.SourceAngle = self:GetAngles()
		self.AngleFrame = 0
		
		if self.ItemID == nil then
			self.ItemID = math.random(4)
		end
		
		self.PickupName = "[UNDEFINED NAME]"
		
		self.ItemOwner = "unassigned"

		self.Desc = ""
		self.ModelPath = ""
		
		self:SetHealth(0)
		
		--self.ItemID = -4
		
		if self.UseDelay == nil then self.UseDelay = 0 end --error-proofing
		
		--RARITIES--
		--1 - common
		--2 - uncommon
		--3 - rare
		--4 - epic
		--5 - legendary
		--6 - mythic
		--7 - wondrous
		--8 - infinite
		--9 - omega
		--10 - ALPHAOMEGA
		--11 - special
		
		--self.Health64 is used to define the item quantity, but the code of the item for when its effect is activated must support the quantity or else this variable is useless
		--run self.Health64 = 1 in the item's initialisation code if you don't want it to have a quantity assigned to it
		--self.PickupName is the item's ingame name. the name will appear as [UNDEFINED NAME] if you don't define it in the item's initialisation code.
		
		self.NoMerge = true
		
		--ITEM INITIALISATION
		--the code with the matching ItemID will be run when the item spawns
		if self.ItemID == 0 then
			if !self.Qty then self.Qty = {1, 0} end
			self.ModelPath = "models/items/currencypack_medium.mdl"
			self.soundfile = "mvm/mvm_money_pickup.wav"
			self.PickupName = bignumwrite(self.Qty) .. " Gold"
			self.Rare = 1
			self.NoPhysics = true
			self.Desc = "Those who control Gold will control the world."
			self.func = function(ent)
				for k, v in pairs(player.GetAll()) do
					v:GainGold(self.Qty)
				end
			end
		elseif self.ItemID == 1 then
			if !self.Qty then self.Qty = {1, 0} end
			if bignumcompare(self.Qty, {100,0}) == 1 then
				self.ModelPath = "models/hunter/blocks/cube1x1x1.mdl"
				self.PickupName = "100 Time Cubes"
			else
				self.ModelPath = "models/hunter/blocks/cube05x05x05.mdl"
				self.PickupName = "Time Cube"
			end
			self:SetMaterial("effects/australium_sapphire")
			self:EmitSound("rf/discovery.wav", 115)
			self.soundfile = "rf/acquire.wav"
			self.UseDelay = 4 + math.Rand(0,6)
			self.Rare = 5
			self.SilentCollect = true
			self.Desc = "Time paradoxes could occur."
		elseif self.ItemID == 2 then
			if !self.Qty then self.Qty = {1, 0} end
			if bignumcompare(self.Qty, {99,0}) == 1 then
				self.ModelPath = "models/hunter/blocks/cube1x1x1.mdl"
				self.PickupName = "100 Weapon Cubes"
			else
				self.ModelPath = "models/hunter/blocks/cube05x05x05.mdl"
				self.PickupName = "Weapon Cube"
			end
			self:SetMaterial("effects/australium_emerald")
			self:EmitSound("rf/discovery.wav", 115)
			self.soundfile = "rf/acquire.wav"
			self.UseDelay = 4 + math.Rand(0,6)
			self.Rare = 6
			self.SilentCollect = true
			self.Desc = "Even simple six-sided geometry poses a deadly threat to your foes."
		elseif self.ItemID == 3 then
			self.Qty = {1, 0}
			self.ModelPath = "models/items/ammopack_small.mdl"
			self.soundfile = "items/gunpickup2.wav"
			self.PickupName = "Ammo"
			self.Rare = 2
			self.NoPhysics = true
			self.Desc = "Supplies all weapons with ammo."
			self.func = function(ent)
				for k, w in pairs(ent:GetWeapons()) do
					ent:GiveAmmo(w:GetMaxClip1() * 3, w:GetPrimaryAmmoType())
				end
			end
		elseif self.ItemID == 4 then
			self.Qty = {1, 0}
			self.ModelPath = "models/props_halloween/halloween_medkit_small.mdl"
			self.soundfile = "rf/acquire.wav"
			self.sndpitch = 80
			self.PickupName = "Health"
			self.Rare = 2
			self.NoPhysics = true
			self.Desc = "Tasty chocolate."
			self.func = function(ent)
				ent.RegenerationTime = ent.RegenerationTime + 2
			end
		elseif self.ItemID == -1 then
			self.Qty = {1, 0}
			self.ModelPath = "models/items/medkit_large.mdl"
			self:EmitSound("rf/discovery.wav", 115)
			self:SetColor(Color(0,0,255))
			self.soundfile = "rf/acquire.wav"
			self.UseDelay = 6
			self.PickupName = "Pulse"
			self.Rare = 4
			self.NoPhysics = true
			self.Desc = "A true death-cheater indeed."
		elseif self.ItemID == -2 then
			ParticleEffectAttach( "merasmus_spawn", 1, self, 2 )
			self.Qty = {1, 0}
			self.ModelPath = "models/props_td/atom_bomb.mdl"
			self:EmitSound("rf/discovery.wav", 115)
			self:SetColor(Color(127,0,255))
			self.soundfile = "rf/acquire.wav"
			self.PickupName = "Zone Bomb"
			self.Rare = 6
			self.NoPhysics = true
			self.Desc = "Claim your victory and move onto the next zone."
			self.func = function(ent)
				ParticleEffect("asplode_hoodoo", ent:GetPos(), Angle(0,0,0))
				CompleteZone()
			end
		else
			self:Remove()
		end
		
		if self.NoModel then self.ModelPath = "models/hunter/blocks/cube025x025x025.mdl" end
		
		if self.sndpitch == nil then self.sndpitch = 100 end --error-proofing

		--leave these be
		if self.NoPhysics then
			self:SetModel("models/hunter/blocks/cube025x025x025.mdl")
		else
			self:SetModel(self.ModelPath)
		end
		local materialapplication = self:GetMaterial()
		self:SetMaterial("null")
		self:SetUseType( SIMPLE_USE )
		self:SetTrigger(true)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetRenderMode(RENDERMODE_TRANSALPHA)
		self:SetCollisionGroup(COLLISION_GROUP_WORLD)
		if !self.NoModel then
			if self.VisualStack then
				for i = 1, self.Health64 do
					local displaymodel = ents.Create("prop_dynamic")
					displaymodel:SetModel(self.ModelPath)
					if i != 1 then
						displaymodel:SetParent(self:GetChildren()[1])
					else
						displaymodel:SetParent(self)
					end
					displaymodel:SetRenderMode(RENDERMODE_TRANSALPHA)
					displaymodel:SetModelScale(self:GetModelScale())
					displaymodel:SetColor(self:GetColor())
					displaymodel:SetMaterial(materialapplication)
					displaymodel:SetPos(self:GetPos() + Vector((i-1)*2,(i-1)*2,(i-1)*2))
					displaymodel:SetAngles(self:GetAngles())
					if displaymodel.SetSkin && self.SkinMod then
						displaymodel:SetSkin(self.SkinMod)
					end
					displaymodel.Indestructible = 1
					displaymodel.IsDebris = 1
					displaymodel.SubmergeBroken = true
					displaymodel:Spawn()
				end
			else
				local displaymodel = ents.Create("prop_dynamic")
				displaymodel:SetModel(self.ModelPath)
				displaymodel:SetParent(self)
				displaymodel:SetRenderMode(RENDERMODE_TRANSALPHA)
				displaymodel:SetModelScale(self:GetModelScale())
				displaymodel:SetColor(self:GetColor())
				displaymodel:SetMaterial(materialapplication)
				displaymodel:SetPos(self:GetPos())
				displaymodel:SetAngles(self:GetAngles())
				displaymodel.Indestructible = 1
				displaymodel.IsDebris = 1
				displaymodel.SubmergeBroken = true
				displaymodel:Spawn()
			end
		end
		self:SetUseType( SIMPLE_USE )
		self:SetTrigger(true)
		self:PrecacheGibs()
		self:DrawShadow(false)
		--/leave these be
		
		self.BeginUse = true
		timer.Simple(0.01, function() if IsValid(self) then self.BeginUse = nil end end) --for insta-give pickups
	
		self.PickedUp = 0 --if you change this you're fucking retarded o_o

		if self.Master then
				ParticleEffectAttach( "mr_portal_exit", 1, self, 2 )
				ParticleEffectAttach( "mr_portal_entrance", 1, self, 2 )
				ParticleEffectAttach( "mr_b_fx_1_core", 1, self, 2 )
				for i = 1, 8 do
				timer.Simple(i/10, function() if IsValid(self) then
				self:EmitSound("rf/super_evolve.mp3",95,50)
								local beacon = ents.Create( "prop_dynamic" )
									beacon:SetModel("models/worms/telepadsinglering.mdl")
									beacon:SetMaterial("pac/default")
									beacon.IsDebris = 1
									beacon:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
									beacon:SetPos(self:GetPos())
									beacon:SetColor(Color(math.random(0,255),math.random(0,255),math.random(0,255)))
									beacon:SetModelScale(0.001, 0)
									beacon:SetModelScale(90, 2)
									timer.Simple(2, function() if IsValid(beacon) then
										for c = 1, 100 do
											timer.Simple(c/100, function() if IsValid(beacon) then
												beacon:SetPos(beacon:GetPos() + Vector(0,0,1))
											end end)
										end
										beacon:SetModelScale(0.001, 1)
									end end)
									timer.Simple(3, function() if IsValid(beacon) then beacon:Remove() end end)
								beacon:Spawn()
				end end)
				end
		elseif self.Infinite then
		self.NeverRemove = true
			ParticleEffectAttach( "mr_b_fx_1_core", 1, self, 2 )
			if !self.SilentInfinite then
				self:EmitSound("rf/infinity.wav", 95)
			end
		elseif self.SemiWondrous then
		self.NeverRemove = true
			ParticleEffectAttach( "mr_effect_03_overflow", 1, self, 2 )
		elseif self.Wondrous then
		self.NeverRemove = true
			ParticleEffectAttach( "mr_portal_entrance", 1, self, 2 )
		end
		timer.Simple(0, function() if IsValid(self) then
			if IsValid(self:GetPhysicsObject()) then
				local phys = self:GetPhysicsObject()
				phys:AddVelocity(Vector(math.random(-50,50),math.random(-50,50),300))
				phys:AddAngleVelocity(Vector(math.random(-1080,1080),math.random(-1080,1080),math.random(-1080,1080)))
			end
		end end)
	
	self.ArchivePos = self:GetPos()
	end
end

if ( CLIENT ) then

	function ENT:Draw()
		self:DrawModel()
	end
	
end

function ENT:PhysicsCollide( data, physobj )
	if (data.Speed > 1 && data.DeltaTime > 0.2 ) then
		if !self.SilentCollect then
			self:EmitSound( "rf/itemimpact.wav", 75, 100 )
		end
		self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	end
end

function ENT:StartTouch(ply)
	if ply:IsPlayer() && self.PickedUp == 0 && self.ItemID != -2 then
		self:Use(ply,ply,3,1)
	end
end

function ENT:OnRemove()
	if self.ShineSnd then
		if self.ShineSnd:IsPlaying() then self.ShineSnd:Stop() end
	end
	if IsValid(self) then
		if self.VisualRemove then
			if !self.Descending and self.VisualStack then
				for i = 1, self.Health64 do
									local debris = ents.Create("base_gmodentity")
									timer.Simple(5, function() if IsValid(debris) then debris:Remove() end end)
									debris.Indestructible = 1
									debris:SetPos(self:GetPos() + Vector((i-1)*2,(i-1)*2,(i-1)*2))
									debris:SetModel(self.VisualRemoveModel)
									debris:SetMaterial(self.VisualRemoveMaterial)
									debris:SetModelScale(self.VisualRemoveModelScale)
									debris:SetRenderMode(RENDERMODE_TRANSALPHA)
									debris:SetColor(Color(self:GetColor().r, self:GetColor().g, self:GetColor().b, 103))
									debris:PhysicsInit(SOLID_VPHYSICS)
									debris:SetAngles(self:GetAngles())
									debris:Spawn()
									debris:SetSolid(SOLID_VPHYSICS)
									debris:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
									timer.Simple(0, function()
									if IsValid(debris:GetPhysicsObject()) then
										debris:GetPhysicsObject():SetVelocity(Vector(math.random(-200,200),math.random(-200,200),math.random(100,700)))
										debris:GetPhysicsObject():AddAngleVelocity(Vector(math.random(-400,400),math.random(-400,400),math.random(-400,400)))
									end
									end)
				end
			else
									local debris = ents.Create("base_gmodentity")
									timer.Simple(5, function() if IsValid(debris) then debris:Remove() end end)
									debris.Indestructible = 1
									debris:SetPos(self:GetPos())
									debris:SetModel(self.VisualRemoveModel)
									debris:SetMaterial(self.VisualRemoveMaterial)
									debris:SetRenderMode(RENDERMODE_TRANSALPHA)
									debris:SetColor(Color(self:GetColor().r, self:GetColor().g, self:GetColor().b, 103))
									debris:PhysicsInit(SOLID_VPHYSICS)
									debris:SetAngles(self:GetAngles())
									debris:Spawn()
									debris:SetSolid(SOLID_VPHYSICS)
									debris:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
									timer.Simple(0, function()
									if IsValid(debris:GetPhysicsObject()) then
										debris:GetPhysicsObject():SetVelocity(Vector(math.random(-200,200),math.random(-200,200),math.random(100,700)))
										debris:GetPhysicsObject():AddAngleVelocity(Vector(math.random(-400,400),math.random(-400,400),math.random(-400,400)))
									end
									end)
			end
		end
	end
end

function ENT:OnTakeDamage( dmginfo )
end

function ENT:DropCrystalRewards()
	if self.SubID then
		if self.SubID == 25 or self.SubID == 26 or self.SubID == 27 then
			SpawnHeroRandom(self:GetPos() + self:OBBCenter(), self.SubID-17)
		end
		if self.SubID == 24 then
			local rnjesus = math.random(1,5)
			if rnjesus == 1 then
				local gold = ents.Create("ses_pickup")
				gold:SetPos(self:GetPos() + self:OBBCenter())
				gold.ItemID = -14
				gold.SubID = 1
				gold.Health64 = math.random(10)*500
				gold:Spawn()
			elseif rnjesus == 2 then
				local gold = ents.Create("ses_pickup")
				gold:SetPos(self:GetPos() + self:OBBCenter())
				gold.ItemID = -14
				gold.SubID = 2
				gold.Health64 = math.random(10)
				gold:Spawn()
			elseif rnjesus == 3 then
				local gold = ents.Create("ses_pickup")
				gold:SetPos(self:GetPos() + self:OBBCenter())
				gold.ItemID = -9
				gold.SubID = table.Random({2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,4,4,5})
				gold:Spawn()
			else
				local gold = ents.Create("ses_pickup")
				gold:SetPos(self:GetPos() + self:OBBCenter())
				gold.ItemID = -10
				gold:Spawn()
			end
		end
		if self.SubID == 11 then
						for i = 1, 10 do
							local gold = ents.Create("ses_pickup")
							gold:SetPos(self:GetPos() + self:OBBCenter())
							gold.ItemID = -6
							gold:Spawn()
						end
		end
		if self.SubID == 12 then
			for i = 1, 3 + math.max(0,math.random(-6,2)) do
				local lewt = ents.Create("ses_pickup")
				lewt:SetPos(self:GetPos() + self:OBBCenter())
				lewt.ItemID = 51
				lewt:Spawn()
			end
		end
		if self.SubID >= 1 && self.SubID <= 7 then
			SpawnHeroRandom(self:GetPos() + self:OBBCenter(), self.SubID)
		end
		if self.SubID == 16 then
			for i = 1, 5 do
				SpawnHeroRandom(self:GetPos() + self:OBBCenter(), table.Random({1,1,1,1,1,2,2,3}))
			end
		end
		if self.SubID == 17 then
			for i = 1, math.random(2,6) do
				local lewt = ents.Create("ses_pickup")
				lewt:SetPos(self:GetPos() + self:OBBCenter())
				lewt.ItemID = -13
				lewt:Spawn()
			end
		end
		if self.SubID == 18 then
			for i = 1, math.random(4,6) do
				local lewt = ents.Create("ses_pickup")
				lewt:SetPos(self:GetPos() + self:OBBCenter())
				lewt.ItemID = -11
				lewt:Spawn()
			end
		end
		if self.SubID == 19 then
			for i = 1, math.random(6,14) do
				local lewt = ents.Create("ses_pickup")
				lewt:SetPos(self:GetPos() + self:OBBCenter())
				lewt.ItemID = -12
				lewt:Spawn()
			end
		end
		if self.SubID == 20 then
			for i = 1, math.random(12,25) do
				local lewt = ents.Create("ses_pickup")
				lewt:SetPos(self:GetPos() + self:OBBCenter())
				lewt.ItemID = -math.random(12,13)
				lewt:Spawn()
			end
		end
		if self.SubID == 23 then
				local lewt = ents.Create("ses_pickup")
				lewt:SetPos(self:GetPos() + self:OBBCenter())
				lewt.ItemID = -10
				lewt.SubID = 14
				lewt:Spawn()
		end
		if self.SubID == 25 then
			for i = 1, math.random(12,25) do
				local lewt = ents.Create("ses_pickup")
				lewt:SetPos(self:GetPos() + self:OBBCenter())
				lewt.ItemID = -math.random(12,13)
				lewt:Spawn()
			end
		end
		if self.SubID == 21 then
			for i = 1, 10 do
				SpawnHeroRandom(self:GetPos() + self:OBBCenter(), math.random(1,6))
			end
		end
		if self.SubID == 22 then
			for i = 1, 15 do
				SpawnHeroRandom(self:GetPos() + self:OBBCenter(), 6)
			end
		end
		if self.SubID == 15 then
			local lewt = ents.Create("ses_pickup")
			lewt:SetPos(self:GetPos() + self:OBBCenter())
			lewt.ItemID = -10
			lewt:Spawn()
			if math.random(1,20) == 1 then
				local lewt = ents.Create("ses_pickup")
				lewt:SetPos(self:GetPos() + self:OBBCenter())
				lewt.ItemID = -10
				lewt:Spawn()
			end
			if math.random(1,40) == 1 then
				local lewt = ents.Create("ses_pickup")
				lewt:SetPos(self:GetPos() + self:OBBCenter())
				lewt.ItemID = -10
				lewt:Spawn()
			end
			for i = 1, math.random(2,6) do
				local lewt = ents.Create("ses_pickup")
				lewt:SetPos(self:GetPos() + self:OBBCenter())
				lewt.ItemID = -12
				lewt:Spawn()
			end
		end
		if self.SubID == 14 then
				SpawnHeroRandom(self:GetPos() + self:OBBCenter(), table.Random({2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,4}))
		end
		if self.SubID == 8 then
			if math.random(1,2) == 1 then
				local lewt = ents.Create("ses_pickup")
				lewt:SetPos(self:GetPos() + self:OBBCenter())
				lewt.ItemID = 51
				lewt:Spawn()
			end
			local lewt = ents.Create("ses_pickup")
			lewt:SetPos(self:GetPos() + self:OBBCenter())
			lewt.ItemID = -11
			lewt:Spawn()
			if math.random(1,4) == 1 then
				local lewt = ents.Create("ses_pickup")
				lewt:SetPos(self:GetPos() + self:OBBCenter())
				lewt.ItemID = -13
				lewt:Spawn()
			end
			if math.random(1,2) == 1 then
				local lewt = ents.Create("ses_pickup")
				lewt:SetPos(self:GetPos() + self:OBBCenter())
				lewt.ItemID = -12
				lewt:Spawn()
			end
			if math.random(1,24) == 1 then
				local lewt = ents.Create("ses_pickup")
				lewt:SetPos(self:GetPos() + self:OBBCenter())
				lewt.ItemID = -10
				lewt.SubID = math.random(1,13)
				lewt:Spawn()
			end
		end
		if self.SubID == 9 then
				local lewt = ents.Create("ses_pickup")
				lewt:SetPos(self:GetPos() + self:OBBCenter())
				lewt.ItemID = 51
				lewt:Spawn()
		end
	end
end

function ENT:ActivateEffect( ply ) --DON'T CALL THIS FUNCTION OUTSIDE OF ENT:Use PLEASE (you really shouldn't be calling it yourself anyway)
		local raritycolours = {Color(255,255,255), Color(0,255,0), Color(0,133,255), Color(127,0,255),Color(255,135,0),Color(0,255,255),Color(255,0,0),Color(0,0,255),Color(255,133,133),Color(0,0,0),Color(255,0,255)}
		--if self.Important then
		--	Announce(ply:Nick() .. " got " .. self.PickupName .. " [x" .. string.Comma(self.Health64) .. "]", raritycolours[math.min(math.max(1,self.Rare),#raritycolours) or 1], Color(64,64,64), 1.2)
		--end
		if !self.SilentCollect then
			SendPopoff(self.PickupName, ply,Color(0,0,0),raritycolours[math.min(math.max(1,self.Rare),#raritycolours) or 1])
		end
		if self.func then self.func(ply) end
end

if SERVER then
--do not touch ENT:Think() at all, even if you are confident. unless if you exactly know what you're doing and know the effect it will produce.
function ENT:Think()
	if IsValid(self:GetChildren()[1]) && self.NoPhysics then
		local child = self:GetChildren()[1]
		child:SetAngles(Angle(0,CurTime()*50,0))
	end
	if self.Rare then
		if self.Rare == 9 && self.ItemID != -3 then
			if !self.ShineSnd then self.ShineSnd = CreateSound(self,"rf/loot_ambient.wav") end
			if self.PickedUp == 0 then self.ShineSnd:Play() elseif self.ShineSnd:IsPlaying() then self.ShineSnd:Stop() end
		end
		if self.Rare == 10 && self.ItemID != -3 then
			if !self.ShineSnd then self.ShineSnd = CreateSound(self,"rf/loot_ambient.wav") end
			if self.PickedUp == 0 then self.ShineSnd:Play() self.ShineSnd:ChangePitch(50) elseif self.ShineSnd:IsPlaying() then self.ShineSnd:Stop() end
		end
	end
	if self.ItemID == 14 then
		if IsValid(self:GetParent()) then
			if string.find(self:GetParent():GetClass(), "npc_") then
				if !self:GetParent().NPCLives then self:GetParent().NPCLives = 0 end
				self:GetParent().NPCLives = self:GetParent().NPCLives + self.Health64
				self:GetParent():EmitSound("rf/evolve_v2.mp3")
				self:Remove()
			end
		end
	end
	if self.IsCrystal then
		self:SetMaxHealth(self.Health64 or 1)
			if self.Health64 > 50 && self.SubID == 24 then
				local quota = self.Health64 - 50
				local refund = ents.Create("ses_pickup")
				refund.ItemID = -14
				refund.SubID = 3
				refund.Health64 = math.floor((2000*quota)/(GetPlus()+1))
				refund:SetPos(self:GetPos())
				refund:Spawn()
				self.Health64 = 50
			end
	end
	if !self.ArchivePos then self.ArchivePos = self:GetPos() end
	if !util.IsInWorld(self.ArchivePos) && self.PickedUp != 1 then self:Remove() end --if we somehow first spawned outside the world
	if self.PickedUp == 0 then
	if (GetConVar("craftworld3_pickups"):GetInt() or 1) == 0 then self:Remove() end
	for k, hurt in pairs(ents.FindInSphere(self:GetPos(),1)) do
		if hurt:GetClass() == "trigger_hurt" && self.PickedUp != 1 then
			if !self.Retries then self.Retries = 0 end
			self:SetPos(self.ArchivePos)
			self:EmitSound("rf/discharge.wav")
			self.Retries = self.Retries + 1
			ParticleEffect("teleportedin_red", self:GetPos(), Angle(0,0,0))
			ParticleEffect("teleported_red", self:GetPos(), Angle(0,0,0))
			self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
			if self.Retries > 10 then --still in water even after teleportation/teleported 10 times?
				self:Remove()
			end
		end
	end
	if !self.Retries then self.Retries = 0 end
	if self:WaterLevel() > 0 && self.PickedUp != 1 then
		if !self.Retries then self.Retries = 0 end
		self:SetPos(self.ArchivePos)
		self:EmitSound("rf/discharge.wav")
		self.Retries = self.Retries + 1
		ParticleEffect("teleportedin_red", self:GetPos(), Angle(0,0,0))
		ParticleEffect("teleported_red", self:GetPos(), Angle(0,0,0))
		self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		if self:WaterLevel() > 0 or self.Retries > 10 then --still in water even after teleportation/teleported 10 times?
			self:Remove()
		end
	end
	if self:GetModel() != "models/props_junk/wood_crate001a.mdl" then
		self:SetNWString("pickname", self.PickupName or "?")
		self:SetNWString("pickdesc", self.Desc or "")
		self:SetNWInt("pickamount", 1)
		self:SetNWInt("pickrarity", self.Rare or 1)
		self:SetNWString("itemowner", self.ItemOwner or "unassigned")
	end
	end
	self:RemoveAllDecals()
	self:NextThink( CurTime() )
	return true
end
end

function ENT:Use( ply, caller ) --don't touch this function unless if you know what you are doing *eyeroll*
	if self.GivesItemIfNotGot then
		if ply:HasWeapon(self.GivesItem) then
			ply:PrintMessage(HUD_PRINTCENTER, "You can't stack this item.")
			return
		end
	end
	if ply.CarryingCrystal && self.IsCrystal then
		if self.SubID != ply.CarryingCrystal.SubID then
			ply:PrintMessage(HUD_PRINTCENTER, "You may only stack crystals of the same type.")
			return
		end
	end
	if self.PickedUp == 0 then
	if self.keyrequired then
		if ply:HasKey(self.keyrequired) then
			ply:TakeKey(self.keyrequired)
			self.keyrequired = nil
		else
			Announce("[ x ] You do not have any suitable key that this item requires.", Color(127,127,127), Color(0,0,0), 1, ply)
			return
		end
	end
	if self.DontAnimate then self.Immediate = true end
	if ply:IsPlayer() && caller:IsPlayer() then
	if self.Medical && ply.Health64 >= ply.MaxHealth64 && ply.Armour64 >= ply.MaxHealth64 then
		Announce("[ x ] Your health and armour are both full.", Color(127,127,127), Color(0,0,0), 1, ply)
		return
	end
	if (self.ItemOwner == "unassigned" or self.ItemOwner == ply:SteamID()) && !self.DisallowUse then
		if !self.BeginUse then
			self.DisallowUse = true
			local dupes = {}
			if !self.NoMerge then
				for k, v in pairs(ents.FindInSphere(self:GetPos(), 155)) do
					if v != self then
						if v.ItemID == self.ItemID && v.PickedUp != 1 && !v.BusyMerging then
							table.insert(dupes, v)
						end
					end
				end
			end
			if #dupes > 0 then
				self.BusyMerging = true
				local phys = self:GetPhysicsObject()
				for k, v in pairs(dupes) do
					if v.Rare > self.Rare then self.Rare = v.Rare end
					self.Health64 = self.Health64 + v.Health64
					v.DisallowUse = true
					v.PickedUp = 1
					if v.OneAtATime then
						if v.soundfile then
							v:EmitSound(v.soundfile, 72, v.sndpitch)
						end
					else
						local soundtomake = self.soundfile or "NOSOUND"
						local pitchtomake = self.sndpitch
						for i = 1, #dupes do
							timer.Simple(i/10, function() if IsValid(ply) then
								if soundtomake != "NOSOUND" then
									ply:EmitSound(soundtomake, 75, pitchtomake)
								end
							end end)
						end
					end
					v:SetMoveType(MOVETYPE_NONE)
					v:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
					for i = 1, 26 do
						timer.Simple(i/30, function() if IsValid(v) && IsValid(self) then
							if i == 26 then
								v:Remove()
							else
								local sourceangle = v:GetAngles()/25
								local targetangle = self:GetAngles()/25
								local sourceposition = v:GetPos()/25
								local targetposition = self:GetPos()/25
								local anglemath = (sourceangle*(25-i)) + (targetangle*i)
								local positionmath = (sourceposition*(25-i)) + (targetposition*i)
								v:SetPos(positionmath)
								v:SetAngles(anglemath)
							end
						elseif IsValid(v) then
							v:Remove()
						end end)
					end
				end
				self.DisallowUse = nil
				self.BusyMerging = nil
				self.NoMerge = true
				self.NoMerge_Toggle = true
				self:Use(ply,ply,3,1)
			elseif self.OneAtATime && self.Health64 > 1 then
				local onesie = ents.Create("ses_pickup")
				onesie.ItemID = self.ItemID
				onesie.ItemOwner = ply:SteamID()
				onesie:SetPos(self:GetPos())
				onesie:SetAngles(self:GetAngles())
				onesie.Health64 = 1
				onesie.NoMerge = true
				onesie.SkipUnbox = true
				onesie:Spawn()
				timer.Simple(0, function() if IsValid(onesie) && IsValid(ply) then if IsValid(self) then onesie.Rare = self.Rare end onesie:Use(ply,ply,3,1) end end)
				self.Health64 = self.Health64 - 1
				self.DisallowUse = nil
			else
				self.BeginUse = true
				self.DisallowUse = nil
				timer.Simple(0, function() if IsValid(self) && IsValid(ply) then self:Use(ply,ply,3,1) end end)
			end
			if self.NoMerge_Toggle then
				self.NoMerge_Toggle = nil
				self.NoMerge = nil
			end
		else
			self.PickedUp = 1
			if self.Descending then self.Immediate = false end --not compatible with Immediate trait
			self:SetCollisionGroup(COLLISION_GROUP_WORLD)
			local RandomX = math.Rand(-15,15)
			local RandomY = math.Rand(-15,15)
			local RandomZ = math.Rand(10,30)
			self.RandomVector = Vector( RandomX, RandomY, RandomZ )
			if !self.speedmult then self.speedmult = 1 end
			if !self.speedmultoffset then self.speedmultoffset = 0 end
			local speed = self.speedmult + self.speedmultoffset
			if ply.classed == "beserker" && !self.Immedate then speed = speed*2 end
			if ply.Dexterity && !self.Immediate then speed = speed/3 end
			if self.Rare == 10 then
				ply:EmitSound("rf/omega.wav", 85, 50)
				ply:EmitSound("rf/omega.wav", 85, 50)
				ply:EmitSound("rf/super_evolve.mp3", 85, 100)
			elseif self.Rare == 9 then
				ply:EmitSound("rf/omega.wav", 85, 100)
			elseif self.Rare == 8 or self.Rare == 7 then
				ply:EmitSound("rf/rareitem.wav", 85, 100)
			end
			if self.Immediate or self.RemoveOnUse then
				self:ActivateEffect(ply)
					if self.RemoveOnUse then
						if self.BreakEffect then
							local soundtable = { "rf/armor/woodbreak" .. math.random(1,3) .. ".wav", "rf/armor/plasticbreak" .. math.random(1,4) .. ".wav", "rf/armor/woodbreak" .. math.random(1,3) .. ".wav", "rf/armor/metalbreak" .. math.random(1,5) .. ".wav" }
							if IsValid(ply) then ply:EmitSound(soundtable[self.BreakEffect]) end
							DynamicEffect(self:GetPos(), self.BreakEffect)
						end
					end
			end
			if self.RemoveOnUse then self:Remove() else
			timer.Simple(self.UseDelay, function() if IsValid(self) then
			--speed = 5
			if self.soundfile && !self.nosnd then
				if self.VisualStack && !self.Descending then
					local archivesnd = self.soundfile
					local archivepitch = self.sndpitch
					for s = 1, self.Health64 do
						timer.Simple((s-1)/20, function() if IsValid(ply) then
							ply:EmitSound(archivesnd, 75, archivepitch)
						end end)
					end
				else
					ply:EmitSound(self.soundfile, 75, self.sndpitch)
				end
			end
			self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
			self:SetMoveType(MOVETYPE_NONE)
			self:SetModelScale(1, speed/10)
			if IsValid(self:GetPhysicsObject()) then self:GetPhysicsObject():EnableMotion(false) end
			local pos = self:GetPos()/(20*speed)
			local ang = self:GetAngles()/(20*speed)
			for i=1,130*speed do
				timer.Simple(i/100, function()
					if IsValid(self) then
						local headpos
						local headbone = "ValveBiped.Bip01_Head1"
						if ply:GetBonePosition(ply:LookupBone(headbone)) then
							headpos = ply:GetBonePosition(ply:LookupBone(headbone)) + Vector(0,0,15) + self.RandomVector
						else
							headpos = Vector(0,0,25+ply:OBBMaxs()) + self.RandomVector
						end
						local calcpos = (pos*((20*speed) - i)) + ((headpos/(20*speed))*i)
						if i >= 110*speed && !self.JustResized then
							self:SetModelScale(0.01,speed/5)
							self.JustResized = true
							--if IsValid(self:GetChildren()[1]) then
								--self:GetChildren()[1]:SetModelScale(0.01,speed/5)
								--local subject = self:GetChildren()[1]:GetChildren()
								--for c = 1, #subject do
									--subject[c]:SetModelScale(0.01,speed/5)
								--end
							--end
						end
						if i <= 20*speed then
							self:SetPos(calcpos)
							self:SetAngles(self:GetAngles() - ang)
						elseif i >= 110*speed then
							self:SetPos((ply:GetBonePosition(ply:LookupBone(headbone))*(1-self:GetModelScale())) + (headpos*self:GetModelScale()))
						else
							self:SetPos(headpos)
							self:SetAngles(Angle(0,0,0))
						end
					end
				end)
			end
			timer.Simple(((130*speed)/100) + 0.1, function() if IsValid(self) then
							if !self.Immediate then if IsValid(ply) then self:ActivateEffect(ply) end end
							if self.PFX then
								ParticleEffect(self.PFX, self:GetPos(), Angle(0,0,0))
							end
							if self.BreakEffect then
								local soundtable = { "rf/armor/woodbreak" .. math.random(1,3) .. ".wav", "rf/armor/plasticbreak" .. math.random(1,4) .. ".wav", "rf/armor/woodbreak" .. math.random(1,3) .. ".wav", "rf/armor/metalbreak" .. math.random(1,5) .. ".wav" }
								if IsValid(ply) then ply:EmitSound(soundtable[self.BreakEffect]) end
								DynamicEffect(self:GetPos(), self.BreakEffect)
							end
							if !self.IsCrystal then self:Remove() end
			end end)
			end end)
			end
		end
	elseif !self.DisallowUse then
		ply:PrintMessage(HUD_PRINTCENTER, "Please wait for this item to become available (wait for the '!' mark to appear).")
	end
	end
end
end