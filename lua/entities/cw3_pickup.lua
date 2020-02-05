AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )


ENT.PrintName		= "Pickup"
ENT.Author			= "Jen Walter"
ENT.Information		= "Item drop from CRAFTWORLD3."
ENT.Category		= "CRAFTWORLD3"

ENT.Editable			= false
ENT.Spawnable			= true
ENT.AdminOnly			= true
ENT.RenderGroup 		= RENDERGROUP_TRANSLUCENT

list.Set( "SENT", "Pickup", {
	Name = "Pickup", 
	Class = "cw3_pickup", 
	Category = "CRAFTWORLD3"
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
function ENT:Initialize()

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

		self.NoMerge = true
		
		--ITEM INITIALISATION
		--the code with the matching ItemID will be run when the item spawns
		if not self.CustomItem then
			if self.ItemID == 0 then
				if !self.Qty then self.Qty = {1, 0} end
				self.ModelPath = "models/tiggorech/borderlands/pickups/cash/cash_pickup.mdl"
				self.soundfile = "mvm/mvm_money_pickup.wav"
				self.PickupName = "$" .. bignumwrite(self.Qty)
				self.Rare = 1
				self:SetModelScale(1.35)
				self.NoImpactNoise = true
				self.SilentCollect = true
				self.Desc = "Money money money!"
				self.func = function(ent)
					if !ent.DoshWait then ent.DoshWait = 0 end
					if math.random(1,10) == 1 && ent.DoshWait < CurTime() then
						ent:EmitSound("rf/dosh_collect" .. math.random(2) .. ".wav")
						ent.DoshWait = CurTime() + 3
					end
					if TrueCraftling() && !self.IgnoreTrueCraftling then
						ent:GainGold(self.Qty)
					else
						for k, v in pairs(player.GetAll()) do
							v:GainGold(self.Qty)
						end
					end
				end
			elseif self.ItemID == 1 then
				if !self.Qty then self.Qty = {1, 0} end
				if bignumcompare(self.Qty, {99,0}) == 1 then
					self.ModelPath = "models/hunter/blocks/cube1x1x1.mdl"
					self.PickupName = "Mega gCube"
				else
					self.ModelPath = "models/hunter/blocks/cube05x05x05.mdl"
					self.PickupName = "gCube"
				end
				self:SetMaterial("effects/australium_sapphire")
				self:EmitSound("rf/discovery.wav", 115)
				self.soundfile = "rf/rareitem.wav"
				self.UseDelay = 3 + math.Rand(0,2)
				self.Rare = 5
				self.SilentCollect = true
				self.Desc = "The letter 'g' symbolises the initial letter of a very formidable individual."
			elseif self.ItemID == 2 then
				if !self.Qty then self.Qty = {1, 0} end
				if bignumcompare(self.Qty, {99,0}) == 1 then
					self.ModelPath = "models/hunter/blocks/cube1x1x1.mdl"
					self.PickupName = "Mega cCube"
				else
					self.ModelPath = "models/hunter/blocks/cube05x05x05.mdl"
					self.PickupName = "cCube"
				end
				self:SetMaterial("effects/australium_emerald")
				self:EmitSound("rf/discovery.wav", 115)
				self.soundfile = "rf/rareitem.wav"
				self.UseDelay = 3 + math.Rand(0,2)
				self.Rare = 6
				self.SilentCollect = true
				self.Desc = "The letter 'c' symbolises this very world itself."
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
						if w:GetMaxClip1() <= 1 then
							ent:GiveAmmo(15, w:GetPrimaryAmmoType())
						else
							ent:GiveAmmo(w:GetMaxClip1() * 5, w:GetPrimaryAmmoType())
						end
					end
				end
			elseif self.ItemID == 4 then
				self.Qty = {1, 0}
				self.ModelPath = "models/props_halloween/halloween_medkit_small.mdl"
				self.soundfile = "rf/acquire.wav"
				self.sndpitch = 80
				self.PickupName = "2s Health Regen"
				self.Rare = 2
				self.NoPhysics = true
				self.Desc = "Tasty chocolate."
				self.func = function(ent)
					ent.RegenerationTime = ent.RegenerationTime + 2
				end
			elseif self.ItemID == 5 then
				if !self.Qty then self.Qty = {1, 0} end
				self.ModelPath = "models/props_halloween/halloween_gift.mdl"
				self:SetMaterial("effects/australium_sapphire")
				self.soundfile = "ui/item_gift_wrap_unwrap.wav"
				self.NoImpactNoise = true
				self.NoAutoPickup = true
				self.ZoneClearPickupImmunity = true
				self.PickupName = bignumwrite(self.Qty) .. " Unclaimed gCubes"
				self.Rare = 5
				self.Desc = "Drops if a cube NPC dies to something other than a player's wrath."
				self.func = function(ent)
					ent:GiveCubes(1, self.Qty, self:GetPos())
				end
			elseif self.ItemID == 6 then
				if !self.Qty then self.Qty = {1, 0} end
				self.ModelPath = "models/props_halloween/halloween_gift.mdl"
				self:SetMaterial("effects/australium_emerald")
				self.soundfile = "ui/item_gift_wrap_unwrap.wav"
				self.NoImpactNoise = true
				self.NoAutoPickup = true
				self.ZoneClearPickupImmunity = true
				self.PickupName = bignumwrite(self.Qty) .. " Unclaimed cCubes"
				self.Rare = 5
				self.Desc = "Drops if a cube NPC dies to something other than a player's wrath."
				self.func = function(ent)
					ent:GiveCubes(2, self.Qty, self:GetPos())
				end
			elseif self.ItemID == 7 then
				if !self.Qty then self.Qty = {1, 0} end
				self.ModelPath = "models/props_halloween/halloween_gift.mdl"
				self:SetMaterial("effects/australium_aquamarine")
				self.soundfile = "ui/item_gift_wrap_unwrap.wav"
				self.NoImpactNoise = true
				self.NoAutoPickup = true
				self.ZoneClearPickupImmunity = true
				self.PickupName = bignumwrite(self.Qty) .. " Unclaimed AceCubes"
				self.Rare = 5
				self.Desc = "Drops if a cube NPC dies to something other than a player's wrath."
				self.func = function(ent)
					ent:GiveCubes(1, self.Qty, self:GetPos())
					ent:GiveCubes(2, self.Qty, self:GetPos())
				end
			elseif self.ItemID == 8 then
				local mats = {"effects/australium_sapphire", "models/player/shared/gold_player", "effects/australium_emerald", "effects/australium_amber", "effects/australium_platinum", "effects/australium_pinkquartz", "effects/australium_aquamarine", "models/weapons/v_slam/new light2", "models/props/cs_office/clouds", "effects/australium_ruby"}
				local phrases = {"Level Up", "Upgrade", "Promotion", "Training", "Spec Ops", "Reclassification", "Advancement", "Improvement", "Empowerment", "Ameliorate"}
				if !self.SubID then self.SubID = math.random(#mats) end
				self.SubID = math.min(self.SubID, math.min(10, 3 + math.floor(GetCurZone()/5)))
				self.ModelPath = "models/xqm/rails/trackball_1.mdl"
				self:SetMaterial(mats[self.SubID])
				self:EmitSound("rf/platinum.wav", 115)
				self.soundfile = "rf/acquire.wav"
				self.Qty = {1, 0}
				self.NoImpactNoise = true
				self.NoAutoPickup = true
				self.ZoneClearPickupImmunity = true
				self.NoPickupWhenNotHibernating = true
				self.PickupName = phrases[self.SubID] .. " Capsule"
				self.Rare = 9
				self.Wondrous = true
				self.Desc = "Cheat the leveling system once, you handsome rogue."
				self.func = function(ent)
					for k, v in pairs(player.GetAll()) do
						v:SetLv(self.SubID, v.accountdata["level"][self.SubID] + 1)
					end
				end
			elseif self.ItemID == 9 then
				self.ModelPath = "models/props_halloween/hwn_flask_vial.mdl"
				self.soundfile = "rf/stats/maxhealth.wav"
				self.Qty = {1, 0}
				self.NoImpactNoise = true
				self.PickupName = "Rejuvenation Potion"
				self.Rare = 3
				self.Desc = "A refreshing, yet flavourless beverage. Recovers 25% Block."
				self.func = function(ent)
					bignumadd(ent.Block64, bignumdiv(bignumcopy(ent.MaxBlock64), 4))
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
				self.NoAutoPickup = true
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
		else
			self.Qty = {1, 0}
			self.ModelPath = self.CustomModelPath
			self.soundfile = self.customsoundfile
			self.sndpitch = self.customsndpitch
			self:SetMaterial(self.custommaterial)
			self:SetModelScale(self.custommodelscale)
			self.PickupName = self.CustomPickupName
			self.Rare = self.CustomRare
			self.NoPhysics = self.CustomNoPhysics
			self.ZoneClearPickupImmunity = true
			self.Desc = self.CustomDesc
			self.func = self.customfunc
			self.spawnfunc = self.customspawnfunc
			if self.CustomCanOnlyBeTakenBy then
				self.CanOnlyBeTakenBy = self.CustomCanOnlyBeTakenBy
			end
			self.NoAutoPickup = true
		end
		
		if self.spawnfunc then self.spawnfunc(self) end
		
		if self.WeaponDrop then
			self.func = function(ent) ent:RewardWeapon(self.WeaponClass, self.RndDmg) end
		end
		
		if self.NoModel then self.ModelPath = "models/hunter/blocks/cube025x025x025.mdl" end
		
		if self.sndpitch == nil then self.sndpitch = 100 end --error-proofing

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
		
		self.BeginUse = true
		timer.Simple(0.01, function() if IsValid(self) then self.BeginUse = nil end end) --for insta-give pickups
	
		self.PickedUp = 0

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
		if !self.SilentCollect && !self.NoImpactNoise then
			self:EmitSound( "rf/itemimpact.wav", 75, 100 )
		end
		self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	end
end

function ENT:StartTouch(ply)
	if ply:IsPlayer() && self.PickedUp == 0 && !self.NoAutoPickup then
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

function ENT:ActivateEffect( ply )
		local raritycolours = {Color(255,255,255), Color(0,255,0), Color(0,133,255), Color(127,0,255),Color(255,135,0),Color(0,255,255),Color(255,0,0),Color(0,0,255),Color(255,133,133),Color(0,0,0),Color(255,0,255)}
		if !self.SilentCollect then
			SendPopoff(self.PickupName, ply,Color(0,0,0),raritycolours[math.min(math.max(1,self.Rare),#raritycolours) or 1])
		end
		if self.func then self.func(ply) end
end

if SERVER then
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
	if !self.ArchivePos then self.ArchivePos = self:GetPos() end
	if !util.IsInWorld(self.ArchivePos) && self.PickedUp != 1 then self:Remove() end --if we somehow first spawned outside the world
	if self.PickedUp == 0 then
	--if (GetConVar("craftworld3_pickups"):GetInt() or 1) == 0 then self:Remove() end
	for k, hurt in pairs(ents.FindInSphere(self:GetPos(),1)) do
		if hurt:GetClass() == "trigger_hurt" && self.PickedUp != 1 then
			if !self.Retries then self.Retries = 0 end
			self:SetPos(self.ArchivePos)
			self:EmitSound("rf/discharge.wav")
			self.Retries = self.Retries + 1
			WarpFX(self)
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
			WarpFX(self)
			self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
			if self:WaterLevel() > 0 or self.Retries > 10 then --still in water even after teleportation/teleported 10 times?
				self:Remove()
			end
		end
	end
	if self.CanOnlyBeTakenBy then --is this item assigned to a player?
		if not IsValid(self.CanOnlyBeTakenBy) then --does the said player no longer exist?
			WarpFX(self)
			self:Remove()
		end
	end
		self:SetNWString("pickname", self.PickupName or "?")
		self:SetNWString("pickdesc", self.Desc or "")
		self:SetNWInt("pickamount", 1)
		self:SetNWInt("pickrarity", self.Rare or 1)
		self:SetNWString("itemowner", "unassigned")
	self:RemoveAllDecals()
	self:NextThink( CurTime() )
	return true
end
end

function ENT:Use( ply, caller )
	if self.PickedUp == 0 then
	if self.DontAnimate then self.Immediate = true end
	if ply:IsPlayer() && caller:IsPlayer() then
	if self.NoPickupWhenNotHibernating && !Hibernating() then ply:PrintMessage(HUD_PRINTCENTER, "This item cannot be taken whilst the zone is not hibernating.") return end
	if self.CanOnlyBeTakenBy then
		if self.CanOnlyBeTakenBy != ply then
			ply:PrintMessage(HUD_PRINTCENTER, "This item can only be taken by: " .. self.CanOnlyBeTakenBy:Nick())
		end
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
				local onesie = ents.Create("cw3_pickup")
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
							if IsValid(self:GetChildren()[1]) then
								self:GetChildren()[1]:SetModelScale(0.01,speed/5)
								local subject = self:GetChildren()[1]:GetChildren()
								for c = 1, #subject do
									subject[c]:SetModelScale(0.01,speed/5)
								end
							end
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