
AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )


ENT.PrintName		= "Treasure Chest"
ENT.Author			= "Jen Walter"
ENT.Information		= ""
ENT.Category		= "CraftWoRLD 2"

ENT.Editable			= true
ENT.Spawnable			= true
ENT.AdminOnly			= true
ENT.RenderGroup 		= RENDERGROUP_TRANSLUCENT

list.Set( "SENT", "Treasure Chest", {
	Name = "Treasure Chest", 
	Class = "ses_chest", 
	Category = "CraftWoRLD 2"
} )

local chests = {"models/fortnite/fn_loot_caches/treasurechestloottier1.mdl", "models/fortnite/fn_loot_caches/treasurechestloottier2.mdl", "models/fortnite/fn_loot_caches/treasurechestloottier3.mdl", "models/fortnite/fn_loot_caches/treasurechestloottier4.mdl", "models/fortnite/fn_loot_caches/treasurechestloottier5-6.mdl", "models/fortnite/fn_loot_caches/treasurechestloottier5-6.mdl"}
local specials = {"models/fortnite/fn_loot_caches/treasurechestloottier1.mdl","models/fortnite/fn_loot_caches/prop_smallsafe.mdl", "models/fortnite/fn_loot_caches/gunsafe.mdl", "models/fortnite/fn_loot_caches/loot_tall_tier4.mdl", "models/fortnite/fn_loot_caches/loot_tall_tier5.mdl"}

function ENT:SetupDataTables()
end

function ENT:SpawnFunction( ply, tr, ClassName )

	if ( !tr.Hit ) then return end
	
	local SpawnPos = tr.HitPos + tr.HitNormal * 10
	
	local ent = ents.Create( ClassName )
	ent:SetPos( SpawnPos )
	ent:SetAngles(Angle(ply:EyeAngles():Forward()*180,0,0))
	ent:Spawn()
	
	return ent
	
end

