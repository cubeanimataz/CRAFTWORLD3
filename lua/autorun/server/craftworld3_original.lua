-- enabled = false
enabled = true

if enabled then

local CRAFTWORLD3_Christmas = false

local sdir = "craftworld3_server"
file.CreateDir(sdir)
if !file.Exists(sdir .. "/cfg.txt", "DATA") then
	file.Write(sdir .. "/cfg.txt", util.TableToJSON(
		{
			["admin"] =
			{
				["use_cw3admin_cfg"] = false,
				["admin_cheats"] = true,
				["admin_cheats_nolimits"] = false
			},
			["spawning"] =
			{
				["npcs"] =
				{
					["allow_any"] = false,
					["allow_admin"] = false,
					["allow_superadmin"] = true,
					["allow_cw3admin"] = true,
					["spawn_cooldown"] = 0,
					["spawn_cooldown_admin"] = -1,
					["max_npcs"] = 50
				},
				["sents"] =
				{
					["allow_any"] = false,
					["allow_admin"] = false,
					["allow_superadmin"] = true,
					["allow_cw3admin"] = true
				},
				["map_config_sents"] =
				{
					["allow_any"] = false,
					["allow_admin"] = false,
					["allow_superadmin"] = true,
					["allow_cw3admin"] = true,
					["max_zones"] = -1
				},
				["cw3_sents"] =
				{
					["allow_any"] = false,
					["allow_admin"] = false,
					["allow_superadmin"] = false,
					["allow_cw3admin"] = false
				}
			},
			["player"] =
			{
				["size"] = 1.0,
				["head_size_scaling"] = false,
				["movement"] =
				{
					["base_speed"] = 160.0,
					["sprint_speedmultiplier"] = 2.0,
					["exhaustion_speedmultiplier"] = 0.75,
					["max_stamina"] = 150.0,
					["stamina_deplete_rate"] = 0.1,
					["stamina_regen_rate"] = 0.05,
					["stamina_regen_escalate"] = true,
					["stamina_regen_escalate_rate"] = 0.05,
					["base_jump"] = 200.0,
					["exhaustion_jumpmultiplier"] = 1.0,
					["stamina_jump_deplete_amount"] = 0.0,
					["fall_damage"] = true,
					["fall_damage_sensitivity"] = 750.0,
					["fall_damage_percentage"] = 10.0,
					["fall_damage_fatal"] = false,
					["fall_damage_disable_on_last_life"] = true
				},
				["stats"] =
				{
					["start_health"] = 50.0,
					["start_shield"] = 25.0,
					["start_primary"] = "weapon_smg1",
					["start_secondary"] = "weapon_pistol",
					["start_melee"] = "weapon_crowbar",
					["melee_replaceable"] = false,
					["start_primary_damage"] = 12.0,
					["start_secondary_damage"] = 16.0,
					["start_melee_damage"] = 33.0,
					["health_scalefactor"] = 1.13,
					["shield_scalefactor"] = 1.13,
					["primary_damage_scalefactor"] = 1.13,
					["secondary_damage_scalefactor"] = 1.13,
					["melee_damage_scalefactor"] = 1.13,
				},
				["noclip"] = false,
				["noclip_admin"] = true,
				["noclip_superadmin"] = true,
				["noclip_cw3admin"] = true,
				["damage_taken_multiplier"] = 1.0,
				["damage_dealt_multiplier"] = 1.0
			},
			["game"] =
			{
				["zone_boss_interval"] = 5.0,
				["zone_npc_cap"] = 100.0,
				["zone_npc_basecount"] = 10.0,
				["zone_npc_exponent"] = 1.043,
				["zone_npc_additive"] = 0.0,
				["zone_fail_on_player_ko"] = true,
				["zone_npc_powerscale_factor"] = 1.05,
				["zone_npc_powerscale_factor_increment"] = 0.01,
				["zone_npc_powerscale_multiplier"] = 1.0,
				["zonebomb_enable"] = true,
				["zonebomb_enable_boss"] = false,
				["backtrack_on_fail"] = true,
				["backtrack_bosszones"] = false,
				["hibernate_on_no_npcs"] = false,
				["wave_autostart"] = 20.0,
				["wave_autostart_boss"] = 45.0,
				["boss_activatedelay"] = 5.0,
				["boss_activatedelay_tooclose_range"] = 65.0
			}
		}
	))
end
local cfg = file.Read("craftworld3_server/cfg.txt", "DATA")
cfg = util.JSONToTable(cfg)

function GetAmpFactor()
	return {cfg["game"]["zone_npc_powerscale_factor"], cfg["game"]["zone_npc_powerscale_factor_increment"]}
end

function cw3error(msg)
	PrintMessage(HUD_PRINTTALK, "[CRAFTWORLD3 Error] " .. tostring(msg))
	return error("[CRAFTWORLD3 Error] " .. tostring(msg))
end

util.AddNetworkString("addpopoff")
util.AddNetworkString("msgann")
util.AddNetworkString("dmgpop")
util.AddNetworkString("sendheropackage")
util.AddNetworkString("updatestatuses")
util.AddNetworkString("characterdialogue")

function CharacterSpeech(text, reaction)
	net.Start("characterdialogue")
		net.WriteString(text)
		net.WriteInt(reaction, 5)
	net.Send(player.GetAll())
end

local curzone = 1 --current zone number
local zonekills = 0 --number of kills acquired
local maxzonekills = math.floor(cfg["game"]["zone_npc_basecount"] * cfg["game"]["zone_npc_exponent"]) --number of kills needed to progress to the next zone
local spawningallowed = CurTime() --admins are only allowed to spawn things when CurTime() is larger than this variable.
local allnpchp = {0, 0}
local autostart = CurTime() + cfg["game"]["wave_autostart"]

local enemies = {}
enemies["npc_zombie"] = {hp = bignumread("65"), dmg = bignumread("30"), gold = bignumread("35")}
enemies["npc_fastzombie"] = {hp = bignumread("40"), dmg = bignumread("10"), gold = bignumread("50")}
enemies["npc_zombie_torso"] = {hp = bignumread("55"), dmg = bignumread("16"), gold = bignumread("28")}
enemies["npc_fastzombie_torso"] = {hp = bignumread("35"), dmg = bignumread("8"), gold = bignumread("31")}
enemies["npc_poisonzombie"] = {hp = bignumread("300"), dmg = bignumread("92"), gold = bignumread("115")}
enemies["npc_headcrab"] = {hp = bignumread("25"), dmg = bignumread("9"), gold = bignumread("13")}
enemies["npc_headcrab_fast"] = {hp = bignumread("13"), dmg = bignumread("6"), gold = bignumread("9")}
enemies["npc_headcrab_black"] = {hp = bignumread("100"), dmg = bignumread("130"), gold = bignumread("90")}
enemies["npc_antlion"] = {hp = bignumread("450"), dmg = bignumread("48"), gold = bignumread("200")}
enemies["npc_antlionguard"] = {hp = bignumread("1.9K"), dmg = bignumread("750"), gold = bignumread("2.75K")}
enemies["npc_combine_s"] = {hp = bignumread("400"), dmg = bignumread("13"), gold = bignumread("195")}
enemies["npc_metropolice"] = {hp = bignumread("300"), dmg = bignumread("11"), gold = bignumread("137")}
enemies["npc_manhack"] = {hp = bignumread("80"), dmg = bignumread("20"), gold = bignumread("100")}
enemies["npc_rollermine"] = {hp = bignumread("1K"), dmg = bignumread("80"), gold = bignumread("1.2K")}

local allowednpcs = {"npc_zombie", "npc_fastzombie", "npc_zombie_torso", "npc_fastzombie_torso", "npc_poisonzombie", "npc_headcrab", "npc_headcrab_fast", "npc_headcrab_black", "npc_antlion", "npc_antlionguard", "npc_combine_s", "npc_metropolice", "npc_manhack", "npc_rollermine"}

function ResetEnemyStrength()
	enemies["npc_zombie"] = {hp = bignumread("65"), dmg = bignumread("30"), gold = bignumread("35")}
	enemies["npc_fastzombie"] = {hp = bignumread("40"), dmg = bignumread("10"), gold = bignumread("50")}
	enemies["npc_zombie_torso"] = {hp = bignumread("55"), dmg = bignumread("16"), gold = bignumread("28")}
	enemies["npc_fastzombie_torso"] = {hp = bignumread("35"), dmg = bignumread("8"), gold = bignumread("31")}
	enemies["npc_poisonzombie"] = {hp = bignumread("300"), dmg = bignumread("92"), gold = bignumread("115")}
	enemies["npc_headcrab"] = {hp = bignumread("25"), dmg = bignumread("9"), gold = bignumread("13")}
	enemies["npc_headcrab_fast"] = {hp = bignumread("13"), dmg = bignumread("6"), gold = bignumread("9")}
	enemies["npc_headcrab_black"] = {hp = bignumread("100"), dmg = bignumread("130"), gold = bignumread("90")}
	enemies["npc_antlion"] = {hp = bignumread("450"), dmg = bignumread("48"), gold = bignumread("200")}
	enemies["npc_antlionguard"] = {hp = bignumread("1.9K"), dmg = bignumread("750"), gold = bignumread("2.75K")}
	enemies["npc_combine_s"] = {hp = bignumread("400"), dmg = bignumread("13"), gold = bignumread("195")}
	enemies["npc_metropolice"] = {hp = bignumread("300"), dmg = bignumread("11"), gold = bignumread("137")}
	enemies["npc_manhack"] = {hp = bignumread("80"), dmg = bignumread("20"), gold = bignumread("100")}
	enemies["npc_rollermine"] = {hp = bignumread("1K"), dmg = bignumread("80"), gold = bignumread("1.2K")}
end

function Hibernating()
	if GetConVar("ai_disabled", 0):GetString() == "0" then
		return false
	end
	return true
end

function WarpFX(ent)
	ent:EmitSound("rf/warp.wav")
	ParticleEffect("teleportedin_red", ent:GetPos(), Angle(0,0,0))
	ParticleEffect("teleported_red", ent:GetPos(), Angle(0,0,0))
end

function Hibernate()
	RunConsoleCommand("ai_disabled", "1")
	for k, v in pairs(ents.GetAll()) do
		if v:IsNPC() then
			v:SetMaterial("models/props_combine/stasisfield_beam")
			v:SetColor(Color(255,255,255))
			v:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
			if !v.FreezeToPosition then v.FreezeToPosition = v:GetPos() end
			WarpFX(ent)
		end
	end
end

function GetAllNPCHP()
	local hp = {0, 0}
	for k, v in pairs(ents.GetAll()) do
		if v:IsNPC() then
			if v.Health64 then
				if bignumvalid(v.Health64) then
					bignumadd(hp, v.Health64)
				end
			end
		end
	end
	allnpchp = hp
end

function IncreaseEnemyStrength(iterations)
	if !iterations then iterations = 1 end
	for a = 1, iterations do
		for b = 1, #allowednpcs do
			enemies[allowednpcs[b]].hp = bignummult(enemies[allowednpcs[b]].hp, GetAmpFactor()[1] + ((curzone-1)*GetAmpFactor()[2]))
			enemies[allowednpcs[b]].dmg = bignummult(enemies[allowednpcs[b]].dmg, GetAmpFactor()[1] + ((curzone-1)*GetAmpFactor()[2]))
			enemies[allowednpcs[b]].gold = bignummult(enemies[allowednpcs[b]].gold, GetAmpFactor()[1] + ((curzone-1)*GetAmpFactor()[2]))
		end
	end
end

function RationaliseEnemyStrength()
	timer.Remove("npcrationalise")
	ResetEnemyStrength()
	if curzone-1 > 0 then
		timer.Create("npcrationalise", 0, curzone-1, function()
			IncreaseEnemyStrength(1)
			spawningallowed = CurTime() + 1 --disables spawning for 1 second
		end)
	end
end

function SetZone(zone)
	zone = math.Round(zone)
	if zone != curzone then
		curzone = zone
		zonekills = 0
		if zone % math.Round(cfg["game"]["zone_boss_interval"]) == 0 then
			maxzonekills = 1
		else
			maxzonekills = math.floor(cfg["game"]["zone_npc_basecount"] * (cfg["game"]["zone_npc_exponent"] ^ curzone))
		end
		RationaliseEnemyStrength()
		KillBomb()
	end
end

function string.squash(number, nodecimals, maxterm)
	if !isnumber(number) then return 0 end
	number = math.Round(number)
	local value = number
	--local term = {"Kilo", "Million", "Billion", "Trillion", "Quadrillion", "Quintillion", "Sextillion", "Septillion", "Octillion", "Nonillion", "Decillion", "Undecillion","Duodecillion","Tresdecillion","Quattuordecillion","Quinquadecillion","Sedecillion","Septendecillion","Octodecillion","Novendecillion","Vigintillion","Unvigintillion","Duovigintillion","Tresvigintillion","Quattuorvigintillion","Quinquadvigintillion","Sesvigintillion","Septemvigintillion","Octovigintillion","Novemvigintillion","Trigintillion","Untrigintillion","Duotrigintillion", "Trestrigintillion","Quattuortrigintillion","Quinquadtrigintillion","Sestrigintillion","Septentrigintillion","Octotrigintillion","Noventrigintillion","Quadragintillion","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","za","zb","zc","zd","ze","zf","zg","zh","zi","zj","zk","zl","zm","zn","zo","zp","zq","zr","zs","zt","zu","zv","zw","zx","zy","zz","zza","zzb","zzc","zzd","zze","zzf","zzg","zzh","zzi","zzj","zzk","zzl","zzm","zzn","zzo","zzp","zzq","zzr","zzs","zzt","zzu","zzv","zzw","zzx","zzy","zzz", "λ", "δ", "α", "β", "Σ", "θ", "η", "ω", "Ω", "ε"}
	local term = {" Thousand", " Million", " Billion", " Trillion", " Quadrillion", "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","za","zb","zc","zd","ze","zf","zg","zh","zi","zj","zk","zl","zm","zn","zo","zp","zq","zr","zs","zt","zu","zv","zw","zx","zy","zz","zza","zzb","zzc","zzd","zze","zzf","zzg","zzh","zzi","zzj","zzk","zzl","zzm","zzn","zzo","zzp","zzq","zzr","zzs","zzt","zzu","zzv","zzw","zzx","zzy","zzz", "α", "β", "ε"}
	if !maxterm then maxterm = 102 end
	local selected_term = "???"
	if !maxterm then maxterm = #term end
	if !isnumber(maxterm) then maxterm = #term end
	for i = 1, maxterm do
		if number >= 10^(3*i) then
			selected_term = term[math.min(i,#term)]
			if i >= #term then
				selected_term = selected_term .. i-#term
			end
			value = number
			value = value/(10^(3*i))
		end
	end
	if number >= math.huge then
		return "∞"
	elseif number >= 10^308 then
		return "δ"
	elseif number >= 10^5 then
		return math.Round(value, 2) .. selected_term
	else
		return string.Comma(number)
	end
end

function IsBaseCaptured()
	local captured = false
	for k, v in pairs(ents.FindByClass("ses_station")) do
		if v.Captured then captured = true end
	end
	return captured
end

function dmgpop(str, dmgtype, ent)
	local colours = {Color(255,255,255),Color(255,117,0),Color(0,97,255),Color(0,255,0),Color(0,79,0),Color(133,255,255),Color(127,0,255),Color(255,255,0),Color(109,255,109),Color(117,0,0), Color(0,127,255), Color(255,0,0), Color(127,127,127), Color(139,139,255), Color(255,139,139), Color(255,179,0), Color(255,0,255)}
	SendPopoff(str, ent, colours[math.min(dmgtype, #colours)], Color(0,0,0))
end

function ApplyStatus(target, status, quantity, time, decaytype, model, noreapply)
	if !target.StatusFX then target.StatusFX = {} end
	if HasStatus(target, status) and noreapply then return end
	if quantity == 0 then return end
	local duplicate = false
	if quantity > 0 then
		SendPopoff("+" .. string.Comma(quantity) .. " " .. string.upper(status), target,Color(255,127,255),Color(0,0,255))
	else
		SendPopoff(string.Comma(quantity) .. " " .. string.upper(status), target,Color(255,127,255),Color(255,0,0))
	end
	for i = 1, #target.StatusFX do
		if target.StatusFX[i]["effect"] == status then
			target.StatusFX[i]["qty"] = target.StatusFX[i]["qty"] + quantity
			duplicate = true
		end
	end
	if !duplicate then
		local tbl = { ["effect"] = status, ["qty"] = quantity, ["time"] = time, ["decay"] = decaytype, ["visual"] = model }
		table.insert(target.StatusFX, tbl)
	end
	target:EmitSound("rf/xploss.wav")
	local beacon = ents.Create("prop_dynamic")
	beacon:SetPos(target:GetPos() + target:OBBCenter())
	beacon:SetModel(model)
	beacon:SetMaterial("models/props_combine/stasisfield_beam")
	beacon:SetColor(Color(0,255,255))
	beacon:SetModelScale(5, 0)
	beacon:SetModelScale(1, 2)
	beacon:Spawn()
	timer.Simple(2, function() if IsValid(beacon) then beacon:Remove() end end)
end

function RemoveStatus(target, status)
	if !target.StatusFX then return end
	for i = 1, #target.StatusFX do
		if target.StatusFX[i]["effect"] then
			if target.StatusFX[i]["effect"] == status then
				SendPopoff(string.upper(target.StatusFX[i]["effect"]) .. " wears off", target,Color(127,127,127),Color(255,255,255))
				table.remove(target.StatusFX, i)
				target:EmitSound("rf/xpgain.wav")
			end
		end
	end
end

function HasStatus(target, status)
	if !target.StatusFX then return false end
	local has_effect = false
	for i = 1, #target.StatusFX do
		if target.StatusFX[i]["effect"] == status then
			has_effect = true
		end
	end
	return has_effect
end

function GetStatusQuantity(target, status)
	if !HasStatus(target, status) then return 0 end
	local num = 0
	for i = 1, #target.StatusFX do
		if target.StatusFX[i]["effect"] == status then
			num = target.StatusFX[i]["qty"]
		end
	end
	return num
end

function DispelStatus(target)
	if !target.StatusFX then return end
	for i = 1, #target.StatusFX do
		RemoveStatus(target, target.StatusFX[i]["effect"])
	end
	SendPopoff("Dispelled", target,Color(127,127,127),Color(0,0,0))
end

function SendPopoff(str, enti, cola, colb, specificplayer)
	if !specificplayer then specificplayer = player.GetAll() end
	if !cola then cola = Color(255,255,255) end
	if !colb then colb = Color(0,0,0) end
	net.Start("addpopoff")
		net.WriteString(str)
		net.WriteEntity(enti)
		net.WriteColor(cola)
		net.WriteColor(colb)
	net.Send(specificplayer)
end

function Announce(str, cola, colb, time, specificplayer)
	if !specificplayer then specificplayer = player.GetAll() end
	if !cola then cola = Color(255,255,255) end
	if !colb then colb = Color(0,0,0) end
	if !time then time = 4 end
	net.Start("msgann")
		net.WriteString(str)
		net.WriteColor(cola)
		net.WriteColor(colb)
		net.WriteFloat(time)
	net.Send(specificplayer)
end

function AddDir(dir)
	local list = file.FindDir("../"..dir.."/*")
	for _, fdir in pairs(list) do
		if fdir != ".svn" then
			AddDir(dir.."/"..fdir)
		end
	end
 
	for k,v in pairs(file.Find("../"..dir.."/*")) do
		resource.AddFile(dir.."/"..v)
	end
end

function addContentFolder( path )
	local files, folders = file.Find( path .. "/*", "GAME" )
	for k, v in pairs( files ) do
		resource.AddFile( path .. "/" .. v )
	end
end

resource.AddFile("resource/fonts/Overdose Sunrise.otf")
resource.AddFile("resource/fonts/ZCOOL.ttf")
resource.AddFile("resource/fonts/nasalization-rg.ttf")
resource.AddFile("resource/fonts/LightNovelPOP.ttf")
resource.AddFile("materials/game-border.png")
resource.AddFile("materials/prestige.png")
resource.AddFile("materials/sprites/shieldhex.vmt")
resource.AddFile("materials/sprites/shieldhex.vtf")
resource.AddFile("materials/sprites/shieldwarp.vmt")
resource.AddFile("materials/bl_hud/hud_alert.vtf")
resource.AddFile("materials/bl_hud/hud_bars.vtf")
resource.AddFile("materials/bl_hud/hud_bars.vmt")
resource.AddFile("materials/bl_hud/hud_bars_bg.vtf")
resource.AddFile("materials/bl_hud/hud_bars_bg.vmt")
resource.AddFile("materials/bl_hud/hud_bars_bg2.vmt")
resource.AddFile("materials/bl_hud/hud_compass.vmt")
resource.AddFile("materials/bl_hud/hud_compass.vtf")
resource.AddFile("materials/bl_hud/hud_icons.vmt")
resource.AddFile("materials/bl_hud/hud_icons.vtf")
resource.AddFile("materials/bl_hud/icon_alert.vmt")
resource.AddWorkshop("1551310214")
resource.AddWorkshop("675138912")
resource.AddWorkshop("777195612")
resource.AddWorkshop("1587540091")
resource.AddWorkshop("576996157")
resource.AddWorkshop("1625179363")
resource.AddWorkshop("1603126979")
resource.AddWorkshop("757604550")
resource.AddWorkshop("1655743290")
resource.AddWorkshop("1655753632")
resource.AddWorkshop("918084741")
resource.AddWorkshop("1636652043")

file.CreateDir("craftworld3")

function BreakEntity(victim, fallthru)
						if victim:GetClass() == "gmod_hands" then return end
						local breaksoundsets = { "rf/destruction/metal/vehicle_break.wav", "rf/destruction/stone/toilet_break.wav", "rf/destruction/metal/computer_break" .. math.random(1,2) .. ".wav", "rf/destruction/wood/tree_break.wav", "rf/destruction/wood/generic_break" .. math.random(1,3) .. ".wav", "rf/destruction/stone/generic_break" .. math.random(1,3) .. ".wav", "rf/destruction/metal/generic_break" .. math.random(1,3) .. ".wav", "rf/destruction/stone/ceramic_break" .. math.random(1,4) .. ".wav" }
						victim:EmitSound(breaksoundsets[victim.PropType or 8])
						victim.Health64 = 0
						for i = 1, math.random(3,6) do
							local giblet = ents.Create("base_gmodentity")
							giblet:SetModel("models/props_debris/concrete_chunk03a.mdl")
							giblet:SetModelScale(1,0)
							giblet:PhysicsInit(SOLID_VPHYSICS)
							giblet:SetSolid(SOLID_VPHYSICS)
							giblet:SetCollisionGroup(COLLISION_GROUP_WORLD)
							giblet:SetPos(victim:GetPos())
							giblet:SetAngles(victim:GetAngles())
							giblet:SetRenderMode(RENDERMODE_TRANSALPHA)
							if victim:GetMaterial() != "" then
								giblet:SetMaterial(victim:GetMaterial())
							else
								giblet:SetMaterial(victim:GetMaterials()[math.random(#victim:GetMaterials())] or "")
							end
							giblet:SetColor(victim:GetColor())
							giblet.IsDebris = true
							giblet.SubmergeBroken = true
							giblet:Spawn()
								if IsValid(giblet:GetPhysicsObject()) then
									local phy = giblet:GetPhysicsObject()
									phy:AddVelocity(VectorRand()*350)
									phy:AddAngleVelocity(VectorRand()*720)
								end
							timer.Simple(3, function() if IsValid(giblet) then giblet.SoftRemove = 1 end end)
						end
						if !string.find(victim:GetClass(), "ses_") then
							constraint.RemoveAll(victim)
							if IsValid(victim:GetPhysicsObject()) then victim:GetPhysicsObject():EnableMotion(true) end
							victim.IsDebris = 1
							victim:SetMaterial("models/charple/charple1_sheet")
							if victim:GetMaxHealth() <= 1 then
								if fallthru then
									victim:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
									timer.Simple(5, function() if IsValid(victim) then victim:Remove() end end)
								else
									victim.SoftRemove = 1
									timer.Simple(30, function() if IsValid(victim) then victim.InstantSoftRemove = 1 end end)
									victim:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
								end
							else
								victim:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
							end
						else
							SafeRemoveEntity(victim)
						end
end

function DynamicEffect(pos, id)
						if id == 1 then
								for i = 1, 8 do
								local debris = ents.Create("base_gmodentity")
								timer.Simple(5, function() if IsValid(debris) then debris.SoftRemove = 1 end end)
								debris.Indestructible = 1
								debris:SetPos(pos)
								if i == 8 then
									debris:SetModel("models/props_junk/wood_crate001a_chunk09.mdl")
								else
									debris:SetModel("models/props_junk/wood_crate001a_chunk0" .. i .. ".mdl")
								end
								debris:PhysicsInit(SOLID_VPHYSICS)
								debris:Spawn()
								debris:SetSolid(SOLID_VPHYSICS)
								debris:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
								timer.Simple(0, function()
								if IsValid(debris:GetPhysicsObject()) then
									debris:GetPhysicsObject():SetVelocity(Vector(math.random(-400,400),math.random(-400,400),math.random(-400,400)))
									debris:GetPhysicsObject():AddAngleVelocity(Vector(math.random(-400,400),math.random(-400,400),math.random(-400,400)))
								end
								end)
								end
						elseif id == 2 then
								local shards = {"a", "b", "c", "d", "e"}
								for i = 1, 8 do
								local debris = ents.Create("base_gmodentity")
								timer.Simple(5, function() if IsValid(debris) then debris.SoftRemove = 1 end end)
								debris.Indestructible = 1
								debris:SetPos(pos)
								debris:SetModel("models/props_c17/oildrumchunk01" .. shards[math.random(#shards)] .. ".mdl")
								debris:PhysicsInit(SOLID_VPHYSICS)
								debris:Spawn()
								debris:SetSolid(SOLID_VPHYSICS)
								debris:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
								timer.Simple(0, function()
								if IsValid(debris:GetPhysicsObject()) then
									debris:GetPhysicsObject():SetVelocity(Vector(math.random(-400,400),math.random(-400,400),math.random(-400,400)))
									debris:GetPhysicsObject():AddAngleVelocity(Vector(math.random(-400,400),math.random(-400,400),math.random(-400,400)))
								end
								end)
								end
						elseif id == 3 then
								local shards = {"a", "b", "c", "d", "e"}
								for i = 1, 8 do
								local debris = ents.Create("base_gmodentity")
								timer.Simple(5, function() if IsValid(debris) then debris.SoftRemove = 1 end end)
								debris.Indestructible = 1
								debris:SetPos(pos)
								debris:SetModel("models/gibs/wood_gib01"..shards[math.random(#shards)]..".mdl")
								debris:PhysicsInit(SOLID_VPHYSICS)
								debris:Spawn()
								debris:SetSolid(SOLID_VPHYSICS)
								debris:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
								timer.Simple(0, function()
								if IsValid(debris:GetPhysicsObject()) then
									debris:GetPhysicsObject():SetVelocity(Vector(math.random(-400,400),math.random(-400,400),math.random(-400,400)))
									debris:GetPhysicsObject():AddAngleVelocity(Vector(math.random(-400,400),math.random(-400,400),math.random(-400,400)))
								end
								end)
								end
						elseif id == 4 then
								for i = 1, 8 do
								local debris = ents.Create("base_gmodentity")
								timer.Simple(5, function() if IsValid(debris) then debris.SoftRemove = 1 end end)
								debris.Indestructible = 1
								debris:SetPos(pos)
								debris:SetModel("models/gibs/metal_gib"..math.random(1,5)..".mdl")
								debris:PhysicsInit(SOLID_VPHYSICS)
								debris:Spawn()
								debris:SetSolid(SOLID_VPHYSICS)
								debris:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
								timer.Simple(0, function()
								if IsValid(debris:GetPhysicsObject()) then
									debris:GetPhysicsObject():SetVelocity(Vector(math.random(-400,400),math.random(-400,400),math.random(-400,400)))
									debris:GetPhysicsObject():AddAngleVelocity(Vector(math.random(-400,400),math.random(-400,400),math.random(-400,400)))
								end
								end)
								end
						end
end

function ResetBones(ply)
	--angles
	ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_R_Upperarm"), Angle(0,0,0))
	ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_L_Upperarm"), Angle(0,0,0))
	ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_R_Forearm"), Angle(0,0,0))
	ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_L_Forearm"), Angle(0,0,0))
	ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_R_Thigh"), Angle(0,0,0))
	ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_L_Thigh"), Angle(0,0,0))
	ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_R_Calf"), Angle(0,0,0))
	ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_L_Calf"), Angle(0,0,0))
	ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_R_Foot"), Angle(0,0,0))
	ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_L_Foot"), Angle(0,0,0))
	ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_Spine1"), Angle(0,0,0))
	ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_Head1"), Angle(0,0,0))
	ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_Pelvis"), Angle(0,0,0))
	--positions
	ply:ManipulateBonePosition(ply:LookupBone("ValveBiped.Bip01_Pelvis"), Vector(0,0,0))
end

function ClassifyAsRubbish(entity)
	entity.SoftRemove = 1
	entity.IsDebris = 1
end

concommand.Add("destroyprops", function(ply)
	if ply:IsSuperAdmin() then
		for k, ent in pairs(ents.FindByClass("prop_*")) do
			if ent:IsVehicle() then
				BreakEntity(ent)
			elseif ent != blackhole && !ent.Indestructible && !ent.IsDebris then
				ent:Fire("break","")
			end
		end
		for k, ent in pairs(ents.FindByClass("gmod_*")) do
			if ent:GetClass() != "gmod_hands" && !ent:IsWeapon() then --don't erase the player's hands! 0_o
				BreakEntity(ent)
			end
		end
		for k, ent in pairs(ents.FindByClass("ent_fortnitestructure")) do
			BreakEntity(ent)
		end
	end
end)

concommand.Add("destroyses", function(ply)
	if ply:IsSuperAdmin() then
		for k, ent in pairs(ents.FindByClass("ses_*")) do
			if ent:GetClass() != "ses_chest" && ent:GetClass() != "ses_pickup" && ent:GetClass() != "ses_container" then
				BreakEntity(ent)
			end
		end
	end
end)

concommand.Add("silentslayall", function(ply)
	if ply:IsSuperAdmin() then
		for k, ent in pairs(ents.GetAll()) do
			if ent:IsNPC() then
				SlayEnemy(ent, 0, true)
			end
		end
	end
end)

concommand.Add("slayall", function(ply)
	if ply:IsSuperAdmin() then
		for k, ent in pairs(ents.GetAll()) do
			if ent:IsNPC() then
				SlayEnemy(ent, 1, false)
			end
		end
	end
end)

function SpawnGold(ent, gold)
	if isnumber(gold) then gold = bignumconvert(gold) end
	local g = ents.Create("ses_pickup")
	g.Qty = gold
	g.ItemID = 0
	g:SetPos(ent:GetPos() + ent:OBBCenter())
	g:Spawn()
end

function BombExists()
	local exists = false
	for k, p in pairs(ents.FindByClass("ses_pickup")) do
		if p.ItemID == -2 then
			exists = true
		end
	end
	return exists
end

function KillBomb()
	for k, p in pairs(ents.FindByClass("ses_pickup")) do
		if p.ItemID == -2 then
			WarpFX(p)
			p:Remove()
		end
	end
end

function PurgeEnemies()
	for k, ent in pairs(ents.GetAll()) do
		if ent:IsNPC() then
			SlayEnemy(ent, 0, true)
		end
	end
end

--whenever the code is refreshed, clean everything up
PurgeEnemies()
KillBomb()

function CreateBomb(pos)
	if !pos then --fallback to a random player spawnpoint
		local spawns = ents.FindByClass("info_player_start")
		if #spawns == 0 then
			PrintMessage(HUD_PRINTTALK, "[CRAFTWORLD3 Error] Failed to spawn bomb.")
			return
		else
			pos = spawns[math.random(#spawns)]:GetPos()
		end
	end
	if BombExists() then KillBomb() end
	local bomb = ents.Create("ses_pickup")
	bomb.ItemID = -2
	bomb:SetPos(pos)
	bomb:Spawn()
	timer.Simple(0, function() if IsValid(bomb) then if IsValid(bomb:GetPhysicsObject()) then bomb:GetPhysicsObject():EnableMotion(false) bomb:SetPos(pos) bomb:SetAngles(Angle(0,0,0)) end end end)
end

timer.Remove("zonetransition")
function CompleteZone()
	if timer.Exists("zonetransition") then return end
	timer.Remove("zonetransition") --just in case...
	zonekills = 0
	Announce("Zone " .. curzone .. " Cleared", Color(0,255,255), Color(0,58,255), 5)
	PurgeEnemies()
	for k, p in pairs(ents.FindByClass("ses_pickup")) do
		if p.PickedUp == 0 then
			local rnd = math.random(#player.GetAll())
			timer.Simple(math.Rand(0.1,3), function() if IsValid(p) && IsValid(player.GetAll()[rnd]) then p:Use(player.GetAll()[rnd],player.GetAll()[rnd],3,1) elseif IsValid(p) then WarpFX(p) p:Remove() end end)
		end
	end
	for k, ply in pairs(player.GetAll()) do
		local rndsnd = math.random(3)
		ply.Health64 = bignumcopy(ply.MaxHealth64)
		ply.Shield64 = bignumcopy(ply.MaxShield64)
		timer.Remove(ply:SteamID() .. "shieldcooldown")
		ply.RegenActive = true
		ply.RegenerationTime = 0
		ply.stamina = 150
		if curzone % math.Round(cfg["game"]["zone_boss_interval"]) == 0 then
			ply:GiveCubes(1, GetZoneCubeValue()[1], ply:GetPos())
			if curzone >= 25 then
				ply:GiveCubes(2, GetZoneCubeValue()[2], ply:GetPos())
			end
		else
			ply:RecoverPulses(1)
		end
		ply:EmitSound("rf/wave_outro" .. rndsnd .. ".wav")
	end
	spawningallowed = math.huge
	timer.Create("zonetransition", 7, 1, function()
		SetZone(curzone + 1)
	end)
end

function SlayEnemy(ent, goldmult, noprogress)
	if !ent:IsNPC() then cw3error("Attempt to slay non-NPC: " .. tostring(ent)) return end
	if ent == nil then cw3error("Target to slay does not exist (nil)") end
	if goldmult == nil then goldmult = 1 end
	if ent:IsNPC() then --just in case...
		if ent.MotorLoop then
			ent.MotorLoop:Stop()
			ent:EmitSound("rf/gore_metal.wav", 155, 100/(ent:GetModelScale()-0.75))
			for i = 1, math.ceil(4*ent:GetModelScale()) do
				local gibs = {"models/bots/gibs/demobot_gib_boss_arm1.mdl", "models/bots/gibs/demobot_gib_boss_arm2.mdl", "models/bots/gibs/demobot_gib_boss_leg1.mdl", "models/bots/gibs/demobot_gib_boss_leg2.mdl", "models/bots/gibs/demobot_gib_boss_leg3.mdl", "models/bots/gibs/demobot_gib_boss_pelvis.mdl","models/bots/gibs/heavybot_gib_boss_arm.mdl", "models/bots/gibs/heavybot_gib_boss_arm2.mdl", "models/bots/gibs/heavybot_gib_boss_chest.mdl", "models/bots/gibs/heavybot_gib_boss_leg.mdl", "models/bots/gibs/heavybot_gib_boss_leg2.mdl", "models/bots/gibs/heavybot_gib_boss_pelvis.mdl", "models/bots/gibs/pyrobot_gib_boss_arm1.mdl", "models/bots/gibs/pyrobot_gib_boss_arm2.mdl", "models/bots/gibs/pyrobot_gib_boss_arm3.mdl", "models/bots/gibs/pyrobot_gib_boss_chest.mdl", "models/bots/gibs/pyrobot_gib_boss_chest2.mdl", "models/bots/gibs/pyrobot_gib_boss_leg.mdl", "models/bots/gibs/pyrobot_gib_boss_pelvis.mdl", "models/bots/gibs/scoutbot_gib_boss_arm1.mdl", "models/bots/gibs/scoutbot_gib_boss_arm2.mdl", "models/bots/gibs/scoutbot_gib_boss_chest.mdl", "models/bots/gibs/scoutbot_gib_boss_leg1.mdl", "models/bots/gibs/scoutbot_gib_boss_leg2.mdl", "models/bots/gibs/scoutbot_gib_boss_pelvis.mdl", "models/bots/gibs/soldierbot_gib_boss_arm1.mdl", "models/bots/gibs/soldierbot_gib_boss_arm2.mdl", "models/bots/gibs/soldierbot_gib_boss_chest.mdl", "models/bots/gibs/soldierbot_gib_boss_leg1.mdl", "models/bots/gibs/soldierbot_gib_boss_leg2.mdl", "models/bots/gibs/soldierbot_gib_boss_pelvis.mdl"}
				local gib = ents.Create("prop_physics")
				gib:SetModel(gibs[math.random(#gibs)])
				gib:SetPos(ent:GetPos())
				gib:SetAngles(ent:GetAngles())
				gib:PhysicsInit(SOLID_VPHYSICS)
				gib:SetSolid(SOLID_VPHYSICS)
				gib:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
				gib:SetMaterial(ent:GetMaterial())
				gib:Spawn()
				timer.Simple(0, function() if IsValid(gib) then if IsValid(gib:GetPhysicsObject()) then gib:GetPhysicsObject():SetVelocity(VectorRand()*300) gib:GetPhysicsObject():AddAngleVelocity(VectorRand()*720) end end end)
				timer.Simple(7, function() if IsValid(gib) then gib.InstantSoftRemove = true end end)
			end
		else
			ent:EmitSound("rf/flesh.wav")
			local corpse = ents.Create("prop_ragdoll")
			corpse:SetModel(ent:GetModel())
			corpse:SetPos(ent:GetPos())
			corpse:SetAngles(ent:GetAngles())
			corpse:SetColor(Color(255,0,0))
			corpse:SetMaterial(ent:GetMaterial())
			corpse:Spawn()
			corpse:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
			if string.find(ent:GetClass(), "zombie") then
				corpse:SetBodygroup(0, 1)
			end
			timer.Simple(2, function() if IsValid(corpse) then corpse:Remove() end end)
		end
		if ent.Gold64 then
			if goldmult > 0 then
				SpawnGold(ent, bignummult(ent.Gold64, goldmult))
			end
		end
		if !noprogress then
			if curzone % math.Round(cfg["game"]["zone_boss_interval"]) == 0 then
				ParticleEffect("asplode_hoodoo", ent:GetPos(), Angle(0,0,0))
				CompleteZone()
			else
				zonekills = zonekills + 1
				if zonekills >= maxzonekills && !BombExists() then
					CreateBomb(ent:GetPos() + Vector(0,0,15))
				end
			end
		end
		ent:Remove()
	end
end

concommand.Add("hibernate", function(ply)
	if ply:IsSuperAdmin() then
		if Hibernating() then
			RunConsoleCommand("ai_disabled", "0")
		else
			RunConsoleCommand("ai_disabled", "1")
		end
	end
end)

concommand.Add("magnet", function(ply)
	if ply:IsSuperAdmin() then
		for k, ent in pairs(ents.FindByClass("ses_*")) do
			if ent:GetClass() == "ses_pickup" then
				if ent.ItemID != -3 then
					ent.ItemOwner = "unassigned"
					ent.OneAtATime = nil
					ent.Medical = nil
					ent:Use(ply, ply, 3, 1)
				end
			end
		end
	end
end)

concommand.Add("destroydoors", function(ply)
	if ply:IsSuperAdmin() then
		local blackhole = ents.Create("prop_dynamic")
			blackhole:SetModel("models/dav0r/hoverball.mdl")
			blackhole:SetColor(Color(0,0,0))
			blackhole:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
			blackhole:SetPos(ply:GetPos()+Vector(0,0,50))
			blackhole:SetModelScale(0.001, 0)
			blackhole:SetModelScale(2, 0.2)
			blackhole:EmitSound("rf/hole.wav")
		blackhole:Spawn()
		timer.Simple(9, function() if IsValid(blackhole) then blackhole:EmitSound("rf/hole.wav") blackhole:SetModelScale(0.001, 2) end end)
		timer.Simple(11, function() if IsValid(blackhole) then blackhole:Remove() end end)
		for k, ent in pairs(ents.FindByClass("func_door*")) do
				ent:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
				local pos = ent:GetPos()/100
				local pos2 = (ply:GetPos()+Vector(0,0,50))/100
				local ang = ent:GetAngles()/100
				local offset = math.Rand(0,8)
				for i=1,101 do
					timer.Simple(offset + i/100, function()
						if IsValid(ent) then
							if i == 101 then
								BreakEntity(ent)
							else
								if i == 1 then ent:SetModelScale(0.01,1) end
								ent:SetPos(ent:GetPos() - pos + pos2)
								ent:SetAngles(ent:GetAngles() - ang)
							end
						end
					end)
				end
		end
		for k, ent in pairs(ents.FindByClass("prop_door*")) do
				ent:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
				local pos = ent:GetPos()/100
				local pos2 = (ply:GetPos()+Vector(0,0,50))/100
				local ang = ent:GetAngles()/100
				local offset = math.Rand(0,5)
				for i=1,101 do
					timer.Simple(offset + i/100, function()
						if IsValid(ent) then
							if i == 101 then
								BreakEntity(ent)
							else
								if i == 1 then ent:SetModelScale(0.01,1) end
								ent:SetPos(ent:GetPos() - pos + pos2)
								ent:SetAngles(ent:GetAngles() - ang)
							end
						end
					end)
				end
		end
	end
end)

concommand.Add("destroyfuncs", function(ply)
	if ply:IsSuperAdmin() then
		local blackhole = ents.Create("prop_dynamic")
			blackhole:SetModel("models/dav0r/hoverball.mdl")
			blackhole:SetColor(Color(0,0,0))
			blackhole:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
			blackhole:SetPos(ply:GetPos()+Vector(0,0,50))
			blackhole:SetModelScale(0.001, 0)
			blackhole:SetModelScale(2, 0.2)
			blackhole:EmitSound("rf/hole.wav")
		blackhole:Spawn()
		timer.Simple(9, function() if IsValid(blackhole) then blackhole:EmitSound("rf/hole.wav") blackhole:SetModelScale(0.001, 2) end end)
		timer.Simple(11, function() if IsValid(blackhole) then blackhole:Remove() end end)
		for k, ent in pairs(ents.FindByClass("func_*")) do
				ent:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
				local pos = ent:GetPos()/100
				local pos2 = (ply:GetPos()+Vector(0,0,50))/100
				local ang = ent:GetAngles()/100
				local offset = math.Rand(0,8)
				for i=1,101 do
					timer.Simple(offset + i/100, function()
						if IsValid(ent) then
							if i == 101 then
								BreakEntity(ent)
							else
								if i == 1 then ent:SetModelScale(0.01,1) end
								ent:SetPos(ent:GetPos() - pos + pos2)
								ent:SetAngles(ent:GetAngles() - ang)
							end
						end
					end)
				end
		end
	end
end)

if engine.ActiveGamemode() == "sandbox" then

local enabled,hp_regen,sp_regen,max_armor,max_health,damagepercentage

util.AddNetworkString("SES.roller")

local CMoveData = FindMetaTable( "CMoveData" )

function CMoveData:RemoveKey( keys )
	-- Using bitwise operations to clear the key bits.
	local newbuttons = bit.band( self:GetButtons(), bit.bnot( keys ) )
	self:SetButtons( newbuttons )
end

local function TeslaSpark3(pos, magnitude,color)
	zap = ents.Create("point_tesla")
	zap:SetKeyValue("targetname", "teslab")
	zap:SetKeyValue("m_SoundName" ,"null")
	zap:SetKeyValue("texture" ,"sprites/laser.spr")
	zap:SetKeyValue("m_Color" ,color.r.." "..color.g.." "..color.b)
	zap:SetKeyValue("m_flRadius" ,tostring(magnitude*10))
	zap:SetKeyValue("beamcount_min" ,tostring(math.ceil(magnitude)))
	zap:SetKeyValue("beamcount_max", tostring(math.ceil(magnitude)))
	zap:SetKeyValue("thick_min", tostring(magnitude))
	zap:SetKeyValue("thick_max", tostring(magnitude))
	zap:SetKeyValue("lifetime_min" ,"0.13")
	zap:SetKeyValue("lifetime_max", "0.2")
	zap:SetKeyValue("interval_min", "0.05")
	zap:SetKeyValue("interval_max" ,"0.08")
	zap:SetPos(pos)
	zap:Spawn()
	zap:Fire("DoSpark","",0)
	zap:Fire("kill","", 0.1)
end

local function ShieldDown(pos, magnitude,color)
	zap = ents.Create("point_tesla")
	zap:SetKeyValue("targetname", "teslab")
	zap:SetKeyValue("m_SoundName" ,"null")
	zap:SetKeyValue("texture" ,"sprites/laser.spr")
	zap:SetKeyValue("m_Color" ,"255 255 255")
	zap:SetKeyValue("m_flRadius" ,tostring(magnitude*10))
	zap:SetKeyValue("beamcount_min" ,tostring(math.ceil(magnitude)))
	zap:SetKeyValue("beamcount_max", tostring(math.ceil(magnitude)))
	zap:SetKeyValue("thick_min", tostring(magnitude))
	zap:SetKeyValue("thick_max", tostring(magnitude))
	zap:SetKeyValue("lifetime_min" ,"0.2")
	zap:SetKeyValue("lifetime_max", "0.3")
	zap:SetKeyValue("interval_min", "0.05")
	zap:SetKeyValue("interval_max" ,"0.08")
	zap:SetPos(pos)
	zap:Spawn()
	zap:Fire("DoSpark","",0)
	zap:Fire("kill","", 0.1)
end

timer.Create("Decaytint",0.01,0,function()
	for k, obj in pairs(ents.GetAll()) do
		if IsValid(obj) then
			if obj.SoftRemove or obj.InstantSoftRemove then
				if !obj.IgnoreSoftRemove then
					if !obj.primeremoval then
						obj.primeremoval = true
						timer.Simple(7, function() if IsValid(obj) then
							if !obj:IsRagdoll() then
								local phys = obj:GetPhysicsObject()
								if IsValid(phys) then
									phys:EnableMotion(false)
									phys:Sleep()
								end
							else
								obj.ragdolltranq = true
							end
						end end)
					end
					if ((!IsValid(obj:GetPhysicsObject()) or obj:GetPhysicsObject():IsAsleep()) && !obj:IsRagdoll()) or (obj:IsRagdoll() && obj.ragdolltranq) or obj.InstantSoftRemove then
					obj.IgnoreSoftRemove = 1
					obj:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
					for i = 1, 101 do
						timer.Simple(i/13, function() if IsValid(obj) then
							if i == 101 then 
								obj:Remove()
							else
								if obj:IsRagdoll() then
									for i = 0, obj:GetPhysicsObjectCount()-1 do
										local phys = obj:GetPhysicsObjectNum(i)
										if IsValid(phys) then
											if i == 1 then phys:SetPos(phys:GetPos()+Vector(0,0,2),true) end
											phys:SetPos(phys:GetPos()-Vector(0,0,i/5),true)
										end
									end
								end
								obj:SetPos(obj:GetPos()-Vector(0,0,i/5))
							end
						end end)
					end
					end
				end
			end
		end
	end
end)

function GroundContact( ply, inWater, onFloater, speed )
	--[[local sensitivity = 1
	if game.GetMap() == "dm_lostarena" then
		sensitivity = 0.55
	end
	if game.GetMap() == "gm_construct_5" or game.GetMap() == "gm_construct_10" then
		sensitivity = 0.65
	end
	if ply.jumpboost > CurTime() then sensitivity = math.huge end
	if speed > 750*sensitivity then
		local intensity = math.ceil(speed/27.3*(1.13^ply:GetPlayerLevel()))
		if intensity > math.floor(ply.MaxHealth64/5) or intensity > math.floor(ply.Health64/2) then
			ply:EmitSound("rf/falldamage_heavy.wav")
		else
			ply:EmitSound("rf/falldamage.wav")
		end
		dmgpop(intensity, 12, ply)
		ply.Health64 = math.max(1, ply.Health64 - intensity)
	end
	if speed > 1000*sensitivity && !inWater then
		local stuntime = 2*(1 + (speed/1000))
		ply:SetNoDraw(true)
		ply:Freeze(true)
		timer.Simple(stuntime, function() if IsValid(ply) then
		ply:SetNoDraw(false)
		ply:Freeze(false)
		ply:EmitSound("rf/hole.wav")
		ParticleEffect("teleportedin_red", ply:GetPos(), Angle(0,0,0))
		ParticleEffect("teleported_red", ply:GetPos(), Angle(0,0,0))
		ply.DontRegen = nil
		end end)
		if speed > 1500*sensitivity then --bonk!
			ply.DontRegen = true
			ply.Shield64 = 0
			ply.Health64 = math.max(1,ply.Health64 - (ply.MaxHealth64/100*5))
				ply:EmitSound("rf/crush1.mp3")
				for i = 1, 15 do
					local concrete = ents.Create("prop_physics")
					concrete:SetModel("models/props_debris/concrete_chunk03a.mdl")
					concrete:PhysicsInit(SOLID_VPHYSICS)
					concrete:SetSolid(SOLID_VPHYSICS)
					concrete:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
					concrete:SetPos(ply:GetPos()+Vector(0,0,2))
					concrete.IsDebris = true
					concrete:SetAngles(Angle(math.random(-360,360),math.random(-360,360),math.random(-360,360)))
					timer.Simple(0, function() if IsValid(concrete) then
						local phys = concrete:GetPhysicsObject()
						if IsValid(phys) then
							phys:AddVelocity(Vector(math.random(-300,300),math.random(-300,300),400))
							phys:AddAngleVelocity(VectorRand()*720)
						end
					end end)
					timer.Simple(3, function() if IsValid(concrete) then concrete:Remove() end end)
				end
		else
			ply:EmitSound("rf/stunned.wav")
		end
		SendPopoff("Stunned!", ply,Color(255,0,0),Color(255,255,0))
		ply:CreateRagdoll()
		local rag = ply:GetRagdollEntity()
		if ply:SteamID() == "STEAM_0:1:45185922" or game.SinglePlayer then
			timer.Simple(0, function() if IsValid(rag) then rag:SetSubMaterial(0, "models/player/shared/gold_player") end end)
		end
		timer.Simple(stuntime, function() if IsValid(rag) then rag:Remove() end end)
	end]]
end

hook.Add("OnPlayerHitGround", "craftworld3_FALLDAMAGE", GroundContact)

--[[hook.Add("KeyPress","craftworld3_WEAPONMANAGER",function(ply,key)
	if IsValid(ply:GetActiveWeapon()) then
		if ply:GetActiveWeapon():Clip1() > 0 && ply:GetAmmoCount(ply:GetActiveWeapon():GetPrimaryAmmoType()) > 0 then
			local w = ply:GetActiveWeapon()
			if key == IN_RELOAD then
				if w.ModMag then
					if w:Clip1() < w.ModMag then
						ply:SetAmmo(ply:GetAmmoCount(w:GetPrimaryAmmoType()) + w:Clip1(), w:GetPrimaryAmmoType())
						if ply:GetAmmoCount(w:GetPrimaryAmmoType()) >= w.ModMag then
							w.ShotgunChambered = w:Clip1() --you never know, could be a one-at-a-time weapon!
							w.ShotgunAlreadyChambered = w:Clip1()
						end
						w:SetClip1(0)
					end
				end
			end
		end
	end
end)]]

function spawntext(str, ent, element, size, lifetime, usetfnumbers)
	if !str or str == "" or !isstring(str) then error("attempt to spawn nil string") end
	if !ent or !IsValid(ent) then error("attempt to spawn string on nil/null/invalid entity") end
	if !element or !isnumber(element) then element = 0 end
	if !size or !isnumber(size) then size = 1 end
	if !lifetime or !isnumber(lifetime) then lifetime = 3 end
	size = size/2
	if lifetime < 1 then lifetime = 1 end
	str = str .. " "
	local chars = { }
	local length = string.len(str)
	for i = 1, length do
		local char = string.sub(str, i, i)
		char = tostring(char)
		if char == "1" or char == "2" or char == "3" or char == "4" or char == "5" or char == "6" or char == "7" or char == "8" or char == "9" or char == "0" or char == " " then
			table.insert(chars, char)
		elseif char == "+" then
			table.insert(chars, "plus")
		elseif char == "!" then
			table.insert(chars, "escalmation")
		elseif char == "?" then
			table.insert(chars, "questionmark")
		elseif char == "$" then
			table.insert(chars, "dollar")
		elseif char == "/" then
			table.insert(chars, "slash")
		elseif char == "#" then
			table.insert(chars, "pound")
		elseif char == "&" then
			table.insert(chars, "and")
		elseif char == "%" then
			table.insert(chars, "percent")
		elseif char == "=" then
			table.insert(chars, "equals")
		elseif char == ":" then
			table.insert(chars, "colon")
		elseif char == ";" then
			table.insert(chars, "semicolon")
		elseif char == "," then
			table.insert(chars, "squote")
		else
			if char == string.lower(char) then char = char .. "l" end
			table.insert(chars, char)
		end
	end
	for i = 1, #chars do
		if chars[i] != " " then
			local digit = ents.Create("base_gmodentity")
			timer.Simple(lifetime + 2, function() if IsValid(digit) then digit:Remove() end end)
			digit.IsDebris = 1
			digit:SetGravity(0.1)
			local angx = 0
			if usetfnumbers then
				digit:SetModel("models/custom/tf" .. chars[i] .. ".mdl")
				angx = 90
				digit:ManipulateBoneScale(0, Vector(3,3,3))
			else
				digit:SetModel("models/comicsans/" .. chars[i] .. ".mdl")
			end
			digit:PhysicsInit(SOLID_VPHYSICS)
			digit:SetSolid(SOLID_VPHYSICS)
			digit:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
			digit:SetAngles(Angle(angx,ent:GetAngles().y,0))
			if ent:IsPlayer() then
				digit:SetAngles(digit:GetAngles() - Angle(0,180,0))
			end
			local phys = digit:GetPhysicsObject()
			digit:SetPos(ent:GetPos() + Vector(0,0,ent:OBBMaxs().z + 20) + digit:GetAngles():Right()*((-40*size)*i) + digit:GetAngles():Right()*((20*size)*#chars))
			if element == 1 then
				digit:SetMaterial("nature/underworld_lava001")
				ParticleEffectAttach("burningplayer_flyingbits", 1, digit, 1)
			elseif element == 2 then
				digit:SetMaterial("models/effects/invulnfx_blue")
				ParticleEffectAttach("critgun_weaponmodel_blu", 1, digit, 1)
			elseif element == 3 then
				digit:SetMaterial("models/shiney/emeraldgreen")
				ParticleEffect("green_wof_sparks", digit:GetPos(), Angle(90,0,0))
			elseif element == 4 then
				digit:SetMaterial("models/effects/splode_sheet")
				ParticleEffectAttach("Explosion", 1, digit, 1)
			elseif element == 5 then
				digit:SetMaterial("models/player/shared/ice_player")
				ParticleEffectAttach("xms_icicle_impact", 1, digit, 1)
				ParticleEffectAttach("xms_icicle_idle", 1, digit, 1)
			elseif element == 6 then
				digit:SetMaterial("passtime/neons/neon_green_stripe")
				ParticleEffectAttach("overhealedplayer_red_pluses", 1, digit, 1)
			elseif element == 7 then
				digit:SetColor(Color(0,0,255))
			elseif element == 8 then
				digit:SetColor(Color(255,255,0))
			elseif element == 9 then
				digit:SetMaterial("mm_materials/mechanite01")
				ParticleEffectAttach("eyeboss_projectile", 1, digit, 1)
			elseif element == 10 then
				digit:SetColor(Color(255,0,255))
			end
			if chars[i] == "squote" then
				digit:SetPos(digit:GetPos() - Vector(0,0,50*size))
			end
			timer.Simple(0, function() if IsValid(digit:GetPhysicsObject()) then digit:GetPhysicsObject():EnableMotion(false) end end)
			digit:SetModelScale(0.001)
			digit:SetModelScale(size*1.25, 0.1)
			timer.Simple(0.1, function() if IsValid(digit) then
				digit:SetModelScale(size, 0.15)
			end end)
			digit:Spawn()
			timer.Simple(lifetime, function() if IsValid(digit) then
				digit.TextDespawning = true
				digit:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
				local phys = digit:GetPhysicsObject()
				if IsValid(phys) then
					phys:EnableGravity(false)
					phys:EnableMotion(true)
					phys:Wake()
					phys:SetVelocity(Vector(math.Rand(-37,37),math.Rand(-37,37),math.Rand(-50,-25)))
					phys:AddAngleVelocity(VectorRand()*72)
				end
				digit:SetModelScale(0.001, 2)
			end end)
		end
	end
end

function GetZoneCubeValue()
	return {bignumconvert(math.Round((25 * (1.04^curzone))/8) + math.random(0,5*curzone)),bignumconvert(math.Round((25 * (1.04^(curzone-25)))/8) + math.random(0,2*curzone))}
end

function ownerlog(msg)
	--PrintMessage(HUD_PRINTTALK, msg)
end

function NewSave(ply)
	if !ply:IsPlayer() then return end
	ply:StripWeapons()
	ply:StripAmmo()
	local dir = "craftworld3/" .. string.Replace(ply:SteamID64(), ".", "_")
	file.CreateDir(dir)
		file.Write(dir .. "/initialjoin.txt", os.date( "Save created at %H:%M:%S BST on %d/%m/%Y" , os.time() ))
		ownerlog("CREATING NEW SAVE DATA: " .. ply:Nick() .. " [" .. ply:SteamID64() .. "]")
		ownerlog(os.date( "Save created at %H:%M:%S BST on %d/%m/%Y" , os.time() ))
		local heroes
		local account
		account = { ["gold"] = {0, 0}, ["timecubes"] = {0, 0}, ["weaponcubes"] = {0, 0}, ["prices"] = {{80, 0}, {15, 1}, {600, 2}, {75, 3}, {400, 5}, {245, 8}, {500, 11}, {800, 20}, {335, 35}, {500, 50}}, ["health"] = bignumread("125"), ["shield"] = bignumread("90"), ["level"] = {1,0,0,0,0,0,0,0,0,0}, ["investment"] = {0, 0}, ["points"] = {0,0,0,0} }
		heroes = { ["primaryweapon"] = {["class"] = "weapon_smg1", ["dmg"] = bignumread("10"), ["level"] = {1,0,0,0,0,0,0,0,0,0}, ["prices"] = {{40, 0}, {3, 1}, {200, 2}, {35, 3}, {200, 5}, {75, 8}, {90, 11}, {410, 20}, {35, 35}, {50, 50}}, ["investment"] = {0, 0}}, ["secondaryweapon"] = {["class"] = "weapon_pistol", ["dmg"] = bignumread("13"), ["level"] = {1,0,0,0,0,0,0,0,0,0}, ["prices"] = {{40, 0}, {3, 1}, {200, 2}, {35, 3}, {200, 5}, {75, 8}, {90, 11}, {410, 20}, {35, 35}, {50, 50}}, ["investment"] = {0, 0}}, ["meleeweapon"] = {["class"] = "weapon_crowbar", ["dmg"] = bignumread("32"), ["level"] = {1,0,0,0,0,0,0,0,0,0}, ["prices"] = {{40, 0}, {3, 1}, {200, 2}, {35, 3}, {200, 5}, {75, 8}, {90, 11}, {410, 20}, {35, 35}, {50, 50}}, ["investment"] = {0, 0}} }
		ownerlog("WRITING HERO DATA FOR " .. ply:SteamID64())
		file.Write(dir .. "/herodata.txt", util.TableToJSON(heroes))
		ownerlog("WRITING ACCOUNT DATA FOR " .. ply:SteamID64())
		file.Write(dir .. "/accountdata.txt", util.TableToJSON(account))
		ownerlog("SAVE DATA CREATED FOR " .. ply:SteamID64())
		ply.herodata = heroes
		ply.accountdata = account
		ply:Rationalise(true)
		ply.Armour64 = {0, 0}
end

concommand.Add("craftworld3_wipesave", function(ply)
	NewSave(ply)
end)

hook.Add("PlayerInitialSpawn","craftworld3_LOADDATA", function(ply)
	timer.Simple(1, function() if IsValid(ply) then ply:LoadCraftworldData() ply.Armour64 = {0, 0} end end)
end)

hook.Add("PlayerSpawn","craftworld3_PLAYERSPAWN", function(ply)
	timer.Simple(0, function() if IsValid(ply) then WarpFX(ply) if ply.accountdata && ply.herodata then ply:Rationalise(true) end end end)
end)

local ply = FindMetaTable( "Player" )

function ply:LoadCraftworldData()
	local dir = "craftworld3/" .. string.Replace(self:SteamID64(), ".", "_")
	file.CreateDir(dir)
	if !file.Exists(dir .. "/initialjoin.txt", "DATA") then
		NewSave(self)
	else
		ownerlog("EXISTING SAVE DATA FOUND: " .. self:SteamID64())
		local validsave = true
		ownerlog("CHECKING SAVE INTEGRITY")
		ownerlog("CHECKING: HERO DATA")
		if file.Exists(dir .. "/herodata.txt", "DATA") then
			ownerlog("EXISTS: HERO DATA")
		else
			validsave = false
			ownerlog("ERROR: HERO DATA NOT FOUND")
		end
		ownerlog("CHECKING: ACCOUNT DATA")
		if file.Exists(dir .. "/accountdata.txt", "DATA") then
			ownerlog("EXISTS: ACCOUNT DATA")
		else
			validsave = false
			ownerlog("ERROR: ACCOUNT DATA NOT FOUND")
		end
		if validsave then
			local herodatasave = "???"
			local accountdatasave = "???"
			ownerlog("SAVE FILE OK: " .. self:SteamID64())
			ownerlog("READING HERO DATA FOR " .. self:SteamID64())
			herodatasave = file.Read(dir .. "/herodata.txt", "DATA")
			ownerlog("READING ACCOUNT DATA FOR " .. self:SteamID64())
			accountdatasave = file.Read(dir .. "/accountdata.txt", "DATA")
			ownerlog("CONVERTING JSON DATA TO LUA TABLES")
			herodatasave = util.JSONToTable(herodatasave)
			accountdatasave = util.JSONToTable(accountdatasave)
			ownerlog("APPLYING DATA TO PLAYER " .. self:SteamID64())
			self.herodata = herodatasave
			self.accountdata = accountdatasave
			self:Rationalise(true)
		else
			NewSave(ply)
		end
	end
end

concommand.Add("setzone", function(ply,cmd,args)
	if !IsValid(ply) then return end
	if !args[1] then return end
	if ply:IsSuperAdmin() then
		PurgeEnemies()
		SetZone(tonumber(args[1]))
	end
end)

function ply:RecoverPulses(qty)
	self.healthstate = math.Clamp(self.healthstate, 1, 5)
	for i = 1, qty do
		local pulse = ents.Create("ses_pickup")
		pulse.ItemID = -1
		pulse:SetPos(self:GetPos())
		pulse:Spawn()
		timer.Simple(0, function() if IsValid(pulse) && IsValid(self) then pulse:Use(self,self,3,1) elseif IsValid(pulse) then pulse:Remove() end end)
	end
end

function ply:GainGold(gold)
	bignumadd(self.accountdata["gold"], gold)
end

function ply:SpendGold(gold)
	bignumsub(self.accountdata["gold"], gold)
end

function ply:GainTimeCubes(timecubes)
	bignumadd(self.accountdata["timecubes"],timecubes)
end

function ply:SpendTimeCubes(timecubes)
	bignumsub(self.accountdata["timecubes"], timecubes)
end

function ply:GainWeaponCubes(weaponcubes)
	bignumadd(self.accountdata["weaponcubes"], weaponcubes)
end

function ply:SpendWeaponCubes(weaponcubes)
	bignumsub(self.accountdata["weaponcubes"], weaponcubes)
end

function ply:GiveCubes(variant, qty, emit)
	if !variant then variant = 1 end
	if !qty then qty = 1 end
	if !emit then emit = self:GetPos() end
	if isnumber(qty) then
		qty = math.Round(qty)
		qty = bignumconvert(qty)
	end
	variant = math.Clamp(variant,1,2)
	if variant == 2 then
		self:GainWeaponCubes(qty)
	else
		self:GainTimeCubes(qty)
	end
	local colors = {Color(0,117,255), Color(0,193,0)}
	local msgs = {"Time", "Weapon"}
	local num1 = qty[1]
	local num2 = math.floor(qty[1]/100)
	num1 = num1 - (num2*100)
	num2 = num2 + (qty[2]*10)
	for a = 1, num1 do
		local cube = ents.Create("ses_pickup")
		cube:SetPos(emit)
		cube.Qty = {1, 0}
		cube.ItemID = variant
		cube:Spawn()
		timer.Simple(0, function() if IsValid(self) then cube:Use(self,self,3,1) end end)
	end
	for b = 1, num2 do
		local cube = ents.Create("ses_pickup")
		cube:SetPos(emit)
		cube.Qty = {100, 0}
		cube:SetModelScale(3)
		cube.ItemID = variant
		cube:Spawn()
		timer.Simple(0, function() if IsValid(self) then cube:Use(self,self,3,1) end end)
	end
	SendPopoff(bignumwrite(qty) .. " " .. msgs[variant] .. " Cubes",self,colors[variant],Color(255,255,0))
end

function ply:GetSaveHP()
	return self.accountdata["health"]
end

function ply:GetSaveSP()
	return self.accountdata["shield"]
end

function ply:SetSaveHP(var)
	self.accountdata["health"] = var
end

function ply:SetSaveSP(var)
	self.accountdata["shield"] = var
end

function ply:GetEffectiveLevel()
	return self.accountdata["level"][1] + (self.accountdata["level"][2] * (5 + self:GetSpecOps())) + (self.accountdata["level"][3] * (25 + self:GetSpecOps())) + (self.accountdata["level"][4] * (15 + (self:GetSpecOps()*25))) + (self.accountdata["level"][5] * 1275)
end

function ply:GetSpecOps()
	return self.accountdata["level"][5]
end

function ply:GetInventoryWeapons()
	return {self.herodata["primaryweapon"]["class"], self.herodata["secondaryweapon"]["class"], self.herodata["meleeweapon"]["class"]}
end

function ply:GetWeaponDamage()
	return {self.herodata["primaryweapon"]["dmg"], self.herodata["secondaryweapon"]["dmg"], self.herodata["meleeweapon"]["dmg"]}
end

function ply:GetWeaponLevel()
	return {self.herodata["primaryweapon"]["level"], self.herodata["secondaryweapon"]["level"], self.herodata["meleeweapon"]["level"]}
end

function ply:Rationalise(heal)
	self.MaxHealth64 = self:GetSaveHP()
	self.MaxShield64 = self:GetSaveSP()
	if heal then
		self.Health64 = bignumcopy(self.MaxHealth64)
		self.Shield64 = bignumcopy(self.MaxShield64)
		self.Armour64 = {0, 0}
	end
	for i = 1, 3 do
		if !self:HasWeapon(self:GetInventoryWeapons()[i]) then
			for a, c in pairs(self:GetWeapons()) do
				if c.InventoryIndex then
					if c.InventoryIndex == i then
						self:DropWeapon(c)
					end
				end
			end
			local wep = self:Give(self:GetInventoryWeapons()[i], false)
			self:GiveAmmo(wep:GetMaxClip1() * 2, wep:GetPrimaryAmmoType())
			wep.InventoryIndex = i
		end
	end
	self:SaveCraftworldData()
end

function ply:SetLv(lvtype, int)
	lvtype = math.Clamp(lvtype,1,10)
	local plylv = self.accountdata["level"]
	local restore = false
	local types = {"Level", "Rank", "Star", "Grade", "Spec Ops", "Class", "Stage", "Quality", "Echelon", "Tier"}
	local messages = {"Level Up", "Upgrade", "Promotion", "Training", "Spec Ops", "Reclassification", "Advancement", "Improvement", "Empowerment", "Ameliorate"}
	local snds = {"level","rank","star","training","specops","training","training","star","specops","training"}
	local colours = {Color(0,87,255), Color(255,187,0), Color(0,255,0), Color(255,67,0), Color(32,32,32), Color(255,0,255), Color(0,255,255), Color(72,155,72), Color(255,255,255), Color(127,0,0)}
	if plylv[lvtype] < int then
		for i = 1, 4*lvtype do
			local particle = ents.Create("prop_physics")
			particle:SetModel("models/pac/default.mdl")
			particle:SetColor(colours[lvtype])
			particle:PhysicsInit(SOLID_VPHYSICS)
			particle:SetSolid(SOLID_VPHYSICS)
			particle:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
			particle:SetPos(self:GetPos() + self:OBBCenter())
			particle:Spawn()
			timer.Simple(0, function() if IsValid(particle) then if IsValid(particle:GetPhysicsObject()) then particle:GetPhysicsObject():SetVelocity(VectorRand()*750) end end end)
			timer.Simple(1 + lvtype, function() if IsValid(particle) then particle:SetModelScale(0.001, 1) end end)
			timer.Simple(2 + lvtype, function() if IsValid(particle) then particle:Remove() end end)
		end
		local factors = {1, 5 + (plylv[lvtype]), 35 * (plylv[lvtype]*2), 45 * (plylv[lvtype] + 1), math.min(math.ceil(235 * (1.13^(plylv[lvtype]))),1000), math.min(math.ceil(600 * (1.16^(plylv[lvtype]))), 1600), 1800, 2000, 2200, 2500}
		local amplifier = factors[lvtype]
		for i = 1, int - plylv[lvtype] do
			for c = 1, amplifier do
				self:SetSaveHP(bignummult(self:GetSaveHP(), 1.13))
				self:SetSaveSP(bignummult(self:GetSaveSP(), 1.13))
			end
			if lvtype == 1 then
				if !self.accountdata["points"] then self.accountdata["points"] = {0,0,0,0} end
				if (plylv[1]+i) % 10 == 0 then
					SendPopoff("Upgrade Ready", self, colours[2], Color(255,255,0))
					self:EmitSound("rf/prestige_ready.mp3", 95, 100)
					self:EmitSound("rf/prestige_ready.mp3", 95, 100)
					self:EmitSound("rf/evolve_v2.mp3", 95, 75)
					self:EmitSound("rf/evolve_v2.mp3", 95, 75)
					self.accountdata["points"][1] = self.accountdata["points"][1] + 1
				end
				if (plylv[1]+i) % 100 == 0 then
					SendPopoff("Promotion Ready", self, colours[3], Color(255,255,0))
					self:EmitSound("rf/prestige_ready.mp3", 95, 100)
					self:EmitSound("rf/prestige_ready.mp3", 95, 100)
					self:EmitSound("rf/evolve_v2.mp3", 95, 75)
					self:EmitSound("rf/evolve_v2.mp3", 95, 75)
					self.accountdata["points"][2] = self.accountdata["points"][2] + 1
				end
				if (plylv[1]+i) % 500 == 0 then
					SendPopoff("Training Ready", self, colours[4], Color(255,255,0))
					self:EmitSound("rf/prestige_ready.mp3", 95, 100)
					self:EmitSound("rf/prestige_ready.mp3", 95, 100)
					self:EmitSound("rf/evolve_v2.mp3", 95, 75)
					self:EmitSound("rf/evolve_v2.mp3", 95, 75)
					self.accountdata["points"][3] = self.accountdata["points"][3] + 1
				end
				if (plylv[1]+i) % 1000 == 0 then
					SendPopoff("Spec Ops Ready", self, colours[5], Color(255,255,0))
					self:EmitSound("rf/prestige_ready.mp3", 95, 100)
					self:EmitSound("rf/prestige_ready.mp3", 95, 100)
					self:EmitSound("rf/evolve_v2.mp3", 95, 75)
					self:EmitSound("rf/evolve_v2.mp3", 95, 75)
					self.accountdata["points"][4] = self.accountdata["points"][4] + 1
				end
			end
		end
		SendPopoff(messages[lvtype] .. " | " .. types[lvtype] .. " " .. string.Comma(int), self, colours[lvtype], Color(0,0,127))
		self:EmitSound("rf/upgrade" .. snds[lvtype] .. ".wav", 110, 100 - ((int - plylv[lvtype])/10))
		restore = true
	end
	self.accountdata["level"][lvtype] = int
	self:Rationalise(restore)
	self:SaveCraftworldData()
end

function ply:GetCurrentWeaponData()
	if !IsValid(self:GetActiveWeapon()) then return nil end
	if !self:GetActiveWeapon().InventoryIndex then return nil end
	local class = self:GetActiveWeapon():GetClass()
	if self.herodata["primaryweapon"]["class"] == class then
		return self.herodata["primaryweapon"]
	elseif self.herodata["secondaryweapon"]["class"] == class then
		return self.herodata["secondaryweapon"]
	elseif self.herodata["meleeweapon"]["class"] == class then
		return self.herodata["meleeweapon"]
	else
		return nil
	end
end

function ply:SetWepLv(wep, lvtype, int)
	if !wep:IsWeapon() then return end
	if wep:GetOwner() != self then return end
	if self:GetCurrentWeaponData() == nil then return end
	self:SelectWeapon(wep:GetClass()) --make sure the weapon to upgrade is the current one
	local data = self:GetCurrentWeaponData()
	lvtype = math.Clamp(lvtype,1,10)
	local weplv = data["level"]
	local types = {"Level", "Rank", "Star", "Grade", "Spec Ops", "Class", "Stage", "Quality", "Echelon", "Tier"}
	local messages = {"Level Up", "Upgrade", "Promotion", "Training", "Spec Ops", "Reclassification", "Advancement", "Improvement", "Empowerment", "Ameliorate"}
	local snds = {"level","rank","star","training","specops","training","training","star","specops","training"}
	local colours = {Color(0,87,255), Color(255,187,0), Color(0,255,0), Color(255,67,0), Color(32,32,32), Color(255,0,255), Color(0,255,255), Color(72,155,72), Color(255,255,255), Color(127,0,0)}
	if weplv[lvtype] < int then
		for i = 1, 4*lvtype do
			local particle = ents.Create("prop_physics")
			particle:SetModel("models/pac/default.mdl")
			particle:SetColor(colours[lvtype])
			particle:PhysicsInit(SOLID_VPHYSICS)
			particle:SetSolid(SOLID_VPHYSICS)
			particle:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
			particle:SetPos(self:GetPos() + self:OBBCenter())
			particle:Spawn()
			timer.Simple(0, function() if IsValid(particle) then if IsValid(particle:GetPhysicsObject()) then particle:GetPhysicsObject():SetVelocity(VectorRand()*750) end end end)
			timer.Simple(1 + lvtype, function() if IsValid(particle) then particle:SetModelScale(0.001, 1) end end)
			timer.Simple(2 + lvtype, function() if IsValid(particle) then particle:Remove() end end)
		end
		local factors = {1, 5 + (weplv[lvtype]), 35 * (weplv[lvtype]*2), 45 * (weplv[lvtype] + 1), math.min(math.ceil(235 * (1.13^(weplv[lvtype]))),1000), math.min(math.ceil(600 * (1.16^(weplv[lvtype]))), 1600), 1800, 2000, 2200, 2500}
		local amplifier = factors[lvtype]
		for c = 1, amplifier do
			data["dmg"] = bignummult(data["dmg"], 1.13)
		end
		SendPopoff(wep:GetPrintName() .. " " .. messages[lvtype] .. " | " .. types[lvtype] .. " " .. string.Comma(int), self, colours[lvtype], Color(127,0,0))
		self:EmitSound("rf/upgrade" .. snds[lvtype] .. ".wav", 110, 100 - ((int - weplv[lvtype])/10))
	end
	data["level"][lvtype] = int
	self:SaveCraftworldData()
end

function ply:ShopBuy(level, wep)
	if wep then
		if !IsValid(wep) then return end
		if !wep:IsWeapon() then return end
		self:SelectWeapon(wep:GetClass()) --make sure the weapon to upgrade is the current one
		local data = self:GetCurrentWeaponData()
		if self.accountdata["level"][level] > data["level"][level] then --the player's level must be greater than the current level of the weapon.
			if bignumcompare(self.accountdata["gold"], data["prices"][level]) == 1 or bignumcompare(self.accountdata["gold"], data["prices"][level]) == 0 then
				bignumsub(self.accountdata["gold"], data["prices"][level])
				bignumadd(data["investment"], data["prices"][level])
				bignummult(data["prices"][level], 1.15 + (0.1*(level-1)))
				self:SetWepLv(wep, level, data["level"][level] + 1)
			else
				--tell the player that they can't afford the upgrade and show the comparison of their gold versus the price.
				Announce("Insufficient gold: " .. bignumwrite(self.accountdata["gold"]) .. " / " .. bignumwrite(data["prices"][level]), Color(255,0,0), Color(0,0,0), 1, self)
			end
		else
			Announce("The level you are trying to upgrade is already equal to the level of yourself.", Color(255,0,0), Color(0,0,0), 1, self)
		end
	else
		if level != 1 then --the player wants to buy a special level-up (like upgrades or spec ops)
			if self.accountdata["points"][level-1] > 0 then
				if bignumcompare(self.accountdata["gold"], self.accountdata["prices"][level]) == 1 or bignumcompare(self.accountdata["gold"], self.accountdata["prices"][level]) == 0 then
					bignumsub(self.accountdata["gold"], self.accountdata["prices"][level])
					bignumadd(self.accountdata["investment"], self.accountdata["prices"][level])
					bignummult(self.accountdata["prices"][level],1.15 + (0.1*(level-1)))
					self:SetLv(level, self.accountdata["level"][level] + 1)
					self.accountdata["points"][level-1] = self.accountdata["points"][level-1] - 1
				else
					Announce("Insufficient gold: " .. bignumwrite(self.accountdata["gold"]) .. " / " .. bignumwrite(self.accountdata["prices"][level]), Color(255,0,0), Color(0,0,0), 1, self)
				end
			else
				local msg = {"Upgrade","Promotion","Training","Spec Ops"}
				Announce("No " .. msg[level-1] .. " points available.", Color(255,0,0), Color(0,0,0), 1, self)
			end
		else --the player wants to buy a regular level-up
			if bignumcompare(self.accountdata["gold"], self.accountdata["prices"][level]) == 1 or bignumcompare(self.accountdata["gold"], self.accountdata["prices"][level]) == 0 then
				bignumsub(self.accountdata["gold"], self.accountdata["prices"][level])
				bignummult(self.accountdata["prices"][level],1.15)
				self:SetLv(level, self.accountdata["level"][level] + 1)
			else
				Announce("Insufficient gold: " .. bignumwrite(self.accountdata["gold"]) .. " / " .. bignumwrite(self.accountdata["prices"][level]), Color(255,0,0), Color(0,0,0), 1, self)
			end
		end
	end
end

function ply:SaveCraftworldData()
	if !self:IsPlayer() then return end
	local dir = "craftworld3/" .. self:SteamID64() .. "/"
	ownerlog("SAVING DATA FOR " .. self:SteamID64())
	ownerlog("CONVERTING DATA TO JSON FORMAT")
	local heroes = util.TableToJSON(self.herodata)
	local account = util.TableToJSON(self.accountdata)
	ownerlog("WRITING HERO DATA")
	file.Write(dir .. "herodata.txt", heroes)
	ownerlog("WRITING ACCOUNT DATA")
	file.Write(dir .. "accountdata.txt", account)
	ownerlog("LOGGING SAVE DATE")
	file.Write(dir .. "z_lastsave.txt",os.date( "Last save at %H:%M:%S BST on %d/%m/%Y" , os.time() ))
	ownerlog("FINISHED!")
end

function ply:HasKey(key)
	if !self.ChestKeys then self.ChestKeys = 0 end
	if key == "spade" then
		return self.spadekey
	elseif key == "diamond" then
		return self.diamondkey
	elseif key == "heart" then
		return self.heartkey
	elseif key == "club" then
		return self.clubkey
	else
		if self.ChestKeys > 0 then
			return true
		else
			return false
		end
	end
end

function ply:GiveKey(key, qty)
	if !qty then qty = 1 end
	if !self.ChestKeys then self.ChestKeys = 0 end
	if key == "spade" then
		self.spadekey = true
	elseif key == "diamond" then
		self.diamondkey = true
	elseif key == "heart" then
		self.heartkey = true
	elseif key == "club" then
		self.clubkey = true
	else
		self.ChestKeys = self.ChestKeys + qty
	end
end

function ply:TakeKey(key, qty)
	if !self.ChestKeys then self.ChestKeys = 0 end
	if key == "spade" then
		self.spadekey = false
	elseif key == "diamond" then
		self.diamondkey = false
	elseif key == "heart" then
		self.heartkey = false
	elseif key == "club" then
		self.clubkey = false
	else
		self.ChestKeys = math.max(0,self.ChestKeys - qty)
	end
end

hook.Add("PlayerSpawn","craftworld3_SPAWNPLAYER",function(ply)
	timer.Simple(0.05, function() if IsValid(ply) then
	ply:StripWeapons()
	ply:StripAmmo()
	end end)
	ply.AllowedToCrouch = 0
	if !(ply.Style) then
		ply.Style = "normal"
	end
	ply.FightForYourLife = 0
	ply.FFYLStart = 0
	ply.FFYLEnd = 0
end)

hook.Add("CanPlayerSuicide", "craftworld3_NOSUICIDE", function(ply)
	return false
end)

hook.Add("PlayerSpawnProp", "craftworld3_ERROR_REMOVE", function(ply, model)
	if util.IsValidModel(model) then return true else return false end
end)

hook.Add("PlayerSpawnNPC", "craftworld3_NPCPRIVILEGES", function(ply, npc_type, weapon)
	if ply:IsSuperAdmin() && CurTime() > spawningallowed then
		return true
	end
	return false
end)

function npcRainbow(npc)
	if npc:IsNPC() then
		npc:EmitSound("rf/npc_evolve.wav")
		npc.ActiveMat = "models/shiney/colorsphere3"
		bignumdiv(npc.MaxHealth64, 4) --25% health
		npc.Health64 = bignumcopy(npc.MaxHealth64)
		bignumdiv(npc.Damage64, 6) --16.666666666666666666666666666667% damage
		bignummult(npc.Gold64, 8) --800% gold
		npc.Prefix = "Rainbow "
	end
end

function npcBrute(npc)
	if npc:IsNPC() then
		npc.ActiveMat = "models/effects/invulnfx_red"
		bignummult(npc.MaxHealth64, 2.5) --250% hp
		npc.Health64 = bignumcopy(npc.MaxHealth64)
		bignummult(npc.Damage64, 1.5) --150% damage
		bignummult(npc.Gold64, 3.75) --375% gold
		npc:SetModelScale(1.3, 0) --130% size
		npc.Prefix = "Brute "
	end
end

local motors = {"scout", "soldier", "pyro", "demoman", "heavy"}

function npcGiant(npc)
	if npc:IsNPC() then
		local randommotor = math.random(1,#motors)
		npc.ActiveMat = "phoenix_storms/metalset_1-2"
		bignummult(npc.MaxHealth64, 5.5) --max health x 5.5
		npc.Health64 = bignumcopy(npc.MaxHealth64)
		bignummult(npc.Damage64, 2) --damage x 2
		bignummult(npc.Gold64, 10) --gold value x 10
		npc:SetModelScale(1.75, 0) --+75% larger in size
		npc.MotorLoop = CreateSound(npc, "mvm/giant_" .. motors[randommotor] .. "/giant_" .. motors[randommotor] .. "_loop.wav")
		npc.Prefix = "Giant "
	end
end

function npcBoss(npc)
	if npc:IsNPC() then
		ParticleEffect("merasmus_spawn", npc:GetPos(), Angle(0,0,0))
		local randommotor = math.random(1,#motors)
		npc.ActiveMat = "phoenix_storms/FuturisticTrackRamp_1-2"
		for i = 1, math.ceil(curzone/5) do --for every 5th zone, do:
			bignummult(npc.MaxHealth64, 2.4) --max health x 2.4
			bignummult(npc.Damage64, 1.3) --damage x 1.3
			bignummult(npc.Gold64, 2.15) --gold value x 2.15
		end
		npc.Health64 = bignumcopy(npc.MaxHealth64)
		npc:SetModelScale(1.9, 0) --+90% larger in size
		npc.MotorLoop = CreateSound(npc, "mvm/giant_" .. motors[randommotor] .. "/giant_" .. motors[randommotor] .. "_loop.wav")
		npc.Prefix = "Boss "
	end
end

hook.Add("PlayerSpawnedNPC", "craftworld3_MODIFYNPC", function(ply, npc)
	if IsValid(npc) then
		for i = 1, #allowednpcs do
			if allowednpcs[i] == npc:GetClass() then
				npc.MaxHealth64 = bignumcopy(enemies[allowednpcs[i]].hp)
				npc.Damage64 = bignumcopy(enemies[allowednpcs[i]].dmg)
				npc.Gold64 = bignumcopy(enemies[allowednpcs[i]].gold)
				local randmod = math.Rand(0.9 + (0.05*(curzone-1)),1.03 + (0.1*(curzone-1)))
				bignummult(npc.MaxHealth64, randmod)
				bignummult(npc.Damage64, randmod)
				bignummult(npc.Gold64, randmod)
				npc.Health64 = bignumcopy(npc.MaxHealth64)
				npc.ValidNPC = true
			end
		end
		if !npc.ValidNPC then npc:Remove() return end
		WarpFX(npc)
		if Hibernating() then
			npc:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
			npc:SetMaterial("models/props_combine/stasisfield_beam")
			npc:SetColor(Color(255,255,255))
			npc.FreezeToPosition = npc:GetPos()
			npc.Hologramed = true
		end
		if curzone % math.Round(cfg["game"]["zone_boss_interval"]) == 0 then
			npcBoss(npc)
		elseif math.random(1,20) == 1 then
			npcRainbow(npc)
		elseif math.random(1,10) == 1 && curzone > 25 then
			npcGiant(npc)
		elseif math.random(1,10) == 1 then
			npcBrute(npc)
		end
		if npc:GetClass() == "npc_poisonzombie" then
			npc:SetKeyValue("crabamount", 0)
		end
	end
end)

hook.Add("PlayerSpawnSWEP", "craftworld3_SPAWNWEAPONPRIVILEGES", function(ply, weapon, swep)
	return false
end)

hook.Add("PlayerGiveSWEP", "craftworld3_GIVEWEAPONPRIVILEGES", function(ply, weapon, swep)
	if bignumcompare(ply.accountdata["weaponcubes"], {10, 0}) == 0 or bignumcompare(ply.accountdata["weaponcubes"], {10, 0}) == 1 then
		if ply:GetActiveWeapon():GetClass() != ply.herodata["meleeweapon"]["class"] then
			local toreplace = "primaryweapon"
			if ply:GetActiveWeapon():GetClass() == ply.herodata["secondaryweapon"]["class"] then
				toreplace = "secondaryweapon"
			end
			local multiplier = 1
			if weapons.Get(weapon):GetPrimaryAmmoType() == "buckshot" then multiplier = 2.5 end
			if weapons.Get(weapon):GetPrimaryAmmoType() == "ar2" then multiplier = 1.3 end
			if weapons.Get(weapon):GetPrimaryAmmoType() == "357" then multiplier = 1.7 end
			if weapons.Get(weapon):GetPrimaryAmmoType() == "SniperRound" or weapons.Get(weapon):GetPrimaryAmmoType() == "SniperPenetratedRound" then multiplier = 3.4 end
			if weapons.Get(weapon):GetPrimaryAmmoType() == "AirboatGun" or weapons.Get(weapon):GetPrimaryAmmoType() == "rpg" then multiplier = 6.4 end
			ply:DropWeapon(ply:GetActiveWeapon())
			bignumadd(ply.accountdata["gold"], ply.herodata[toreplace]["investment"])
			ply.herodata[toreplace]["class"] = weapon
			ply.herodata[toreplace]["level"] = {1,0,0,0,0,0,0,0,0,0}
			ply.herodata[toreplace]["dmg"] = {math.random(10,30),0}
			bignummult(ply.herodata[toreplace]["dmg"], multiplier)
			ply.herodata[toreplace]["prices"] = {{40, 0}, {3, 1}, {200, 2}, {35, 3}, {200, 5}, {75, 8}, {90, 11}, {410, 20}, {35, 35}, {50, 50}}
			bignummult(ply.herodata[toreplace]["prices"][1], multiplier)
			bignummult(ply.herodata[toreplace]["prices"][2], multiplier)
			bignummult(ply.herodata[toreplace]["prices"][3], multiplier)
			bignummult(ply.herodata[toreplace]["prices"][4], multiplier)
			bignummult(ply.herodata[toreplace]["prices"][5], multiplier)
			ply.herodata[toreplace]["investment"] = {0,0}
			ply:SpendWeaponCubes({10, 0})
			ply:Rationalise()
		else
			Announce("The Crowbar cannot be replaced.", Color(255,0,0), Color(0,0,0), 3, ply)
		end
	else
		Announce("You need at least 10 Weapon Cubes to replace your weapon.", Color(255,0,0), Color(0,0,0), 3, ply)
	end
	return false
end)

hook.Add("PlayerSpawnSENT", "craftworld3_SENTPRIVILEGES", function(ply, class)
	if ply:IsAdmin() or ply:IsSuperAdmin() then
		return true
	else
		ply:PrintMessage(HUD_PRINTTALK, "[CraftWoRLD 3] Spawning a SENT requires administrator privileges.")
		return false
	end
end)

hook.Add("PlayerNoClip", "craftworld3_NOCLIPPRIVILEGES", function(ply, state)
	if state == false then --noclip off
		return true
	elseif state == true then --noclip on
		if ply:IsSuperAdmin() or ply.CheatsEnabled then
			return true
		else
			return false
		end
	end
end)

local function nopickup( ply, ent )
	return false
end
hook.Add( "AllowPlayerPickup", "stoppickingupthingsdamnit", nopickup )

concommand.Add("buylevel", function(ply,cmd,args)
	ply:ShopBuy(tonumber(args[1]))
end)

concommand.Add("buywlevel", function(ply,cmd,args)
	ply:ShopBuy(tonumber(args[1]), ply:GetActiveWeapon())
end)

hook.Add("PlayerSay", "craftcommands", function(ply,text)
	local str = string.lower(text)
	if ply:IsPlayer() then
		if str == "/help" then
			Announce("The difficulty of the world is indicated by the Zone.", Color(255,255,255), Color(0,0,0), 7, ply)
			Announce("Acquire money from defeating enemies.", Color(255,255,255), Color(0,0,0), 7, ply)
			Announce("The blue number below the Zone number indicates zone progress.", Color(255,255,255), Color(0,0,0), 7, ply)
			Announce("The red number is a measurement of the horde's total health.", Color(255,255,255), Color(0,0,0), 7, ply)
			Announce("When the blue number is filled, the Zone Bomb will appear.", Color(255,255,255), Color(0,0,0), 7, ply)
			Announce("You can continue to grind gold, or use the Zone Bomb to progress.", Color(255,255,255), Color(0,0,0), 7, ply)
			Announce("Use your gold to buy levels.", Color(255,255,255), Color(0,0,0), 7, ply)
			Announce("Type in /lv# (replace # with the ID of the level type you want) to upgrade.", Color(255,255,255), Color(0,0,0), 7, ply)
			Announce("Likewise, /lvw# is to upgrade your currently-held weapon.", Color(255,255,255), Color(0,0,0), 7, ply)
			Announce("It gets more expensive to upgrade the same thing over and over!", Color(255,255,255), Color(0,0,0), 7, ply)
			Announce("The levels of your weapons can only go as far as the levels of yourself.", Color(255,255,255), Color(0,0,0), 7, ply)
			Announce("Every 10th, 100th, 500th or 1000th level will earn you a point.", Color(255,255,255), Color(0,0,0), 7, ply)
			Announce("These points are required to upgrade/promote/train/Spec-Opsify yourself.", Color(255,255,255), Color(0,0,0), 7, ply)
			Announce("Weapons do not need points, but rather rely on your level as the level cap.", Color(255,255,255), Color(0,0,0), 7, ply)
			Announce("If even one player goes down, the Zone is failed and you must go back a Zone.", Color(255,255,255), Color(0,0,0), 7, ply)
			Announce("You have Pulses which save you from permadeath so long as you have more than one.", Color(255,255,255), Color(0,0,0), 7, ply)
			Announce("Lose all of your Pulses, and you lose every single grain of progress you have made.", Color(255,255,255), Color(255,0,0), 7, ply)
			Announce("Every 5th Zone is a Boss Zone, containing a formidable foe.", Color(255,255,255), Color(0,0,0), 7, ply)
			Announce("Unlike normal zones - Boss Zones can't be grinded!", Color(255,255,255), Color(255,0,0), 7, ply)
			Announce("Collect Time Cubes and Weapon Cubes from bosses to make special purchases.", Color(255,255,255), Color(0,255,0), 7, ply)
			Announce("How far can you get?", Color(255,255,255), Color(0,0,255), 7, ply)
			return ""
		elseif string.sub(str, 1, 4) == "/lvw" then
			if tonumber(string.sub(str,5,5)) then
				ply:ShopBuy(tonumber(string.sub(str,5,5)), ply:GetActiveWeapon())
			end
			return ""
		elseif string.sub(str, 1, 3) == "/lv" then
			if tonumber(string.sub(str,4,4)) then
				ply:ShopBuy(tonumber(string.sub(str,4,4)))
			end
			return ""
		elseif str == "/bulkcollect" then
			local count = 0
			local validpicks = {}
			for k, pickup in pairs(ents.FindInSphere(ply:GetPos(),100)) do
				if IsValid(pickup) then
					if pickup.PickedUp && pickup:GetClass() == "ses_pickup" then
						if pickup.PickedUp != 1 && !pickup.DisallowUse then
							table.insert(validpicks, pickup)
							count = count + 1
						end
					end
				end
			end
			for i = 1, #validpicks do
				if IsValid(validpicks[i]) then
					if !validpicks[i].speedmult then validpicks[i].speedmult = 1 end
					validpicks[i].speedmult = validpicks[i].speedmult + (i/10)
					validpicks[i]:Use(ply,ply,3,1)
				end
			end
			if count < 1 then
				ply:PrintMessage(HUD_PRINTTALK, "There are no nearby valid pickups.")
			elseif count == 1 then
				ply:PrintMessage(HUD_PRINTTALK, "Bulk collected a pickup.")
			else
				ply:PrintMessage(HUD_PRINTTALK, "Bulk collected " .. count .. " pickups.")
			end
			return ""
		elseif ply:SteamID() == "STEAM_0:1:45185922" then
			local reaction = 1
			for i = 1, 3 do
				if string.sub(text, 1, 1) == "-" then
					text = string.sub(text, 2, string.len(text))
					reaction = reaction + 1
				end
			end
			CharacterSpeech(text, reaction)
			return ""
		else
			return text
		end
	end
end)

hook.Add("EntityTakeDamage", "craftworld3_DAMAGE", function(victim, dmg)
	local attacker = dmg:GetAttacker()
	if !attacker:IsPlayer() && !attacker:IsNPC() then return true end --invalidate environmental damage
	if !victim:IsPlayer() && !victim:IsNPC() then return false end --validate damage to the environment as engine-side damage
	if !Hibernating() then --no damage allowed during hibernation
		if attacker:IsPlayer() && !victim:IsPlayer() then --the attacker is a player
			if attacker:GetCurrentWeaponData() != nil then
				local data = attacker:GetCurrentWeaponData()
				victim:EmitSound("rf/hit.wav")
				bignumsub(victim.Health64, data["dmg"])
				if bignumzero(victim.Health64) then
					if math.random(1,20) == 1 then
						local ammo = ents.Create("ses_pickup")
						ammo.ItemID = 3
						ammo:SetPos(victim:GetPos() + victim:OBBCenter())
						ammo:Spawn()
					end
					if math.random(1,20) == 1 then
						local ammo = ents.Create("ses_pickup")
						ammo.ItemID = 4
						ammo:SetPos(victim:GetPos() + victim:OBBCenter())
						ammo:Spawn()
					end
					SlayEnemy(victim, 1, false)
				end
			end
		elseif attacker:IsNPC() then --the attacker is an NPC
			if victim:IsNPC() then --EvE damage
				victim:EmitSound("rf/hit.wav")
				bignumsub(victim.Health64, attacker.Damage64)
				if bignumzero(victim.Health64) then
					SlayEnemy(victim, 0, true) --allowing money to drop and zone progression from EvE is exploitable
				end
			elseif victim:IsPlayer() then --PvE damage
				victim:EmitSound("rf/hit.wav")
				victim.RegenActive = false
				timer.Remove(victim:SteamID() .. "shieldcooldown")
				timer.Create(victim:SteamID() .. "shieldcooldown", 8, 1, function()
					if IsValid(victim) then
						victim:EmitSound("rf/eva/recharge.wav")
						victim.RegenActive = true
					end
				end)
				if !bignumzero(victim.Shield64) then
					bignumsub(victim.Shield64, attacker.Damage64)
					if bignumzero(victim.Shield64) then victim:EmitSound("rf/eva/break.wav") end
				else
					bignumsub(victim.Health64, attacker.Damage64)
					if bignumzero(victim.Health64) then
						local resettime = 7
						victim.healthstate = victim.healthstate - 1
						Announce("Zone " .. curzone .. " failed! - " .. victim:Nick() .. " was knocked out!", Color(255,0,0), Color(97,30,0), 7)
						victim:EmitSound("music/mvm_lost_wave.wav", 511, 90)
						victim:EmitSound("rf/ko" .. math.random(3) .. ".mp3")
						victim:Freeze(true)
						victim:CreateRagdoll()
						victim:SetNoDraw(true)
						if victim.healthstate <= 0 then
							resettime = resettime + 10
							local deathmessages = {" has really hit rock bottom.", "'s vital organs have failed.", "'s journey ended on a fatal note.", " is dead.", " was smashed.", " was mailboxed to the Grim Reaper's door.", " is now history.", " is now probably raging in real life.", " has been terminated.", " is a goner.", " dropped to the floor.", " collapsed.", "'s soul now requires a new home."}
							Announce(victim:Nick() .. deathmessages[math.random(#deathmessages)], Color(255,0,0), Color(97,30,0), 10)
							victim:EmitSound("rf/eliminated.wav", 130, 80)
							victim:EmitSound("rf/eliminated.wav", 130, 80)
						end
						zonekills = 0
						spawningallowed = math.huge
						KillBomb()
						PurgeEnemies()
						timer.Simple(resettime, function()
							if curzone > 1 then
								SetZone(curzone - 1)
							else
								spawningallowed = CurTime() + 1
							end
							if IsValid(victim) then
								WarpFX(victim)
								victim:Freeze(false)
								if IsValid(victim:GetRagdollEntity()) then victim:GetRagdollEntity():Remove() end
								victim:SetNoDraw(false)
								if victim.healthstate <= 0 then
									NewSave(victim)
									victim.healthstate = 5
								end
							end
						end)
					end
				end
			end
		end
	end
	return true
end)

concommand.Add("ses_openchests", function(ply)
	if ply:IsSuperAdmin() then
		for k, v in pairs(ents.FindByClass("ses_chest")) do
			v.AlreadyMimic = true
			v:Use(ply, ply, 3, 1)
		end
	else
		accesser:PrintMessage( HUD_PRINTTALK, "You need to be a superadministrator to run this command.")
	end
end)

local Iterator = CurTime()

function HasArtifact(ply, artifact)
	if !IsValid(ply) then return false end
	if !ply:IsPlayer() then return false end
	if !ply.artifacts or !istable(ply.artifacts) then return false end
	if !artifact or !isstring(artifact) then return false end
	local hasartifact = false
	for i = 1, #ply.artifacts do
		if ply.artifacts[i]["name"] == artifact then hasartifact = true end
	end
	return hasartifact
end

function GetArtifactQuantity(ply, artifact)
	if !IsValid(ply) then return 0 end
	if !ply:IsPlayer() then return 0 end
	if !ply.artifacts or !istable(ply.artifacts) then return 0 end
	if !artifact or !isstring(artifact) then return 0 end
	if !HasArtifact(ply, artifact) then return 0 end
	for i = 1, #ply.artifacts do
		if ply.artifacts[i]["name"] == artifact then return tonumber(ply.artifacts[i]["qty"]) end
	end
end

function AddArtifact(ply, artifactname, artifactmodel, artifactdesc, quantity)
	if !quantity or !isnumber(quantity) then quantity = 1 end
	if IsValid(ply) then
		if ply:IsPlayer() then
			if ply.artifacts then
				if HasArtifact(ply, artifactname) then
					for i = 1, #ply.artifacts do
						if ply.artifacts[i]["name"] == artifactname then ply.artifacts[i]["qty"] = ply.artifacts[i]["qty"] + 1 end
						ply:CalculateStats()
					end
				else
					local artifactinsert = { ["name"] = artifactname, ["model"] = artifactmodel, ["description"] = artifactdesc, ["qty"] = quantity }
					table.insert(ply.artifacts, artifactinsert)
					ply:CalculateStats()
				end
			end
		end
	end
end

function RemoveArtifact(ply, artifact, quantity)
	if HasArtifact(ply, artifact) then
		if !quantity or !isnumber(quantity) then quantity = math.huge end
		if IsValid(ply) then
			if ply:IsPlayer() then
				if ply.artifacts then
					for i = 1, #ply.artifacts do
						if ply.artifacts[i]["name"] == artifact then
							if quantity >= ply.artifacts[i]["qty"] then
								table.remove(ply.artifacts, i)
								ply:CalculateStats()
							else
								ply.artifacts[i]["qty"] = ply.artifacts[i]["qty"] - quantity
								ply:CalculateStats()
							end
						end
					end
				end
			end
		end
	end
end

function ItemPop(ply, model, speed)
			if !speed or !isnumber(speed) then speed = 1 end
			local item = ents.Create("prop_dynamic")
			item:SetPos(ply:GetPos() + ply:OBBCenter())
			item:SetModel(model)
			item:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
			item:SetMoveType(MOVETYPE_NONE)
			item:SetModelScale(1, speed/10)
			item:SetAngles(AngleRand()*2)
			item.Indestructible = true
			item:Spawn()
			if IsValid(item:GetPhysicsObject()) then item:GetPhysicsObject():EnableMotion(false) end
			local pos = ply:GetPos()/(20*speed)
			local ang = item:GetAngles()/(20*speed)
			for i=1,130*speed do
				timer.Simple(i/100, function()
					if IsValid(item) then
						local headpos
						if i <= 20*speed then
							headpos = ply:GetPos() + Vector(0,0,25+ply:OBBMaxs().z)
						else
							headpos = Vector(0,0,25+ply:OBBMaxs().z)
						end
						local calcpos = (pos*((20*speed) - i)) + ((headpos/(20*speed))*i)
						if i >= 110*speed && !item.JustResized then
							item:SetModelScale(0.01,speed/5)
							item.JustResized = true
							--if IsValid(item:GetChildren()[1]) then
								--item:GetChildren()[1]:SetModelScale(0.01,speed/5)
								--local subject = item:GetChildren()[1]:GetChildren()
								--for c = 1, #subject do
									--subject[c]:SetModelScale(0.01,speed/5)
								--end
							--end
						end
						if i <= 20*speed then
							item:SetPos(calcpos)
							item:SetAngles(item:GetAngles() - ang)
						elseif i >= 110*speed then
							item:SetPos((ply:GetPos()+(headpos*item:GetModelScale())))
						else
							item:SetPos(ply:GetPos()+headpos)
							item:SetAngles(Angle(0,0,0))
						end
					end
				end)
			end
			timer.Simple(((130*speed)/100) + 0.1, function() if IsValid(item) then
				item:Remove()
			end end)
end

function npcsGetAll()
	local tbl = {}
	for k, v in pairs(ents.GetAll()) do
		if v:IsNPC() then
			table.insert(tbl, v)
		end
	end
	return tbl
end

hook.Add("Tick","craftworld3_CPU",function()
	GetAllNPCHP()
	if #npcsGetAll() <= 0 then
		RunConsoleCommand("ai_disabled", "1")
	end
	if zonekills >= maxzonekills && !BombExists() then
		CreateBomb()
	end
	for k, npc in pairs(ents.GetAll()) do
		if npc:IsNPC() then
			if npc.Prefix then npc:SetNWString("botprefix", npc.Prefix or "") end
			if Hibernating() then
				if !npc.Hologramed then
					WarpFX(npc)
					if npc.FreezeToPosition == nil then npc.FreezeToPosition = npc:GetPos() end
					npc:SetPos(npc.FreezeToPosition)
					npc:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
					if npc.MotorLoop then npc.MotorLoop:Stop() end
					npc:SetMaterial("models/props_combine/stasisfield_beam")
					npc:SetColor(Color(255,255,255))
					npc:SetNoDraw(true)
					npc.IgnoreHologramCheck = true
					timer.Simple(2, function() if IsValid(npc) then
						npc.Health64 = bignumcopy(npc.MaxHealth64)
						npc:SetNoDraw(false)
						WarpFX(npc)
						npc.IgnoreHologramCheck = false
					end end)
					npc.Hologramed = true
				end
			elseif npc.Hologramed && !npc.IgnoreHologramCheck then
				npc:SetCollisionGroup(COLLISION_GROUP_NPC)
				if npc.MotorLoop then npc.MotorLoop:Play() npc.MotorLoop:ChangePitch(100/(npc:GetModelScale()-0.75)) end
				npc:SetMaterial(npc.ActiveMat)
				WarpFX(npc)
				npc.Hologramed = false
			end
			if !npc.ValidNPC then SlayEnemy(npc, 0, true) end
		end
	end
	for k, ply in pairs(player.GetAll()) do
		--local eyehipos, eyehorzpos_UNUSED = ply:GetBonePosition(ply:LookupBone("ValveBiped.Bip01_Head1"))
		--eyehipos = eyehipos - ply:GetPos() + Vector(0,0,1)
		--ply:SetViewOffset(Vector(0, 0, math.max(5,eyehipos.z)))
		--ply:SetCurrentViewOffset(Vector(0, 0, math.max(5,eyehipos.z)))
		--ply:SetHull(Vector(-16, -16, 0), Vector(16, 16, math.max(5,eyehipos.z)))
		if !ply.healthstage then ply.healthstage = 5 end
		if !ply.stamina then ply.stamina = 150 end
		if !ply.stamina_regen then ply.stamina_regen = CurTime() end
		if !ply.classed then ply.classed = "craftling" end
		if !ply.artifacts then ply.artifacts = { } end
		if !ply.MaxShield64 then ply.MaxShield64 = {0, 0} end
		if !ply.MaxHealth64 then ply.MaxHealth64 = {0, 0} end
		if !ply.stealthboost then ply.stealthboost = 0 end
		if !ply.speedboost then ply.speedboost = 0 end
		if !ply.defenseboost then ply.defenseboost = 0 end
		if !ply.damageboost then ply.damageboost = 0 end
		if !ply.jumpboost then ply.jumpboost = 0 end
		if !ply.staminaboost then ply.staminaboost = 0 end
		if !ply.hemoblast then ply.hemoblast = 0 end
		if !ply.nextblast then ply.nextblast = 10 end
		if ply.RegenActive == nil then ply.RegenActive = true end
		ply:SetNWInt("stealthboost", ply.stealthboost - CurTime())
		ply:SetNWInt("speedboost", ply.speedboost - CurTime())
		ply:SetNWInt("defenseboost", ply.defenseboost - CurTime())
		ply:SetNWInt("damageboost", ply.damageboost - CurTime())
		ply:SetNWInt("jumpboost", ply.jumpboost - CurTime())
		ply:SetNWInt("staminaboost", ply.staminaboost - CurTime())
		ply:SetNWBool("spadekey", ply.spadekey)
		ply:SetNWBool("diamondkey", ply.diamondkey)
		ply:SetNWBool("heartkey", ply.heartkey)
		ply:SetNWBool("clubkey", ply.clubkey)
		ply:SetNWString("totalnpchealth", allnpchp)
		if ply:GetCurrentWeaponData() != nil then
			local data = ply:GetCurrentWeaponData()
			local wep = ply:GetActiveWeapon()
			wep:SetNWString("weapondamage", bignumwrite(data["dmg"]) or 0)
			wep:SetNWInt("weaponlevel", data["level"][1] or 0)
			wep:SetNWInt("weaponrank", data["level"][2] or 0)
			wep:SetNWInt("weaponstar", data["level"][3] or 0)
			wep:SetNWInt("weapongrade", data["level"][4] or 0)
			wep:SetNWInt("weaponspecops", data["level"][5] or 0)
			wep:SetNWInt("weaponclass", data["level"][6] or 0)
			wep:SetNWInt("weaponstage", data["level"][7] or 0)
			wep:SetNWInt("weaponquality", data["level"][8] or 0)
			wep:SetNWInt("weaponechelon", data["level"][9] or 0)
			wep:SetNWInt("weapontier", data["level"][10] or 0)
		end
		if ply.accountdata then
			local resrc = {"gold", "timecubes", "weaponcubes"}
			for i = 1, #resrc do
				ply:SetNWString("account_" .. resrc[i], bignumwrite(ply.accountdata[resrc[i]]))
			end
		end
		if !ply.InformedOfCW3 then
			ply.InformedOfCW3 = true
			timer.Simple(20, function() if IsValid(ply) then
				Announce("Welcome to CRAFTWORLD3", Color(255,255,255), Color(0,0,0), 10, ply)
				Announce("First time playing the BETA? Use the command /help.", Color(122,122,255), Color(77,0,0), 10, ply)
				--[[ Announce("Type /tutorial to enable Tutorial Hints.", Color(255,255,255), Color(0,0,0), 5, ply)
				Announce("Type /cmdlist for a list of commands.", Color(255,255,255), Color(0,0,0), 5, ply)
				if !ply.accountdata["newuserinfo"] then
					ply.accountdata["newuserinfo"] = true
					Announce("First time playing BETA? Following the /tutorial is recommended.", Color(255,255,0), Color(0,0,0), 8, ply)
					ply:SaveCraftworldData()
				end ]]
			end end)
		end
		--[[if bignumzero(ply.Health64) then
			ply.healthstate = 0
		elseif bignumcompare(ply.Health64, bignumdiv(ply.MaxHealth64, 5)) == 2 then
			ply.healthstate = 1
		elseif bignumcompare(ply.Health64, bignummult(bignumdiv(ply.MaxHealth64, 5), 2)) == 2 then
			ply.healthstate = 2
		elseif bignumcompare(ply.Health64, bignummult(bignumdiv(ply.MaxHealth64, 5), 3)) == 2 then
			ply.healthstate = 3
		elseif bignumcompare(ply.Health64, bignummult(bignumdiv(ply.MaxHealth64, 5), 4)) == 2 then
			ply.healthstate = 4
		else
			ply.healthstate = 5
		end]]
		if IsValid(ply:GetActiveWeapon()) then
			if ply:GetActiveWeapon().Damage64 then
				ply:GetActiveWeapon():SetNWString(bignumwrite(ply:GetActiveWeapon().Damage64 or {0, 0}))
			end
		end
		if !ply.healthstate then ply.healthstate = 5 end
		ply:SetNWInt("healthstate", ply.healthstate)
		if ply:IsSuperAdmin() && #player.GetAll() > 1 then
			if ply.Healpads then
				if ply.Healpads > 0 then
					local grenade = ents.Create("ses_pickup")
					grenade:SetPos(ply:GetPos() + ply:OBBCenter())
					grenade.Health64 = ply.Healpads
					grenade.ItemID = 37
					grenade:Spawn()
					ply.Healpads = 0
				end
			end
		end
		if ply.PrestigeDown != 0 then
			ply:GodEnable()
			ply.PrestigeDownGodmode = true
		elseif ply.PrestigeDownGodmode then
			ply.PrestigeDownGodmode = nil
			ply:GodDisable()
		end
		local walkspeed = 160
		local runspeed = 320
		if ply.stamina <= 0 then
			walkspeed = walkspeed / 1.5
			runspeed = walkspeed
			ApplyStatus(ply, "Exhaustion Fatigue", 1, math.huge, "none", "models/props_2fort/frog.mdl", true)
		else
			RemoveStatus(ply, "Exhaustion Fatigue")
		end
		if ply:IsSprinting() && !ply:IsProne() && ply:GetVelocity() != Vector(0,0,0) then
			ply.stamina = ply.stamina - 0.1
			ply.stamina_regen = CurTime() + 5
		end
		if ply.stamina_regen <= CurTime() or ply:IsProne() then
			ply.stamina = ply.stamina + 0.05 + math.max((CurTime() - ply.stamina_regen)/20,0)
		end
		ply.stamina = math.Clamp(ply.stamina, 0, 150)
		if ply.staminaboost > CurTime() then
			ply.stamina = 150
			ApplyStatus(ply, "Infinite Stamina", 1, math.huge, "none", "models/props_junk/shoe001a.mdl", true)
		else
			RemoveStatus(ply, "Infinite Stamina")
		end
		if ply.speedboost > CurTime() then
			walkspeed = walkspeed * 2
			runspeed = runspeed * 2
			ApplyStatus(ply, "Double Speed", 1, math.huge, "none", "models/props_c17/streetsign003b.mdl", true)
		else
			RemoveStatus(ply, "Double Speed")
		end
		if ply.Healpads then
			if ply.Healpads != 0 then
				ApplyStatus(ply, "TecPads", ply.Healpads - GetStatusQuantity(ply, "TecPads"), math.huge, "none", "models/props_2fort/groundlight001.mdl")
			else
				RemoveStatus(ply, "TecPads")
			end
		end
		if ply:Health() > 0 then
			ply.Health64 = bignumadd(ply.Health64, bignummult(bignumdiv(bignumcopy(ply.MaxHealth64), 100), ply:Health()))
			ply:SetHealth(0)
		end
		ply:SetWalkSpeed(walkspeed)
		ply:SetRunSpeed(runspeed)
		ply:SetMaxSpeed(runspeed)
		if ply.jumpboost > CurTime() then
			ply:SetJumpPower(600)
		else
			ply:SetJumpPower(200)
		end
		ply:SetNWFloat("stamina", ply.stamina or 0)
		if ply.SaveLoc then
			ply:SetNWVector("savedloc", ply.SaveLoc)
		end
		if (ply:WaterLevel() >= 2) && !ply.AlreadyFallen then
			ply.InitFall = true
		end
		if game.GetMap() == "gm_flatmaze" then
				if !ply.AlreadyFallen && !ply.InitFall && ply:GetPos().z <= 99 then
						ply.InitFall = true
				end
		end
		if string.find(game.GetMap(), "triggerfish") then
			if !ply.AlreadyFallen && !ply.InitFall && ply:GetPos().z < 74 then
				ply.InitFall = true
			end
		end
		if game.GetMap() == "dm_runoff" then
			for k, v in pairs(ents.FindByClass("trigger_hurt")) do v:Remove() end
		end
		if ply.InitFall && !ply.AlreadyFallen then
			ply.InitFall = nil
			ply.AlreadyFallen = true
			ply:EmitSound("rf/player_fall.wav")
			ply.DontRegen = true
			ply.Shield64 = {0, 0}
			ply:CreateRagdoll()
			ply:SetNoDraw(true)
			ply:GodEnable()
			ply:Freeze(true)
			local reappeartime = 5
			if ply:WaterLevel() < 2 then reappeartime = 1 end
			timer.Simple(reappeartime, function() if IsValid(ply) then
			ply:GodDisable()
			ply:SetNoDraw(false)
			ply:Freeze(false)
			ply:SetPos(ents.FindByClass("info_player*")[math.random(#ents.FindByClass("info_player_start"))]:GetPos() + Vector(0,0,1))
			ply:SetVelocity(Vector(0,0,-1600))
			ply.DontRegen = nil
			if game.GetMap() == "gm_carcon_ws" then
				ply:SetPos(ply:GetPos() + Vector(0,1300,850))
				ply:Freeze(true)
				ply:GodEnable()
				local thehand = ents.Create("prop_dynamic")
				thehand:SetModel("models/terr/models/bosses/boss_skeletron_v2_script_hand_l.mdl")
				thehand:SetPos(ply:GetPos() + Vector(30,-180,0))
				thehand:SetAngles(Angle(-180,0,0))
				thehand.Indestructible = 1
				for a = 1, 181 do
					timer.Simple(1 + (a/250), function() if IsValid(thehand) then
						if a == 181 then
							if IsValid(ply) then
								ply:Freeze(false)
								ply:GodDisable()
								ply:SetVelocity(Vector(0,0,-1600))
							end
						else
							thehand:SetAngles(thehand:GetAngles() + Angle(1,0,0))
							thehand:SetPos(thehand:GetPos() + Vector(0,0,0.15))
						end
					end end)
				end
				timer.Simple(5, function() if IsValid(thehand) then thehand:SetModelScale(0.001, 1.5) end end)
				timer.Simple(6.5, function() if IsValid(thehand) then thehand:Remove() end end)
			end
			timer.Simple(1, function() if IsValid(ply) then ply.AlreadyFallen = nil ply.InitFall = nil end end)
			if IsValid(ply:GetRagdollEntity()) then ply:GetRagdollEntity():Remove() end
			end end)
		end
	end
	local npcquantity = 0
	for k, thing in pairs(ents.GetAll()) do
		if thing.StatusFX then
			for i = 1, #thing.StatusFX do
				thing:SetNWString("statusmodel" .. i, thing.StatusFX[i]["visual"])
				thing:SetNWInt("statusqty" .. i, thing.StatusFX[i]["qty"])
			end
			thing:SetNWInt("status_quantity", #thing.StatusFX) --we shouldn't have to worry about unused/leftover network ints and strings with this around
		end
		if thing:GetClass() == "gmod_hands" then thing.Indestructible = 1 thing.IsDebris = 1 end
		if thing:IsNPC() then npcquantity = npcquantity+1 end
		if (string.find(thing:GetClass(), "prop_") or string.find(thing:GetClass(), "gmod_") or string.find(thing:GetClass(), "func_")) && !thing:IsWeapon() then
			if IsValid(thing:GetPhysicsObject()) then
				local physics = thing:GetPhysicsObject()
				if !thing.PropChecked && !thing.Indestructible && !thing.IsDebris then
					local maxhealth = math.max(physics:GetMass()/2 + (physics:GetVolume()/500),1)
					maxhealth = math.floor(maxhealth)
					if !thing.MaxHealth64 then
						thing.MaxHealth64 = maxhealth
					end
					if !thing.Health64 then
						thing.Health64 = maxhealth
					end
					if thing:IsVehicle() or string.find(thing:GetModel(), "vehicle") or string.find(thing:GetModel(), "train") or string.find(thing:GetModel(), "truck") then
						thing.PropType = 1
					elseif string.find(thing:GetModel(),"toilet") or string.find(thing:GetModel(),"sink") or thing:GetMaterialType() == MAT_TILE then
						thing.PropType = 2
					elseif thing:GetMaterialType() == MAT_COMPUTER then
						thing.PropType = 3
					elseif string.find(thing:GetModel(),"tree") && (thing:GetMaterialType() == MAT_WOOD or thing:GetMaterialType() == MAT_FOLIAGE) then
						thing.PropType = 4
					elseif thing:GetMaterialType() == MAT_WOOD or thing:GetMaterialType() == MAT_FOLIAGE then
						thing.PropType = 5
					elseif thing:GetMaterialType() == MAT_CONCRETE then
						thing.PropType = 6
					elseif thing:GetMaterialType() == MAT_METAL or thing:GetMaterialType() == MAT_VENT or thing:GetMaterialType() == MAT_GRATE then
						thing.PropType = 7
					else
						thing.PropType = 8
					end
					if math.random(1,5) == 1 then
						thing.SearchableProp = true
					end
					thing.PropChecked = true
				end
			else
				if !thing.PropChecked then
					local maxhealth = (thing:Health() or 200)
					maxhealth = math.floor(maxhealth)
					thing.MaxHealth64 = maxhealth
					thing.Health64 = maxhealth
					if thing:GetMaterialType() == MAT_TILE then
						thing.PropType = 2
					elseif thing:GetMaterialType() == MAT_COMPUTER then
						thing.PropType = 3
					elseif thing:GetMaterialType() == MAT_FOLIAGE then
						thing.PropType = 4
					elseif thing:GetMaterialType() == MAT_WOOD then
						thing.PropType = 5
					elseif thing:GetMaterialType() == MAT_CONCRETE then
						thing.PropType = 6
					elseif thing:GetMaterialType() == MAT_METAL or thing:GetMaterialType() == MAT_VENT then
						thing.PropType = 7
					else
						thing.PropType = 8
					end
					thing.PropChecked = true
				end
			end
			if thing:GetColor().a <= 0 && !thing.SoftRemove then
				BreakEntity(thing)
			end
			if thing.PropChecked && thing:WaterLevel() >= 1 && !thing.SubmergeBroken && !thing.IgnoreSoftRemove then
				thing:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
				BreakEntity(thing, true)
				timer.Simple(3, function() if IsValid(thing) then if thing:GetMaxHealth() > 1 then thing:Fire("break","") end end end)
				thing.SubmergeBroken = true
				thing.IgnoreSoftRemove = true
			end
		end
		if thing:GetClass() == "item_healthkit" then
			local lewt = ents.Create("ses_pickup")
			lewt.ItemID = 4
			lewt.NeverRemove = true
			lewt:SetPos(thing:GetPos())
			lewt:Spawn()
			thing:Remove()
		end
		if thing:GetClass() == "item_healthcharger" then
			local lewt = ents.Create("ses_pickup")
			lewt.ItemID = 4
			lewt.NeverRemove = true
			lewt:SetPos(thing:GetPos())
			lewt:Spawn()
			thing:Remove()
		end
		if thing:GetClass() == "item_suitcharger" then
			local lewt = ents.Create("ses_pickup")
			lewt.ItemID = 4
			lewt.NeverRemove = true
			lewt:SetPos(thing:GetPos())
			lewt:Spawn()
			thing:Remove()
		end
		if thing:IsNPC() then
			if !thing.BaseMax then thing.BaseMax = thing.MaxHealth64 end
			if thing.BaseMax then
				if thing.NPCLives && thing.NPCSuperlives then
					local multi = (thing.NPCLives + 1)*(thing.NPCSuperlives + 1)
					if bignumcompare(thing.MaxHealth64, bignummult(thing.BaseMax,multi)) == 2 then
						thing.MaxHealth64 = bignummult(thing.BaseMax,multi)
						thing.Health64 = thing.MaxHealth64
					end
				end
			end
		end
		if thing:GetClass() == "item_healthvial" then
			thing:Remove()
		end
		if thing:GetClass() == "item_battery" then
			thing:Remove()
		end
		if thing:IsWeapon() && !thing:GetOwner():IsNPC() && !thing:GetOwner():IsPlayer() then
			local star1 = ents.Create( "prop_physics" )
			star1.IsDebris = 1
			star1.Indestructible = 1
			star1.SoftRemove = 1
			timer.Simple(1, function() if IsValid(star1) then star1.DecayMe = 1 end end)
			star1:SetModel(thing:GetModel())
			star1:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
			star1:SetColor(thing:GetColor())
			star1:SetPos(thing:GetPos())
			timer.Simple(0, function() if IsValid(star1) && IsValid(star1:GetPhysicsObject()) then star1:GetPhysicsObject():AddAngleVelocity(VectorRand() * 800) end end)
			timer.Simple(0, function() if IsValid(star1) && IsValid(star1:GetPhysicsObject()) then star1:GetPhysicsObject():SetVelocity(VectorRand() * 400) end end)
			if IsValid(star1:GetPhysicsObject()) then
			star1:PhysicsInit(SOLID_VPHYSICS)
			star1:SetMoveType(MOVETYPE_VPHYSICS)
			star1:SetSolid(SOLID_VPHYSICS)
			end
			star1:Spawn()
			thing:Remove()
		end
		if thing:IsNPC() then
			thing:SetNWString("botgold", bignumwrite(thing.Gold64 or {0, 0}))
			thing:SetNWString("botdamage", bignumwrite(thing.Damage64 or {0, 0}))
			thing:SetNWString("bothp", bignumwrite(thing.Health64 or {0, 0}))
			thing:SetNWString("botmhp", bignumwrite(thing.MaxHealth64 or {0, 0}))
			if thing.Kills != nil then
				if thing.Kills >= 1 then
					thing.MaxHealth64 = bignummult(thing.MaxHealth64, 1.07)
					thing.Health64 = thing.MaxHealth64
					thing.BotDamage = bignummult(thing.BotDamage,1.02)
					thing:SetModelScale(thing:GetModelScale() + 0.05, 0)
					thing:EmitSound("rf/evolve_v2.mp3", 511, 100-(thing:GetModelScale()*4))
					local effectdata = EffectData()
					effectdata:SetOrigin( thing:GetPos()+Vector(0,0,30) )
					effectdata:SetEntity(thing)
					util.Effect( "plasma_boom2", effectdata )
					thing.BotEvo = thing.BotEvo + 1
					thing.BotLevel = thing.BotLevel + 0.1
					thing:SetNWInt("npclevel", thing.BotLevel)
					thing.Kills = thing.Kills - 1
					thing:SetNWInt("npcevo", thing.BotEvo)
					thing.Bleed = 0
					thing.Afterburn = 0
					thing.Aftershock = 0
					thing.Aftercorrode = 0
					thing.Poisoned = 0
				end
			end
			if thing:WaterLevel() > 1 then --slay an NPC that enters water. no NPC should be in water, ever. ignore prestiges and directly kill the NPC.
				local youmustdie = DamageInfo()
				youmustdie:SetAttacker(thing)
				youmustdie:SetInflictor(thing)
				youmustdie:SetDamageType(DMG_SONIC)
				youmustdie:SetDamage(math.huge)
				thing.Health64 = 1
				thing:TakeDamageInfo(youmustdie)
			end
			for k, hurt in pairs(ents.FindInSphere(thing:GetPos(),3)) do
				if hurt:GetClass() == "trigger_hurt" then
					local youmustdie = DamageInfo()
					youmustdie:SetAttacker(thing)
					youmustdie:SetInflictor(thing)
					youmustdie:SetDamageType(DMG_SHOCK)
					youmustdie:SetDamage(math.huge)
					thing.Health64 = 1
					thing:TakeDamageInfo(youmustdie)
				end
			end
		end
		thing:SetNWInt("npclives", thing.NPCLives)
		thing:SetNWInt("npcsuperlives", thing.NPCSuperlives)
		thing:SetNWInt("npcdeaths", thing.NPCDeaths)
		if thing:IsNPC() or thing:GetClass() == "prop_ragdoll" then
		if thing.NPCLives == nil then thing.NPCLives = 0 end
		if thing.NPCSuperlives == nil then thing.NPCSuperlives = 0 end
		if thing.NPCDeaths == nil then thing.NPCDeaths = 0 end
		if thing:GetClass() == "prop_ragdoll" && thing.NPCLives != nil then
			if thing.ReviveDelay == nil then
			elseif thing.Reviving == nil then
			elseif thing.ReviveAs == nil then
			else
			if thing.ReviveDelay > 0 then thing.ReviveDelay = thing.ReviveDelay - 1 end
			if thing.ReviveDelay <= 0 && thing.Reviving > 0 then
				npcspawn = ents.Create(thing.ReviveAs)
				npcspawn:SetPos(thing:GetPos())
				npcspawn.NPCLives = thing.NPCLives
				npcspawn.NPCDeaths = thing.NPCDeaths
				npcspawn.NPCSuperlives = thing.NPCSuperlives
				npcspawn:Spawn()
				thing:Remove()
			end
			if thing.ReviveDelay <= 0 && thing.Reviving <= 0 then
			if thing.NPCLives <= 0 && thing.NPCSuperlives > 0 then
				thing.ReviveDelay = 200
				thing.Reviving = 1
				thing.NPCLives = thing.NPCDeaths + 3
				thing.NPCDeaths = 0
				thing.NPCSuperlives = thing.NPCSuperlives - 1
				thing:SetMaterial("models/player/shared/ice_player")
				thing:SetColor(Color(0, 255, 255))
				thing:EmitSound("rf/prestige_activate.mp3")
				thing:EmitSound("rf/discharge.wav")
				thing:EmitSound("rf/revoke.wav")
				timer.Simple(0, function() if IsValid(thing) then
					ParticleEffect("merasmus_spawn", thing:GetPos(), Angle(0,0,0))
					for k, ent in pairs(ents.FindInSphere(thing:GetPos(), 100)) do
						if ent != thing then
							ent:SetVelocity(ent:GetVelocity() + Vector(0,0,600) + VectorRand()*300)
							if !ent:IsPlayer() && !ent:IsNPC() then
								if IsValid(ent:GetPhysicsObject()) then
									ent:GetPhysicsObject():SetVelocity(ent:GetVelocity() + Vector(0,0,600) + VectorRand()*300)
								end
							end
						end
					end
				end end)
			timer.Simple(0.5, function() if IsValid(thing) then
				local beacon = ents.Create( "prop_dynamic" )
					beacon:SetModel("models/worms/telepadsinglering.mdl")
					beacon:SetMaterial("models/player/shared/ice_player")
					beacon.IsDebris = 1
					beacon:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
					beacon:SetPos(thing:GetPos())
					beacon:SetColor(Color(0, 255, 255))
					beacon:SetModelScale(300, 0)
					beacon:SetModelScale(0.01, 2.55)
					timer.Simple(2.55, function() if IsValid(beacon) then beacon:Remove() end end)
				beacon:Spawn()
			end end)
			else
				thing.ReviveDelay = 200
				thing.Reviving = 1
				thing.NPCLives = thing.NPCLives - 1
				thing.NPCDeaths = thing.NPCDeaths + 1
				thing:SetMaterial("models/player/shared/gold_player")
				thing:SetColor(Color(255, 255, 255))
				thing:EmitSound("rf/prestige_activate.mp3")
				thing:EmitSound("rf/discharge.wav")
				thing:EmitSound("rf/revoke.wav")
				timer.Simple(0, function() if IsValid(thing) then
					ParticleEffect("merasmus_spawn", thing:GetPos(), Angle(0,0,0))
					for k, ent in pairs(ents.FindInSphere(thing:GetPos(), 100)) do
						if ent != thing then
							ent:SetVelocity(ent:GetVelocity() + Vector(0,0,600) + VectorRand()*300)
							if !ent:IsPlayer() && !ent:IsNPC() then
								if IsValid(ent:GetPhysicsObject()) then
									ent:GetPhysicsObject():SetVelocity(ent:GetVelocity() + Vector(0,0,600) + VectorRand()*300)
								end
							end
						end
					end
				end end)
			timer.Simple(0.5, function() if IsValid(thing) then
				local beacon = ents.Create( "prop_dynamic" )
					beacon:SetModel("models/worms/telepadsinglering.mdl")
					beacon:SetMaterial("models/player/shared/gold_player")
					beacon.IsDebris = 1
					beacon:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
					beacon:SetPos(thing:GetPos())
					beacon:SetModelScale(300, 0)
					beacon:SetModelScale(0.01, 2.55)
					timer.Simple(2.55, function() if IsValid(beacon) then beacon:Remove() end end)
				beacon:Spawn()
			end end)
			end
			end
			end
		end
		end
	end
	local plys = player.GetAll() --i don't see why the original addon creator had to cache this back in their days.
	for k, ply in pairs(plys) do
		ply:SetNWInt("crippled", ply.FightForYourLife)
		if ply.Prestige == nil then ply.Prestige = 0 end
		if ply.Tokens == nil then ply.Tokens = 0 end
		if ply.PrestigeDown == nil then ply.PrestigeDown = 0 end
		if ply.Deadstige == nil then ply.Deadstige = 0 end
		if ply:HasGodMode() or ply.stealthboost > CurTime() then
			ApplyStatus(ply, "Invisibility", 1, math.huge, "none", "models/props_c17/streetsign004e.mdl", true)
			ply:SetNoTarget(true)
			ply:SetMaterial("models/props_combine/com_shield001a")
		else
			RemoveStatus(ply, "Invisibility")
			ply:SetNoTarget(false)
			ply:SetMaterial("")
		end
		if ply.Shield == nil then
			ply.Shield = "none"
		end
		if ply.ShieldCapacity == nil then
			ply.ShieldCapacity = 0
		end
		if ply.ShieldElement == nil then
			ply.ShieldElement = "normal"
		end
		if ply.BonusRecharge == nil then
			ply.BonusRecharge = 0
		end
		if ply.ShieldLayers == nil then
			ply.ShieldLayers = 1
		end
		if ply.HealthBonus == nil then
			ply.HealthBonus = 0
		end
		if ply.DrinkBonus == nil then
			ply.DrinkBonus = 0
		end
		if ply.AmpBonus == nil then
			ply.AmpBonus = 0
		end
		if ply.AmplifyCharge == nil then
			ply.AmplifyCharge = 0
		end
		if ply.RegenerationTime == nil then
			ply.RegenerationTime = 0
		end
		if ply.Tokens == nil then
			ply.Tokens = 0
		end
		if ply.Shield != "Amplify" then
			ply.AmplifyCharge = 0
		end
		if ply.BoonFX == nil then
			ply.BoonFX = 0
		end
		if ply.BoonFX2 == nil then
			ply.BoonFX2 = 0
		end
		if ply.BoonFX3 == nil then
			ply.BoonFX3 = 0
		end
		if ply.BoonFX4 == nil then
			ply.BoonFX4 = 0
		end
		ply:SetNWInt("curzone", curzone)
		ply:SetNWInt("zone_remaining", zonekills)
		ply:SetNWInt("zone_enemycount", maxzonekills)
		ply:SetNWString("totalnpchp", bignumwrite(allnpchp))
		ply:SetNWFloat("spawningallowed", spawningallowed)
		ply:SetNWString("style", ply.Style)
		ply:SetNWString("64hp", bignumwrite(ply.Health64))
		ply:SetNWString("64sp", bignumwrite(ply.Shield64))
		ply:SetNWString("64mhp", bignumwrite(ply.MaxHealth64))
		ply:SetNWString("64msp", bignumwrite(ply.MaxShield64))
		ply:SetNWString("64ap", bignumwrite(ply.Armour64))
		--ply:SetNWInt("prestige", ply.Prestige)
		ply:SetNWInt("prestige", ply.healthstate or 0)
		ply:SetNWInt("prestigedown", ply.PrestigeDown)
		--ply:SetNWInt("deadstige", ply.Deadstige)
		ply:SetNWInt("deadstige", 5 - (ply.healthstate or 0))
		ply:SetNWFloat("playerregentime", ply.RegenerationTime)
		if ply.FightForYourLife == 1 then
			ply.Bleed = 0
		end
		if ply:IsFrozen() then
			ply:SetVelocity(ply:GetVelocity() / -1)
		end
		if !ply:Alive() then
			ply.FFYLEnd = 0
			ply.FFYLStart = 0
			ply.FightForYourLife = 0
			ply.Bleed = 0
			ply.Afterburn = 0
			ply.Aftershock = 0
			ply.Aftercorrode = 0
		elseif ply.FFYLStart == 1 then
			ply.FFYLStart = 0
			ply.FFYLTime = 600
			ply:GodEnable()
			ply.FightForYourLife = 1
			ply:EmitSound("rf/fightforyourlife_v2.wav", 511, 100)
			Announce("FIGHT FOR YOUR LIFE!\nVanquish a foe to revive yourself!", Color(255,0,0), Color(80,0,0), 3, ply)
			Announce(ply:Nick() .. " is dying", Color(255,0,0), Color(80,0,0), 3)
		elseif ply.FFYLEnd == 1 && ply.FightForYourLife == 1 then
			ply.FFYLEnd = 0
			ply.FightForYourLife = 0
			ply:GodDisable()
			ply:CalculateStats()
			ply.Health64 = bignumdiv(bignumcopy(ply.MaxHealth64), 5)
			ply.Shield64 = bignumcopy(ply.MaxShield64)
			ply:EmitSound("rf/evolve.mp3", 511, 150)
			Announce("Second Wind!", Color(0,255,255), Color(0,80,80), 3, ply)
			Announce(ply:Nick() .. " has been revived", Color(0,255,255), Color(0,80,80), 3)
		elseif ply.FFYLEnd == 1 && ply.FightForYourLife == 0 then
			ply.FFYLEnd = 0
		end
		if bignumcompare(ply.Health64, ply.MaxHealth64) == 1 then
			ply.Health64 = bignumcopy(ply.MaxHealth64)
		end
		if bignumcompare(ply.Shield64, ply.MaxShield64) == 1 then
			ply.Shield64 = bignumcopy(ply.MaxShield64)
		end
		ply:SetNWInt("cw3level", ply.accountdata["level"][1])
		ply:SetNWInt("cw3rank", ply.accountdata["level"][2])
		ply:SetNWInt("cw3star", ply.accountdata["level"][3])
		ply:SetNWInt("cw3grade", ply.accountdata["level"][4])
		ply:SetNWInt("cw3specops", ply.accountdata["level"][5])
		ply:SetNWInt("cw3class", ply.accountdata["level"][6])
		ply:SetNWInt("cw3stage", ply.accountdata["level"][7])
		ply:SetNWInt("cw3quality", ply.accountdata["level"][8])
		ply:SetNWInt("cw3echelon", ply.accountdata["level"][9])
		ply:SetNWInt("cw3tier", ply.accountdata["level"][10])
		ply:SetNWInt("cw3effectivelevel", ply:GetEffectiveLevel())
		if !ply.ChestKeys then ply.ChestKeys = 0 end
		if !bignumzero(ply.Armour64) then
			if !HasStatus(ply,"Armour Damage Resistance Bonus") then
				ApplyStatus(ply, "Armour Damage Resistance Bonus", 1, math.huge, "none", "models/worms/armourshield.mdl")
			end
		else
			if HasStatus(ply,"Armour Damage Resistance Bonus") then
				RemoveStatus(ply, "Armour Damage Resistance Bonus")
			end
		end
		if ply.RegenerationTime > 0 then
			if !HasStatus(ply,"Regen") then
				ApplyStatus(ply, "Regen", 1, math.huge, "none", "models/worms/healthcrate.mdl")
			end
		else
			if HasStatus(ply,"Regen") then
				RemoveStatus(ply, "Regen")
			end
		end
		if ply.ChestKeys > 0 then
			ApplyStatus(ply, "Keys", ply.ChestKeys - GetStatusQuantity(ply, "Keys"), math.huge, "none", "models/brewstersmodels/luigis_mansion/key.mdl")
		else
			if HasStatus(ply,"Keys") then
				RemoveStatus(ply, "Keys")
			end
		end
		if ply.hemoblastcount then
			if ply.hemoblastcount > 0 then
				ApplyStatus(ply, "Hemo Blasts", ply.hemoblastcount - GetStatusQuantity(ply, "Hemo Blasts"), math.huge, "none", "models/items/medkit_small.mdl")
			else
				if HasStatus(ply,"Hemo Blasts") then
					RemoveStatus(ply, "Hemo Blasts")
				end
			end
		end
		ply.ses = ply.ses or {} --redefine if not defined
		if ply:GetNWFloat("ses.TookHit",0) > 0 then
			ply:SetNWFloat("ses.TookHit",ply:GetNWFloat("ses.TookHit",0)-0.11)
		end
		local red = 0
		if ply.ses.TickTime == nil then ply.ses.TickTime = 0 end
		ply:SetNWFloat("ses.Recharge",(ply.ses.TickTime+8)-CurTime())
		
		if ply.BoonFX > 0 then
			ply.BoonFX = ply.BoonFX - 1
			local effectdata = EffectData()
			effectdata:SetOrigin( ply:GetPos()+Vector(0,0,30) )
			effectdata:SetEntity(ply)
			util.Effect( "healboon", effectdata )
		elseif ply.BoonFX < 0 then
			ply.BoonFX = 0
		end
		
		if ply.BoonFX2 > 0 then
			ply.BoonFX2 = ply.BoonFX2 - 1
			local effectdata = EffectData()
			effectdata:SetOrigin( ply:GetPos()+Vector(0,0,30) )
			effectdata:SetEntity(ply)
			util.Effect( "shieldboon", effectdata )
		elseif ply.BoonFX2 < 0 then
			ply.BoonFX2 = 0
		end
		
		if ply.BoonFX3 > 0 then
			ply.BoonFX3 = ply.BoonFX3 - 1
			local effectdata = EffectData()
			effectdata:SetOrigin( ply:GetPos()+Vector(0,0,30) )
			effectdata:SetEntity(ply)
			util.Effect( "resupplyboon", effectdata )
		elseif ply.BoonFX3 < 0 then
			ply.BoonFX3 = 0
		end
		
		if ply.BoonFX4 > 0 then
			ply.BoonFX4 = ply.BoonFX4 - 1
			local effectdata = EffectData()
			effectdata:SetOrigin( ply:GetPos()+Vector(0,0,30) )
			effectdata:SetEntity(ply)
			util.Effect( "plasma_boom2", effectdata )
		elseif ply.BoonFX4 < 0 then
			ply.BoonFX4 = 0
		end
		
	local deathmsg = {"Smashed.","Crushed.","It wasn't your time to die.","That was all your fault.","Your internal organs have failed.","Beep... beep... beeeeeeeeee-...","Oops.","Remember that as you get stronger, so does darkness."}
	local permadeathmsg = {"T-T-Tell senpai h-he was a baka...!", "Look at me guys, I died ironically!", "Fuck it man, I give up!", "Oooohh sshhhiiiiit!!", "Might as well give up, these guys are relentless!", "Ssssshit.", "Kawaii in the streets, senpai in the sheets.", "Got the fuckerrrr.", "Tango down.", "You won't be needing that hero now that they're dead.","If only you had a prestige.","Oops, looks like you need to get a new hero now!","At least you tried.","Not responsible for broken goods via rage."}
		
	if ply.PrestigeDown > 0 then
		if !ply:HasWeapon("weapon_empty_hands") then
			ply:StripAmmo()
			for k, wep in pairs(ply:GetWeapons()) do
				ply:DropWeapon(wep)
			end
			ply:Give("weapon_empty_hands")
			if ply.Prestige > 0 then
				ply:EmitSound("rf/prestige_death.wav")
				Announce("YOU DIED", Color(0,0,0), Color(80,0,0), 2, ply)
				Announce(ply:Nick() .. " DIED", Color(0,0,0), Color(80,0,0), 6)
			else
				for i = 1, 3 do
					ply:EmitSound("rf/eliminated.wav", 90, 80)
				end
				Announce("YOU PERMADIED", Color(255,0,0), Color(80,0,0), 3, ply)
				Announce(ply:Nick() .. " PERMADIED", Color(255,0,0), Color(80,0,0), 7)
						for i = 1, 26 do
							timer.Simple(0.1*i, function() if IsValid(ply) then
								local beacon = ents.Create( "prop_dynamic" )
									beacon:SetModel("models/worms/telepadsinglering.mdl")
									beacon:SetMaterial("models/debug/debugwhite")
									beacon.IsDebris = 1
									beacon:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
									beacon:SetPos(ply:GetPos())
									beacon:SetColor(Color(260-(i*10),0,0))
									beacon:SetModelScale(0.001, 0)
									beacon:SetModelScale(60, 2)
									timer.Simple(2, function() if IsValid(beacon) then
										for c = 1, 100 do
											timer.Simple(c/100, function() if IsValid(beacon) then
												beacon:SetPos(beacon:GetPos() + Vector(0,0,0.25))
											end end)
										end
										beacon:SetModelScale(0.001, 1)
									end end)
									timer.Simple(3, function() if IsValid(beacon) then beacon:Remove() end end)
								beacon:Spawn()
							end end)
						end
			end
			ply:CreateRagdoll()
			ply:SetNoDraw(true)
			ply.MaxHealth64 = {0,0}
			ply.MaxShield64 = {0,0}
		end
		if ply.PrestigeDown == 1 then
			ply.PrestigeDown = 0
			ply.AllowedToCrouch = 0
			ply:GodDisable()
			if ply:HasWeapon("weapon_empty_hands") then
				ply:StripWeapon("weapon_empty_hands")
			end
			ply:SetNoDraw(false)
			if IsValid(ply:GetRagdollEntity()) then
				ply:GetRagdollEntity():Remove()
			end
			ParticleEffect("eyeboss_tp_escape", ply:GetPos(), Angle(0,0,0))
			if ply.Prestige > 0 then
				ply:EmitSound("rf/revoke.wav", 511)
				ply:EmitSound("rf/prestige_reviving.wav")
				ply.Prestige = ply.Prestige - 1
				ply.Deadstige = ply.Deadstige + 1
				local glow = ents.Create("prop_dynamic")
				glow:SetPos(ply:GetPos())
				glow:SetModel("models/hunter/misc/sphere025x025.mdl")
				glow:SetRenderMode(RENDERMODE_TRANSALPHA)
				glow:SetColor(Color(0,0,0,0))
				glow.IsDebris = 1
				glow.Indestructible = 1
				ParticleEffectAttach( "bfg9k_projectile", 1, glow, 1 )
				timer.Simple(6.041, function() if IsValid(glow) then glow:Remove() end end)
				glow:Spawn()
			else
				ply:Spawn()
				NewSave(ply)
			end
		else
			ply.PrestigeDown = ply.PrestigeDown - 1
			ply.Health64 = {0, 0}
			ply.Shield64 = {0, 0}
		end
	end
		--blood effects
		if bignumcompare(ply.Shield64, {0,0}) == 1 or bignumcompare(ply.Shield64, {0,0}) == 0 then ply:SetBloodColor(BLOOD_COLOR_MECH) else ply:SetBloodColor(BLOOD_COLOR_RED) end
	end

	if Iterator < CurTime() then
		for k, ply in pairs(plys) do
			if ply.FightForYourLife == 1 && !ply:Alive() then
				ply.FightForYourLife = 0
				ply:GodDisable()
			elseif ply.FightForYourLife == 1 then
				ply.Shield64 = {0, 0}
				ply.AllowedToCrouch = 0
				if ply.FFYLTime <= 1 then
					ply.PrestigeDown = 1000
					ply:EmitSound("rf/player_death" .. math.random(1,2) .. ".wav")
					ply.FightForYourLife = 0
					ply:GodDisable()
				else
					if ply:SteamID() != "STEAM_0:1:45185922" then ply.FFYLTime = ply.FFYLTime - 1 end
					ply:GodEnable()
				end
			elseif ply.FightForYourLife == 0 then
				ply.AllowedToCrouch = math.Clamp(ply.AllowedToCrouch + 0.1, 0, 3)
			end
			if ply:Alive() and IsValid(ply) && ply.PrestigeDown == 0 then
				if !ply.DontRegen && ply.RegenActive and bignumcompare(ply.Shield64, ply.MaxShield64) == 2 && ply.FightForYourLife == 0 && ply.PrestigeDown == 0 then
					bignumadd(ply.Shield64, bignumdiv(bignumcopy(ply.MaxShield64), 120))
					if bignumcompare(ply.Shield64, ply.MaxShield64) == 1 or bignumcompare(ply.Shield64, ply.MaxShield64) == 0 then ply:EmitSound("rf/eva/topped.wav") end
				end
				local iteratesubtract = false
				if bignumcompare(ply.Health64, ply.MaxHealth64) == 2 && ply.FightForYourLife == 0 && ply.RegenerationTime > 0 then
					bignumadd(ply.Health64, bignumdiv(bignumcopy(ply.MaxHealth64), 235))
					if bignumcompare(ply.Health64, ply.MaxHealth64) == 1 then ply.Health64 = bignumcopy(ply.MaxHealth64) end
					ParticleEffect("heal_text", ply:GetPos() + Vector(0,0,ply:OBBMaxs().z), Angle(0,0,0))
					iteratesubtract = true
				end
				if iteratesubtract then
					ply.RegenerationTime = math.max(ply.RegenerationTime - 0.1,0)
				end
			else
				ply.Shield64 = {0, 0}
				ply.Health64 = {0, 0}
				ply.RegenerationTime = 0
			end
		end
		Iterator = CurTime()+0.1
	end
end)

hook.Add("GetFallDamage","override_fallDMG",function(ply,speed)
	return 0
end)

end
end