if ( SERVER ) then
function ENT:Initialize()
	local rarity = {}
	if self.Specialised == nil then
		if math.random(1,10) == 1 then
			self.Specialised = true
		end
	end
	if !self.Specialised then
		for i = 1, #chests do
			for c = 1, 2^i do
				table.insert(rarity, (#chests+1)-i)
			end
		end
	else
		rarity = math.random(2,#specials)
	end
	if !self.Locked then
		self.Locked = false
	end
	if istable(rarity) then
		rarity = rarity[math.random(#rarity)]
	end
	--self.Specialised = false
	--rarity = 6
	local apparel = ""
	if self.Specialised then
		local colours = {Color(0,0,0),Color(0,255,0),Color(0,137,255),Color(127,0,255),Color(255,137,0)}
		local names = {"","Safe","Large Safe","Gilded Safe","Huge Vault"}
		apparel = specials[rarity]
		Announce(names[rarity] .. " spawned", colours[rarity], Color(255,255,0))
	else
		local colours = {Color(255,255,255),Color(0,255,0),Color(0,137,255),Color(127,0,255),Color(255,137,0),Color(0,255,255)}
		apparel = chests[rarity]
		Announce("Level " .. rarity .. " Chest spawned", colours[rarity], Color(255,255,0))
	end
	self:SetModel(apparel)
	self:SetMaxHealth(rarity)
	self.Indestructible = true
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	if IsValid(self:GetPhysicsObject()) then
		self:GetPhysicsObject():Wake()
	end
	if self:GetMaxHealth() >= 6 then
		self:SetSkin(1)
	end
	self:SetTrigger(true)
	self:SetUseType(SIMPLE_USE)
end
function ENT:Think()
	if IsValid(self:GetParent()) then
		if self:GetParent():GetClass() == "npc_antlion" then
			local mimic = self:GetParent()
			local bonepos, boneang = mimic:GetBonePosition(mimic:LookupBone("Antlion.Head_Bone"))
			self:SetParent(nil)
			self:SetPos(Vector(bonepos.x,bonepos.y,bonepos.z-11) - mimic:GetAngles():Forward()*3)
			self:SetParent(mimic)
			self:SetAngles(Angle(boneang.x+180,boneang.y,boneang.z+90))
			self:SetModelScale(mimic:GetModelScale())
		end
	end
	self:NextThink(CurTime()+0.01)
	return true
end
end

if ( CLIENT ) then

	function ENT:Draw()
		self:DrawModel()
		if !IsValid(self:GetParent()) then
			for k, v in next, player.GetAll() do
				if v == LocalPlayer() && self:GetMaxHealth() > 0 && !v:GetNWBool("isdarkzone",false) then
					local cost = math.ceil((800*self:GetMaxHealth())*(1.13^LocalPlayer():GetNWInt("playerlevelcap",0)))
					cam.Start3D2D( (self:GetPos() + Vector(0,0,self:OBBMaxs().z) ), Angle( 0, LocalPlayer():EyeAngles().y - 90, 90), 1 )
						draw.SimpleTextOutlined( string.Comma(cost), "size60l", 0, -20, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0) )
					cam.End3D2D()
				end
			end
		end
	end
	
end

function ENT:PhysicsCollide( data, physobj )
end

function ENT:OnTakeDamage( dmginfo )
end

if CLIENT then
function ENT:Think()
	if IsValid(self:GetParent()) then
		if self:GetParent():GetClass() == "npc_antlion" then
			if !self.NextScream then self.NextScream = CurTime()+math.random(7,9) end
			if CurTime() >= self.NextScream then
				self.NextScream = CurTime()+math.random(7,9)
				if self:GetParent():GetNWInt("64health",0) <= math.floor(self:GetParent():GetNWInt("64maxhealth",0)/5) then
					self:EmitSound("rf/mimic/lowhealth" .. math.random(1,4) .. ".wav", 110, 110 - (10*self:GetModelScale()))
				else
					self:EmitSound("rf/mimic/yell" .. math.random(1,4) .. ".wav", 110, 110 - (10*self:GetModelScale()))
				end
			end
		end
	end
end
end

function ENT:Use( ply, caller )
	if IsValid(ply) && ply:IsPlayer() then
		local cost = math.ceil((800*self:GetMaxHealth())*(1.13^GetWorldLevel()))
		if string.find(GetZone(),"darkzone") then cost = 0 end
		if !self.AlreadyOpen && (ply:GetAccountItems()["gold"] >= cost or (ply:HasKey("normal") && !ply:Crouching())) && !self.Locked then
			if (!ply:HasKey("normal") or ply:Crouching()) && !self.AlreadyMimic && math.random(1,10) == 1 then
				local brobdingnagian = false
				if math.random(1,10) == 1 then
					brobdingnagian = true
				end
				dmgpop(cost, 15, self)
				ply:AddAccountItems(1,-cost)
				self.Locked = true
				self.AlreadyMimic = true
				self:EmitSound("rf/search/treasure_mimic.wav", 110)
				timer.Simple(1.5, function() if IsValid(self) then
				dmgpop(cost, 14, self)
				ply:AddAccountItems(1,cost)
				self:SetBodygroup(0,1)
					for i = 1, 700 do
						timer.Simple(i/100, function() if IsValid(self) then
							for c = 1, 5 do
								local aberration = ents.Create("prop_dynamic")
								aberration:SetModel(self:GetModel())
								aberration:SetMaterial(self:GetMaterial())
								aberration:SetRenderMode(RENDERMODE_TRANSALPHA)
								aberration:SetColor(Color(math.random(0,255),math.random(0,255),math.random(0,255),80))
								aberration:SetPos(self:GetPos() + ((VectorRand()*(701-i))/30))
								aberration:SetAngles(self:GetAngles())
								aberration.IsDebris = 1
								aberration.Indestructible = 1
								aberration.SubmergeBroken = true
								timer.Simple(0.01, function() if IsValid(aberration) then aberration:Remove() end end)
							end
						end end)
					end
				end end)
				timer.Simple(2.5, function() if IsValid(self) then
					if brobdingnagian then
						self:EmitSound("rf/warning.wav")
						self:EmitSound("rf/boss_warning.wav")
						self:EmitSound("rf/warning.wav")
						self:EmitSound("rf/boss_warning.wav")
						SendPopoff("A brobdingnagian mimic is incoming!!!!!", self, Color(127,0,255), Color(0,0,0))
					elseif self:GetMaxHealth() >= 6 then
						self:EmitSound("rf/warning.wav")
						self:EmitSound("rf/boss_warning.wav")
						SendPopoff("A huge mimic is incoming!!!", self, Color(255,0,0), Color(0,0,0))
					end
				end end)
				timer.Simple(9, function() if IsValid(self) then
					local giants = {2,3,4,5,8}
					self:EmitSound("rf/mimic/yell4.wav", 110)
					local mimic = ents.Create("npc_antlion") --surprise, bitch! muah-hahaha
					mimic:SetPos(self:GetPos())
					if brobdingnagian then
						mimic.OverrideBadass = 14
					elseif self:GetMaxHealth() > 1 then
						mimic.OverrideBadass = giants[math.Clamp(self:GetMaxHealth()-1,1,5)]
					end
					mimic.AdditivePrestige = self:GetMaxHealth()*15
					mimic:Spawn()
					local bonepos, boneang = mimic:GetBonePosition(mimic:LookupBone("Antlion.Head_Bone"))
					self:SetParent(mimic)
					self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
					timer.Simple(0.1, function() if IsValid(mimic) then self:SetModelScale(mimic:GetModelScale()) end end) --if the mimic spawns as a resized npc, we need to readjust the size of the chest
					mimic:ManipulateBoneScale(mimic:LookupBone("Antlion.Head_Bone"), Vector(0.1,0.1,0.1))
				end end)
			elseif !self.Locked then --6.409
				self.AlreadyOpen = true
				if ply:HasKey("normal") && !ply:Crouching() then
					ply:TakeKey("normal", 1)
					Announce(ply:Nick() .. " used a key! Keys left: " .. ply.ChestKeys, Color(255,255,255), Color(0,0,0), 4, ply)
				else
					dmgpop(cost, 15, self)
					ply:AddAccountItems(1,-cost)
				end
				self:EmitSound("rf/search/treasure.wav", 110)
				if !string.find(GetZone(),"darkzone") then
					for k, p in pairs(player.GetAll()) do
						p:XP(cost/5,1)
					end
				end
				timer.Simple(2.267, function() if IsValid(self) then self:SetBodygroup(0,1) end end)
				timer.Simple(6.409, function() if IsValid(self) && IsValid(ply) then
					local artifact = ents.Create("ses_artifact")
					artifact:SetPos(self:GetPos() + self:OBBCenter())
					artifact:Spawn()
					if self.Specialised then
						if self:GetMaxHealth() == 2 then
							for i = 1, 2 do
								local gold = ents.Create("ses_pickup")
								gold:SetPos(self:GetPos())
								gold.ItemID = -9
								gold.SubID = table.Random({8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,1,1,1,1,1,2,2,2,15,15,15,15,15,15,16,14,14,14,14,14,14,12,12,11,11,11,11,11,11,11})
								gold:Spawn()
							end
						elseif self:GetMaxHealth() == 3 then
							for w = 1, 1 do
								RandomWeapon(self:GetPos() + self:OBBCenter(), ply:GetHeroLevel() + ply:GetHeroDZLevel(), math.ceil(ply.HeroLevel/10), ply.HeroRarity, ply:SteamID())
							end
							for i = 1, 50 do
								local lewt = ents.Create("ses_pickup")
								lewt.ItemOwner = ply:SteamID()
								lewt:SetPos(self:GetPos() + self:OBBCenter())
								--lewt:SetAngles(self:GetAngles())
								lewt.speedmult = 1
								lewt.ItemID = math.random(1,7)
								lewt:Spawn()
							end
								local gold = ents.Create("ses_pickup")
								gold:SetPos(self:GetPos())
								gold.ItemID = -9
								gold.SubID = table.Random({8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,1,1,1,1,1,2,2,2,15,15,15,15,15,15,16,14,14,14,14,14,14,12,12,11,11,11,11,11,11,11})
								gold:Spawn()
						elseif self:GetMaxHealth() == 4 then
							for i = 1, 60 do
								local lewt = ents.Create("ses_pickup")
								lewt.ItemOwner = ply:SteamID()
								lewt:SetPos(self:GetPos() + self:OBBCenter())
								--lewt:SetAngles(self:GetAngles())
								lewt.speedmult = 1
								lewt.ItemID = 8
								lewt:Spawn()
							end
							for i = 1, 3 do
								local gold = ents.Create("ses_pickup")
								gold:SetPos(self:GetPos())
								gold.ItemID = -6
								gold.SubID = math.random(1,13)
								gold:Spawn()
							end
								local gold = ents.Create("ses_pickup")
								gold:SetPos(self:GetPos())
								gold.ItemID = -9
								gold.SubID = table.Random({8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,1,1,1,1,1,2,2,2,15,15,15,15,15,15,16,14,14,14,14,14,14,12,12,11,11,11,11,11,11,11})
								gold:Spawn()
						elseif self:GetMaxHealth() == 5 then
							for w = 1, 12 do
								local gold = ents.Create("ses_pickup")
								gold:SetPos(self:GetPos())
								gold.ItemID = -9
								gold.SubID = table.Random({8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,1,1,1,1,1,2,2,2,15,15,15,15,15,15,16,14,14,14,14,14,14,12,12,11,11,11,11,11,11,11})
								gold:Spawn()
							end
						end
					else
						if string.find(GetZone(), "darkzone") then
							for i = 1, self:GetMaxHealth()*3 do
								local gold = ents.Create("ses_pickup")
								gold:SetPos(self:GetPos())
								gold.ItemID = -9
								gold.SubID = table.Random({8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,1,1,1,1,1,2,2,2,15,15,15,15,15,15,16,14,14,14,14,14,14,12,12,11,11,11,11,11,11,11,17,17,17,17,17,17,17,17,17,17,17,17,17,18,18,18,18,18,18,18,18,18,18,18,18,19,19,19,19,19,20,20,20,20,20,21,21,22})
								gold:Spawn()
							end
						else
							for i = 1, 12*self:GetMaxHealth() do
								local gold = ents.Create("ses_pickup")
								gold:SetPos(self:GetPos() + self:OBBCenter())
								gold.ItemID = -6
								gold.tierboost = self:GetMaxHealth()-1
								gold:Spawn()
							end
							if self:GetMaxHealth() >= 2 then
								for i = 1, self:GetMaxHealth() - 1 do
									local gold = ents.Create("ses_pickup")
									gold:SetPos(self:GetPos())
									gold.ItemID = -9
									gold.SubID = table.Random({8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,1,1,1,1,1,2,2,2,15,15,15,15,15,15,16,14,14,14,14,14,14,12,12,11,11,11,11,11,11,11,17,17,17,17,17,17,17,17,17,17,17,17,17,18,18,18,18,18,18,18,18,18,18,18,18,19,19,19,19,19,20,20,20,20,20,21,21,22})
									gold:Spawn()
								end
							end
						end
						if self:GetMaxHealth() >= 6 then
							if math.random(1,4) == 1 then
								local gold = ents.Create("ses_pickup")
								gold:SetPos(self:GetPos())
								gold.ItemID = -6
								gold.SubID = 13
								gold:Spawn()
							end
						end
					end
					self:SetMaxHealth(0)
					if IsValid(self:GetPhysicsObject()) then self:GetPhysicsObject():AddVelocity(VectorRand()*500) self:GetPhysicsObject():AddAngleVelocity(VectorRand()*1080) end
					timer.Simple(10, function() if IsValid(self) then self.InstantSoftRemove = 1 self:EmitSound("rf/revoke.wav") end end)
				elseif IsValid(self) then
					self:SetBodygroup(0,0)
					SendPopoff("Oops! The player I was targetting is no longer valid! Closed chest.", self, Color(255,0,0), Color(0,0,0))
					self.AlreadyOpen = false
				end end)
			end
		elseif ply:GetAccountItems()["gold"] < cost && !self.AlreadyOpen then
			ply:PrintMessage(HUD_PRINTCENTER, "Not enough ATOhMs, stranga! [" .. string.Comma(ply:GetAccountItems()["gold"]) .. " / " .. string.Comma(cost) .. "]")
		end
	end
end