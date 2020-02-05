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
				["boss_activatedelay_tooclose_range"] = 65.0,
				["true_craftling_mode"] = false,
				["anti_troll"] = true
			}
		}
	))
end
local cfg = file.Read(sdir .. "/cfg.txt", "DATA")
cfg = util.JSONToTable(cfg)

function cw3error(msg)
	PrintMessage(HUD_PRINTCENTER, "[!] CRAFTWORLD3 is creating errors. [!]")
	PrintMessage(HUD_PRINTTALK, "[CRAFTWORLD3 Error] " .. tostring(msg))
	error("[CRAFTWORLD3 Error] " .. tostring(msg))
end

function GetAmpFactor()
	return {cfg["game"]["zone_npc_powerscale_factor"], cfg["game"]["zone_npc_powerscale_factor_increment"]}
end

--True Craftling Mode
--Automatic power scaling for NPCs and other various gameplay changes.
function TrueCraftling()
	return cfg["game"]["true_craftling_mode"]
end

--Anti-Griefing
--Stops mischevious players from trolling the game's logic by using countermeasures.
function AntiGriefing()
	return cfg["game"]["anti_troll"] or true
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
local maxzonekills = math.min(math.floor(cfg["game"]["zone_npc_basecount"] * cfg["game"]["zone_npc_exponent"]), 30) --number of kills needed to progress to the next zone
local spawningallowed = CurTime() --admins are only allowed to spawn things when CurTime() is larger than this variable.
local allnpchp = {0, 0}
local autostart = CurTime() + cfg["game"]["wave_autostart"]
local rainbowchestvalue = {900, 0}
local zonebonus = {300, 0}
local timeuntilnextchest = CurTime() + 600
local capsulechance = 1

local listenemies = {}
listenemies["npc_zombie"] = {hp = bignumread("65"), dmg = bignumread("30"), gold = bignumread("35"), playerscale = 1}
listenemies["npc_fastzombie"] = {hp = bignumread("40"), dmg = bignumread("10"), gold = bignumread("50"), playerscale = 0.9}
listenemies["npc_zombie_torso"] = {hp = bignumread("55"), dmg = bignumread("16"), gold = bignumread("28"), playerscale = 0.8}
listenemies["npc_fastzombie_torso"] = {hp = bignumread("35"), dmg = bignumread("8"), gold = bignumread("31"), playerscale = 0.75}
listenemies["npc_poisonzombie"] = {hp = bignumread("300"), dmg = bignumread("92"), gold = bignumread("115"), playerscale = 1.1}
listenemies["npc_headcrab"] = {hp = bignumread("25"), dmg = bignumread("9"), gold = bignumread("13"), playerscale = 0.3}
listenemies["npc_headcrab_fast"] = {hp = bignumread("13"), dmg = bignumread("6"), gold = bignumread("9"), playerscale = 0.23}
listenemies["npc_headcrab_black"] = {hp = bignumread("100"), dmg = bignumread("130"), gold = bignumread("90"), playerscale = 0.5}
listenemies["npc_antlion"] = {hp = bignumread("450"), dmg = bignumread("48"), gold = bignumread("200"), playerscale = 1.65}
listenemies["npc_antlionguard"] = {hp = bignumread("1.9K"), dmg = bignumread("750"), gold = bignumread("2.75K"), playerscale = 4}
listenemies["npc_combine_s"] = {hp = bignumread("400"), dmg = bignumread("13"), gold = bignumread("195"), playerscale = 0.8}
listenemies["npc_metropolice"] = {hp = bignumread("300"), dmg = bignumread("11"), gold = bignumread("137"), playerscale = 0.9}
listenemies["npc_manhack"] = {hp = bignumread("80"), dmg = bignumread("20"), gold = bignumread("100"), playerscale = 0.2}
listenemies["npc_rollermine"] = {hp = bignumread("1K"), dmg = bignumread("80"), gold = bignumread("1.2K"), playerscale = 0.5}
listenemies["npc_antlion_worker"] = {hp = bignumread("833"), dmg = bignumread("36"), gold = bignumread("600"), playerscale = 1.35}

local enemies = listenemies

local zoneclear = false

local allowednpcs = {"npc_zombie", "npc_fastzombie", "npc_zombie_torso", "npc_fastzombie_torso", "npc_poisonzombie", "npc_headcrab", "npc_headcrab_fast", "npc_headcrab_black", "npc_antlion", "npc_antlionguard", "npc_combine_s", "npc_metropolice", "npc_manhack", "npc_rollermine", "npc_antlion_worker"}

local weaponevos = {}
weaponevos["tfa_cso_m4a1"] = {"tfa_cso_m4a1red", "tfa_cso_m4a1g", "tfa_cso_m4a1gold", "tfa_cso_m4a1dragon", "tfa_cso_darkknight", "tfa_cso_darkknight_v6", "tfa_cso_darkknight_v8"}
weaponevos["tfa_cso_m60"] = {"tfa_cso_m60g", "tfa_cso_m60_v6", "tfa_cso_m60_v8", "tfa_cso_m60craft"}
weaponevos["tfa_cso_m95"] = {"tfa_cso_m95_expert", "tfa_cso_m95_master", "tfa_cso_m95ghost", "tfa_cso_m95tiger"}
weaponevos["tfa_cso_magnumdrill"] = {"tfa_cso_magnumdrill_expert"}
weaponevos["tfa_cso_mg3"] = {"tfa_cso_mg3g", "tfa_cso_mg3_v6", "tfa_cso_mg3_v8"}
weaponevos["tfa_cso_pkm"] = {"tfa_cso_pkm_gold", "tfa_cso_pkm_expert", "tfa_cso_pkm_master"}
weaponevos["tfa_cso_mp7a1"] = {"tfa_cso_mp7a160r", "tfa_cso_mp7unicorn"}
weaponevos["tfa_cso_groza"] = {"tfa_cso_groza_expert", "tfa_cso_groza_master"}
weaponevos["tfa_cso_plasmagun"] = {"tfa_cso_plasmagun_v6"}
weaponevos["tfa_cso_m24"] = {"tfa_cso_xm2010", "tfa_cso_xm2010_v6", "tfa_cso_xm2010_v8"}
weaponevos["tfa_cso_rpg7"] = {"tfa_cso_rpg7_v6", "tfa_cso_rpg7_v8"}
weaponevos["tfa_cso_m82"] = {"tfa_cso_m82_v6", "tfa_cso_m82_v8"}
weaponevos["tfa_cso_newcomen"] = {"tfa_cso_newcomen_v6"}
weaponevos["tfa_cso_mk3a1"] = {"tfa_cso_mk3a1_flame"}
weaponevos["tfa_cso_desperado"] = {"tfa_cso_desperado_v6"}
weaponevos["tfa_cso_runebreaker"] = {"tfa_cso_runebreaker_expert"}
weaponevos["tfa_cso_skull1"] = {"tfa_cso_skull2", "tfa_cso_skull3_a", "tfa_cso_skull3_b", "tfa_cso_skull4", "tfa_cso_skull5", "tfa_cso_skull6", "tfa_cso_m249ex", "tfa_cso_skull8", "tfa_cso_skull9"}
weaponevos["tfa_cso_sl8"] = {"tfa_cso_sl8g", "tfa_cso_sl8ex"}
weaponevos["tfa_cso_spas12"] = {"tfa_cso_spas12ex", "tfa_cso_spas12exb", "tfa_cso_spas12superior", "tfa_cso_spas12maverick"}
weaponevos["tfa_cso_starchaserar"] = {"tfa_cso_starchasersr"}
weaponevos["tfa_cso_scout"] = {"tfa_cso_scout_red"}
weaponevos["tfa_cso_stg44"] = {"tfa_cso_stg44g", "tfa_cso_stg44_expert", "tfa_cso_stg44_master"}
weaponevos["tfa_cso_trg42"] = {"tfa_cso_trg42g"}
weaponevos["tfa_cso_savery"] = {"tfa_cso_savery_v6"}
weaponevos["tfa_cso_thompson_chicago"] = {"tfa_cso_thompson_gold", "tfa_cso_thompson_expert", "tfa_cso_thompson_master"}
weaponevos["tfa_cso_thunderbolt"] = {"tfa_cso_thunderbolt_v6"}
weaponevos["tfa_cso_tmp"] = {"tfa_cso_tmpdragon"}
weaponevos["tfa_cso_uts15"] = {"tfa_cso_uts15g", "tfa_cso_uts15_v6", "tfa_cso_uts15_v8"}
weaponevos["tfa_cso_turbulent1"] = {"tfa_cso_turbulent3", "tfa_cso_turbulent5", "tfa_cso_turbulent7", "tfa_cso_turbulent11"}
weaponevos["tfa_cso_thanatos1"] = {"tfa_cso_thanatos3", "tfa_cso_thanatos5", "tfa_cso_thanatos7", "tfa_cso_thanatos9", "tfa_cso_thanatos11"}
weaponevos["tfa_cso_vulcanus1_a"] = {"tfa_cso_vulcanus1_b", "tfa_cso_vulcanus3", "tfa_cso_vulcanus5", "tfa_cso_vulcanus7", "tfa_cso_vulcanus11"}
weaponevos["tfa_cso_wa2000"] = {"tfa_cso_wa2000_gold", "tfa_cso_wa2000_expert", "tfa_cso_wa2000_master"}
weaponevos["tfa_cso_m1887"] = {"tfa_cso_m1887_gold", "tfa_cso_m1887_expert", "tfa_cso_m1887_master"}
weaponevos["tfa_cso_xm8"] = {"tfa_cso_xm8_sharpshooter"}
weaponevos["tfa_cso_lycanthrope"] = {"tfa_cso_lycanthrope_expert"}
weaponevos["tfa_cso_mg36"] = {"tfa_cso_mg36g"}
weaponevos["tfa_cso_m249"] = {"tfa_cso_m249_xmas", "tfa_cso_m249camo", "tfa_cso_m249ep", "tfa_cso_m249phoenix"}
weaponevos["tfa_cso_m2"] = {"tfa_cso_m2_v6", "tfa_cso_m2_v8"}
weaponevos["tfa_cso_luger"] = {"tfa_cso_luger_gold", "tfa_cso_luger_expert", "tfa_cso_luger_master", "tfa_cso_luger_silver", "tfa_cso_luger_legacy"}
weaponevos["tfa_cso_at4"] = {"tfa_cso_at4ex"}
weaponevos["tfa_cso_m14ebr"] = {"tfa_cso_m14ebrg", "tfa_cso_m14ebr_expert", "tfa_cso_m14ebr_master"}
weaponevos["tfa_cso_m16a1"] = {"tfa_cso_m16a1ep"}
weaponevos["tfa_cso_kingcobra"] = {"tfa_cso_kingcobragold", "tfa_cso_kingcobra_v6", "tfa_cso_kingcobra_v8"}
weaponevos["tfa_cso_ksg12"] = {"tfa_cso_ksg12_gold", "tfa_cso_ksg12_expert", "tfa_cso_ksg12_master"}
weaponevos["tfa_cso_hk121"] = {"tfa_cso_hk121_custom"}
weaponevos["tfa_cso_hk23"] = {"tfa_cso_hk23g", "tfa_cso_hk23_expert", "tfa_cso_hk23_master"}
weaponevos["tfa_cso_gungnir_nrm"] = {"tfa_cso_gungnir"}
weaponevos["tfa_cso_hk_g11"] = {"tfa_cso_g11g", "tfa_cso_g11_v6", "tfa_cso_g11_v8"}
weaponevos["tfa_cso_gilboa"] = {"tfa_cso_gilboa_viper"}
weaponevos["tfa_cso_glock"] = {"tfa_cso_glock_red"}
weaponevos["tfa_cso_p90"] = {"tfa_cso_pchan"}
weaponevos["tfa_cso_mk48"] = {"tfa_cso_mk48_expert", "tfa_cso_mk48_master"}
weaponevos["tfa_cso_m79"] = {"tfa_cso_m79_gold"}
weaponevos["tfa_cso_usp"] = {"tfa_cso_usp_red"}
weaponevos["tfa_cso_infinite_silver"] = {"tfa_cso_infinite_black", "tfa_cso_infinite_red", "tfa_cso_dualinfinity", "tfa_cso_infinityex1", "tfa_cso_dualinfinityfinal"}
weaponevos["tfa_cso_kriss_v"] = {"tfa_cso_dualkriss", "tfa_cso_dualkrisshero"}
weaponevos["tfa_cso_guitar"] = {"tfa_cso_violingun"}
weaponevos["tfa_cso_dbarrel"] = {"tfa_cso_dbarrel_g", "tfa_cso_tbarrel", "tfa_cso_qbarrel"}
weaponevos["tfa_cso_budgetsword"] = {"tfa_cso_dualsword", "tfa_cso_dualsword_rb"}
weaponevos["tfa_cso_deagle"] = {"tfa_cso_deaglered", "tfa_cso_g_deagle", "tfa_cso_crimson_hunter", "tfa_cso_crimson_hunter_expert"}
weaponevos["tfa_cso_awp"] = {"tfa_cso_awp_red", "tfa_cso_awpcamo", "tfa_cso_awpz", "tfa_cso_elvenranger"}
weaponevos["tfa_cso_as50"] = {"tfa_cso_as50g", "tfa_cso_as50_expert", "tfa_cso_as50_master"}
weaponevos["tfa_cso_ak47"] = {"tfa_cso_ak47red", "tfa_cso_g_ak47", "tfa_cso_ak47_dragon", "tfa_cso_paladin", "tfa_cso_paladin_v6", "tfa_cso_paladin_v8"}
weaponevos["tfa_cso_balrog1"] = {"tfa_cso_balrog3", "tfa_cso_balrog5", "tfa_cso_balrog7", "tfa_cso_balrog11"}
weaponevos["tfa_cso_xm1014"] = {"tfa_cso_xm1014red"}
weaponevos["tfa_cso_bendita"] = {"tfa_cso_bendita_v6"}
weaponevos["tfa_cso2_m3"] = {"tfa_cso2_m3boom", "tfa_cso_m3shark", "tfa_cso2_m3dragon", "tfa_cso_m3dragon"}
weaponevos["tfa_cso_dragonblade"] = {"tfa_cso_dragonblade_expert"}
weaponevos["tfa_cso_tacticalknife"] = {"tfa_cso_dualtacknife", "tfa_cso_tritacknife"}
weaponevos["tfa_cso_katana"] = {"tfa_cso_dualkatana"}
weaponevos["tfa_cso_nata"] = {"tfa_cso_dualnata"}
weaponevos["tfa_cso_m950"] = {"tfa_cso_m950_v6", "tfa_cso_m950_v8"}
weaponevos["tfa_cso_arx160"] = {"tfa_cso_arx160_expert", "tfa_cso_arx160_master"}
weaponevos["tfa_bo4_welling"] = {"tfa_bo4_welling_dw"}
weaponevos["tfa_bo4_strife"] = {"tfa_bo4_rk7"}
weaponevos["tfa_cso_sten_mk2"] = {"tfa_bo3_bootlegger"}
local wpns = {"tfa_bo4_mozu", "tfa_bo3_m1911", "tfa_bo3_pharo", "tfa_bo3_mg08", "tfa_bo3_olympia", "tfa_bo3_m14", "tfa_bo3_haymaker12", "tfa_bo3_dingo", "tfa_bo3_marshal_16", "tfa_bo3_xr2", "tfa_bo3_ppsh", "tfa_bo4_kap45", "tfa_bo4_daemon", "tfa_bo4_strife", "tfa_bo4_welling", "tfa_cso_dbarrel", "tfa_cso2_m3", "tfa_cso_avalanche", "tfa_cso_dragoncannon", "tfa_cso_arx160", "tfa_cso_m950", "tfa_cso_laserminigun", "tfa_cso_r93", "tfa_cso_m200", "tfa_cso_python", "tfa_cso_jaydagger", "tfa_cso_katana", "tfa_cso_nata", "tfa_cso_aeolis", "tfa_cso_as50", "tfa_cso_ak47", "tfa_cso_ak74u", "tfa_cso_akm", "tfa_cso_an94", "tfa_cso_anaconda", "tfa_cso_batista", "tfa_cso_bazooka", "tfa_cso_bendita", "tfa_cso_xm1014", "tfa_cso_automagv", "tfa_cso2_m3", "tfa_cso_awp", "tfa_cso_butterflyknife", "tfa_cso_balrog1", "tfa_cso_broad", "tfa_cso_deagle", "tfa_cso_f2000", "tfa_cso_p90", "tfa_cso_mk48", "tfa_cso_fnp45", "tfa_cso_glock", "tfa_cso_hk_g11", "tfa_cso_gungnir_nrm", "tfa_cso_dragonblade", "tfa_cso_hk121", "tfa_cso_hk23", "tfa_cso_infinite_silver", "tfa_cso_holysword", "tfa_cso_laserfist", "tfa_cso_kingcobra", "tfa_cso_kriss_v", "tfa_cso_ksg12","tfa_cso_guitar","tfa_cso_kujang","tfa_cso_cameragun","tfa_cso_umbrella","tfa_cso_m134_vulcan","tfa_cso_at4","tfa_cso_luger","tfa_cso_m14ebr","tfa_cso_m16a1","tfa_cso_m2","tfa_cso_m1911a1","tfa_cso_m1918bar","tfa_cso_m249","tfa_cso_m4a1","tfa_cso_m60","tfa_cso_m79","tfa_cso_m95","tfa_cso_mg3","tfa_cso_mg36","tfa_cso_mp7a1","tfa_cso_mp5","tfa_cso_newcomen","tfa_cso_groza","tfa_bo4_mp40","tfa_cso_m82","tfa_cso_pkm","tfa_cso_m24","tfa_cso_rpg7","tfa_cso_runebreaker","tfa_cso_ruyi","tfa_cso_trg42","tfa_cso_savery","tfa_cso_sapientia","tfa_cso_scarh","tfa_cso_scar_l","tfa_cso_sealknife","tfa_cso_serpent_blade","tfa_cso_lycanthrope","tfa_cso_skull1","tfa_cso_sl8","tfa_cso_snap_blade","tfa_cso_spas12","tfa_cso_duckgun","tfa_cso_starchaserar","tfa_cso_sten_mk2","tfa_cso_scout","tfa_cso_stg44","tfa_cso_tacticalknife","tfa_cso_budgetsword","tfa_cso_tempest","tfa_cso_thanatos1","tfa_cso_thompson_chicago","tfa_cso_thunderbolt","tfa_cso_thunderpistol","tfa_cso_tmp","tfa_cso_usp","tfa_cso_uts15","tfa_cso_wa2000","tfa_cso_vulcanus1_a","tfa_cso_xm8","tfa_cso_m1887","tfa_cso_m134_zhubajie","tfa_cso_stormgiant_tw"}

timer.Create("cw3_coderefreshnotification", 0.3, 1, function()
	PrintMessage(HUD_PRINTTALK, "[CRAFTWORLD3] Code has just been refreshed or initialised.")
	PrintMessage(HUD_PRINTTALK, "Got " .. #wpns .. " weapon entries.")
	PrintMessage(HUD_PRINTTALK, "Got " .. table.Count(weaponevos) .. " weapon evolution paths.")
	local weaponstotal = 0
	for i = 1, #wpns do
		weaponstotal = weaponstotal + 1
		if weaponevos[wpns[i]] != nil then
			weaponstotal = weaponstotal + table.Count(weaponevos[wpns[i]])
		end
	end
	PrintMessage(HUD_PRINTTALK,  weaponstotal .. " total unique weapons.")
end)
function GetStrongestPlayer()
	local strongest = {"INVALID", {0, 0}, Entity(0)}
	for k, ply in pairs(player.GetAll()) do
		if strongest[1] != ply:SteamID() then
			if bignumcompare(PowerMeasure(ply), strongest[2]) == 1 then --only accept entry if it's GREATER, not GREATER THAN OR EQUAL TO.
				strongest[1] = ply:SteamID()
				strongest[2] = PowerMeasure(ply)
				strongest[3] = ply
			end
		end
	end
	if strongest[1] == "INVALID" then cw3error("Invalid handle with finding strongest player") end
	if strongest[3] == Entity(0) then cw3error("Invalid handle with finding strongest player") end
	return strongest[3]
end

function TallySpecialLevels(ent)
	if ent:IsPlayer() then
		local qty = 0
		for i = 1, 9 do
			qty = qty + (ent.accountdata["level"][i + 1]*i)
		end
		return qty
	end
end

function GetCurZone()
	return curzone
end

function Equalise()
	local strong = GetStrongestPlayer()
	local reductionscale = math.max(0, (TallySpecialLevels(strong) - (curzone*4))/15)
	for a = 1, #allowednpcs do
		enemies[allowednpcs[a]].hp = bignumdiv(bignummult(bignumcopy(strong.MaxHealth64), enemies[allowednpcs[a]].playerscale), 2.5 + reductionscale)
		enemies[allowednpcs[a]].dmg = bignumdiv(bignummult(bignumcopy(strong.MaxShield64), enemies[allowednpcs[a]].playerscale), 6.6 + reductionscale)
		enemies[allowednpcs[a]].gold = bignumadd({1, curzone}, bignumdiv(bignumcopy(strong.accountdata["gold"]), {1, curzone}))
	end
	zonebonus = bignummult(bignumcopy(strong.accountdata["gold"]), 3.3)
	--PrintMessage(HUD_PRINTTALK, "Zone Bonus: " .. bignumwrite(zonebonus))
	rainbowchestvalue = bignumpow(bignumcopy(zonebonus), 3)
	--PrintMessage(HUD_PRINTTALK, "Rainbow Chest: " .. bignumwrite(rainbowchestvalue))
end

timer.Simple(1, function() if TrueCraftling() then Equalise() end end)

function ResetEnemyStrength()
	rainbowchestvalue = {900, 0}
	zonebonus = {300, 0}
	enemies = listenemies
	if TrueCraftling() then Equalise() end
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

function CustomPickup(spawnpos, name, desc, model, material, snd, pitch, size, rarity, physics, lockto, funct, spawnfunct)
	if !spawnpos then cw3error("CustomPickup - no pickup spawn position defined") end
	if physics == nil then physics = true end
	local custom = ents.Create("cw3_pickup")
	custom.CustomItem = true
	custom.CustomModelPath = model or "models/hunter/blocks/cube025x025x025.mdl"
	custom.customsoundfile = snd or "rf/get.wav"
	custom.customsndpitch = pitch or 100
	custom.custommaterial = material or ""
	custom.CustomPickupName = name or ""
	custom.CustomDesc = desc or ""
	custom.custommodelscale = size or 1
	custom.CustomRare = rarity or 1
	custom.CustomNoPhysics = not physics
	if funct then
		custom.customfunc = funct
	end
	if lockto then
		custom.CustomCanOnlyBeTakenBy = lockto
	end
	if spawnfunct then
		custom.customspawnfunc = spawnfunct
	end
	custom:SetPos(spawnpos)
	custom:Spawn()
end

function LoneWolf()
	if game.SinglePlayer() then
		return true
	else
		return #player.GetAll() == 1
	end
end

function PlayerCount()
	if game.SinglePlayer() then
		return 1
	else
		return #player.GetAll()
	end
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

function IncreaseEnemyStrength(iterations)
	if !iterations then iterations = 1 end
	for a = 1, iterations do
		if TrueCraftling() then
			for b = 1, #allowednpcs do
				enemies[allowednpcs[b]].hp = bignummult(enemies[allowednpcs[b]].hp, 1.007)
				enemies[allowednpcs[b]].dmg = bignummult(enemies[allowednpcs[b]].dmg, 1.007)
				enemies[allowednpcs[b]].gold = bignummult(enemies[allowednpcs[b]].gold, 1.007)
				zonebonus = bignummult(zonebonus, 1.007)
				rainbowchestvalue = bignummult(rainbowchestvalue, 1.007)
			end
		else
			for b = 1, #allowednpcs do
				for c = 1, math.ceil(curzone/5) do
					zonebonus = bignummult(zonebonus, GetAmpFactor()[1] + (((curzone-1)*GetAmpFactor()[2]) ^ 0.08) + (1.1^curzone))
					rainbowchestvalue = bignummult(rainbowchestvalue, GetAmpFactor()[1] + (((curzone-1)*GetAmpFactor()[2]) ^ 0.02) + curzone*3 + (1.9^curzone))
					for e = 1, math.ceil(curzone/5)^1.3 do
						enemies[allowednpcs[b]].gold = bignummult(enemies[allowednpcs[b]].gold, GetAmpFactor()[1] + (((curzone-1)*GetAmpFactor()[2]) ^ 0.02) + curzone*3 + (1.9^curzone))
					end
				end
				for f = 1, math.ceil(curzone/5)^2.35 do
					enemies[allowednpcs[b]].hp = bignummult(enemies[allowednpcs[b]].hp, GetAmpFactor()[1] + (((curzone-1)*GetAmpFactor()[2]) ^ 0.2) + (1.4^curzone))
					enemies[allowednpcs[b]].dmg = bignummult(enemies[allowednpcs[b]].dmg, GetAmpFactor()[1] + (((curzone-1)*GetAmpFactor()[2]) ^ 0.3) + (1.4^curzone))
				end
			end
		end
	end
end

local rationiter = 0
timer.Remove("npcrationalise")
function RationaliseEnemyStrength()
	timer.Remove("npcrationalise")
	ResetEnemyStrength()
	rationiter = 0
	if curzone <= 1 then spawningallowed = CurTime() + 1 end
	if curzone-1 > 0 then
		timer.Create("npcrationalise", 0, 0, function()
			if curzone - 1 - rationiter > 10000 then
				IncreaseEnemyStrength(1000)
				rationiter = rationiter + 1000
			elseif curzone - 1 - rationiter > 1000 then
				IncreaseEnemyStrength(100)
				rationiter = rationiter + 100
			elseif curzone - 1 - rationiter > 100 then
				IncreaseEnemyStrength(10)
				rationiter = rationiter + 10
			else
				IncreaseEnemyStrength(1)
				rationiter = rationiter + 1
			end
			--PrintMessage(HUD_PRINTCENTER, "Loading Zone " .. string.Comma(curzone) .. "...\nStat-Scaling Iteration " .. string.Comma(rationiter) .. " / " .. string.Comma(curzone-1))
			spawningallowed = CurTime() + 1 --disables spawning for 1 second
			if rationiter >= curzone - 1 then
				timer.Remove("npcrationalise")
			end
		end)
	end
end

function SetZone(zone)
	zoneclear = false
	zone = math.Round(zone)
	if zone != curzone then
		curzone = zone
		zonekills = 0
		capsulechance = 1
		if zone % math.Round(cfg["game"]["zone_boss_interval"]) == 0 then
			maxzonekills = 1
		else
			maxzonekills = math.min(math.floor(cfg["game"]["zone_npc_basecount"] * (cfg["game"]["zone_npc_exponent"] ^ curzone)), 30)
		end
		RationaliseEnemyStrength()
		KillBomb()
	end
end

timer.Remove("zonereset")
function ResetZone(additivedelay, resetprogress)
	if !zoneclear then
		PurgeEnemies()
		spawningallowed = math.huge
		if resetprogress then
			zonekills = 0
			KillBomb()
		end
		timer.Remove("zonereset")
		timer.Create("zonereset", 2 + (additivedelay or 0), 1, function()
			RationaliseEnemyStrength()
		end)
	end
end

function AttachVisual(ent, visualfx, nocenter)
	local visual = ents.Create(visualfx)
	visual:SetPos(ent:GetPos() and nocenter or (ent:GetPos() + ent:OBBCenter()))
	visual:SetAngles(ent:GetAngles())
	visual:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	visual.IsDebris = 1
	visual.VisualFX = true
	visual:SetParent(ent)
	visual:Spawn()
	if IsValid(visual:GetPhysicsObject()) then visual:GetPhysicsObject():EnableMotion(false) end
end

function AttachVisualTemp(lifetime, ent, visualfx, nocenter)
	local visual = ents.Create(visualfx)
	visual:SetPos(ent:GetPos() and nocenter or (ent:GetPos() + ent:OBBCenter()))
	visual:SetAngles(ent:GetAngles())
	visual:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	visual.IsDebris = 1
	visual.VisualFX = true
	visual:SetParent(ent)
	visual:Spawn()
	timer.Simple(lifetime, function() if IsValid(visual) then visual:Remove() end end)
	if IsValid(visual:GetPhysicsObject()) then visual:GetPhysicsObject():EnableMotion(false) end
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
		SendPopoff("+" .. string.Comma(quantity) .. " " .. status, target,Color(255,127,255),Color(0,0,255))
	else
		SendPopoff(string.Comma(quantity) .. " " .. status, target,Color(255,127,255),Color(255,0,0))
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
	target:EmitSound("rf/shine.wav", 85, 100, 0.5)
end

function RemoveStatus(target, status)
	if !target.StatusFX then return end
	for i = 1, #target.StatusFX do
		if target.StatusFX[i] then
			if target.StatusFX[i]["effect"] then
				if target.StatusFX[i]["effect"] == status then
					SendPopoff(target.StatusFX[i]["effect"] .. " wears off", target,Color(127,127,127),Color(255,255,255))
					table.remove(target.StatusFX, i)
					target:EmitSound("rf/hole.wav", 85, 100, 0.5)
				end
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

file.CreateDir(sdir)

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
						if !string.find(victim:GetClass(), "cw3_") then
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

function SpawnGold(ent, gold, ignoretruecraftling)
	if isnumber(gold) then gold = bignumconvert(gold) end
	if bignumzero(gold) then return end
	local g = ents.Create("cw3_pickup")
	g.Qty = gold
	g.ItemID = 0
	g.IgnoreTrueCraftling = (ignoretruecraftling or false)
	g:SetPos(ent:GetPos() + ent:OBBCenter())
	g:Spawn()
end

function ScatterGold(ent, gold, forcedamount, ignoretruecraftling)
	if !forcedamount then forcedamount = math.random(4,7) end --default to random of 4 to 7 cash pickups if forcedamount is not defined
	local amount = forcedamount
	if isnumber(gold) then gold = bignumconvert(gold) end
	if bignumzero(gold) then return end
	for i = 1, amount do
		local g = ents.Create("cw3_pickup")
		g.Qty = bignumdiv(bignumcopy(gold), amount)
		g.ItemID = 0
		g.IgnoreTrueCraftling = (ignoretruecraftling or false)
		g:SetPos(ent:GetPos() + ent:OBBCenter())
		g:Spawn()
	end
end

function BombExists()
	local exists = false
	for k, p in pairs(ents.FindByClass("cw3_pickup")) do
		if p.ItemID == -2 then
			exists = true
		end
	end
	return exists
end

function KillBomb()
	for k, p in pairs(ents.FindByClass("cw3_pickup")) do
		if p.ItemID == -2 then
			WarpFX(p)
			p:Remove()
		end
	end
end

function PurgeEnemies(gold)
	if !gold then gold = 0 end
	for k, ent in pairs(ents.GetAll()) do
		if ent:IsNPC() then
			SlayEnemy(ent, gold, true)
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
	local bomb = ents.Create("cw3_pickup")
	bomb.ItemID = -2
	bomb:SetPos(pos)
	bomb:Spawn()
	timer.Simple(0, function() if IsValid(bomb) then if IsValid(bomb:GetPhysicsObject()) then bomb:GetPhysicsObject():EnableMotion(false) bomb:SetPos(pos) bomb:SetAngles(Angle(0,0,0)) end end end)
end

timer.Remove("zonetransition")
function CompleteZone()
	zoneclear = true
	local zonechangetime = 7
	if timer.Exists("zonetransition") then return end
	timer.Remove("zonetransition") --just in case...
	timer.Remove("zonereset")
	zonekills = 0
	PurgeEnemies(0.15)
	if curzone % math.Round(cfg["game"]["zone_boss_interval"]) != 0 then -- boss zone gold is managed by the boss
		Announce("Zone " .. curzone .. " Cleared", Color(0,255,255), Color(0,58,255), 5)
		SpawnGold(player.GetAll()[math.random(#player.GetAll())], zonebonus, true)
	end
	for k, p in pairs(ents.FindByClass("cw3_pickup")) do
		if p.PickedUp == 0 && p.ItemID != 0 && !p.ZoneClearPickupImmunity then
			local rnd = math.random(#player.GetAll())
			timer.Simple(math.Rand(0.1,3), function() if IsValid(p) && IsValid(player.GetAll()[rnd]) then p:Use(player.GetAll()[rnd],player.GetAll()[rnd],3,1) elseif IsValid(p) then WarpFX(p) p:Remove() end end)
		end
	end
	local spawns = ents.FindByClass("info_player_start")
	for k, ply in pairs(player.GetAll()) do	
		if !ply.CodeBusy then
			timer.Remove(ply:SteamID() .. "shieldcooldown")
			ply.stamina = 150
			if curzone % math.Round(cfg["game"]["zone_boss_interval"]) == 0 then
				ply:GiveCubes(1, bignumcalc(GetZoneCubeValue()[1]), ply:GetPos())
				if curzone >= 25 then
					ply:GiveCubes(2, bignumcalc(GetZoneCubeValue()[2]), ply:GetPos())
				end
			end
			ply.RegenerationTime = 0
			if curzone % math.Round(cfg["game"]["zone_boss_interval"]) == 0 then
				ply.CodeBusy = true
				ply.RegenActive = false
				ply:Freeze(true)
				ply:CreateRagdoll()
				ply:SetNoDraw(true)
				zonechangetime = 21
				ply:EmitSound("rf/end.wav", 95, 80)
				if ply.AntiGriefBossCountdown then
					ply.AntiGriefBossCountdown = math.min(10, ply.AntiGriefBossCountdown + 2) --trust them a little bit
				end
				if ply.AntiGriefBossDamagePercent then ply.AntiGriefBossDamagePercent = math.max(0, ply.AntiGriefBossDamagePercent - 4) end --cut them a little bit of slack
				Announce("=Summary=", Color(168,168,168), Color(0,0,0), 3, ply)
				Announce("Shield Left: " .. bignumwrite(ply.Shield64) .. "/" .. bignumwrite(ply.MaxShield64), Color(0,158,255), Color(0,0,0), 3, ply)
				Announce("Health Left: " .. bignumwrite(ply.Health64) .. "/" .. bignumwrite(ply.MaxHealth64), Color(92,0,0), Color(0,0,0), 3, ply)
				Announce("Pulses Left: " .. ply.healthstate .. "/" .. 5, Color(127,0,255), Color(0,0,255), 5, ply)
				for i = 1, ply.healthstate - 1 do
					timer.Simple(i + 9, function() if IsValid(ply) then
						ply:GiveCubes(1, {5*i, 0})
						if i > 2 then
							ply:GiveCubes(2, {3*(i-2), 0})
						end
					end end)
				end
				timer.Simple(zonechangetime, function() if IsValid(ply) then
					ply.Health64 = bignumcopy(ply.MaxHealth64)
					ply.Shield64 = bignumcopy(ply.MaxShield64)
					ply.Block64 = bignumcopy(ply.MaxBlock64)
					ply.RegenActive = true
					ply.healthstate = 5
					ply.CodeBusy = false
					ply:Freeze(false)
					if IsValid(ply:GetRagdollEntity()) then ply:GetRagdollEntity():Remove() end
					ply:SetNoDraw(false)
					local rnd = math.random(#spawns)
					if #spawns > 0 then
						ply:SetPos(spawns[rnd]:GetPos())
						table.remove(spawns, rnd)
						WarpFX(ply)
					end
				end end)
			else
				ply.Health64 = bignumcopy(ply.MaxHealth64)
				ply.Shield64 = bignumcopy(ply.MaxShield64)
				ply.Block64 = bignumcopy(ply.MaxBlock64)
				ply.RegenActive = true
				ply:EmitSound("rf/maxout.wav")
				if ply.healthstate < 5 then
					ply:RecoverPulses(1)
				end
			end
		end
	end
	spawningallowed = math.huge
	timer.Create("zonetransition", zonechangetime, 1, function()
		SetZone(curzone + 1)
	end)
end

function PowerMeasure(ent)
	if ent:IsPlayer() then
		local power = bignummult(bignumcopy(ent.MaxHealth64), 1.32)
		bignumadd(power, bignummult(bignumcopy(ent.MaxShield64), 1.16))
		bignumadd(power, bignummult(bignumcopy(ent.MaxBlock64), 0.54))
		for k, w in pairs(ent:GetWeapons()) do
			if w.Damage64 then
				bignumadd(power, bignummult(bignumcopy(w.Damage64), 3.632))
			end
		end
		return power
	elseif ent:IsNPC() then
		local power = bignummult(bignumcopy(ent.MaxHealth64), 1.29)
		bignumadd(power, bignummult(bignumcopy(ent.Damage64), 2.358))
		return power
	else
		return {0, 0}
	end
end

function AutoUpgrade(ply) --automatically upgrades players who have absurdly large amounts of gold
	if bignumelevate(ply.accountdata["gold"], ply.accountdata["prices"][1]) >= 3 then
		for i = 1, math.Clamp(bignumelevate(ply.accountdata["gold"], ply.accountdata["prices"][1]), 1, 100) do
			ply:ShopBuy(1, nil, true)
		end
	elseif bignumelevate(ply.accountdata["gold"], ply.accountdata["prices"][2]) >= 3 && ply.accountdata["points"][1] > 100 then
		ply:ShopBuy(2, nil, true)
	elseif bignumelevate(ply.accountdata["gold"], ply.accountdata["prices"][3]) >= 3 && ply.accountdata["points"][2] > 50 then
		ply:ShopBuy(3, nil, true)
	elseif bignumelevate(ply.accountdata["gold"], ply.accountdata["prices"][4]) >= 3 && ply.accountdata["points"][3] > 50 then
		ply:ShopBuy(4, nil, true)
	elseif bignumelevate(ply.accountdata["gold"], ply.accountdata["prices"][5]) >= 3 && ply.accountdata["points"][4] > 25 then
		ply:ShopBuy(5, nil, true)
	end
end

function TurboUpgrade(ply) --an alternative version that can be activated via a command, which autobuys levels constantly
	if ply.TurboLv then
		for i = 1, 10 do
			ply:ShopBuy(i, nil, true)
			ply:ShopBuy(i, ply:GetActiveWeapon(), true)
		end
	end
end

function SlayEnemy(ent, goldmult, noprogress)
	if ent.NPCDead then return end
	if !ent:IsNPC() then cw3error("Attempt to slay non-NPC: " .. tostring(ent)) return end
	if ent == nil then cw3error("Target to slay does not exist (nil)") end
	if goldmult == nil then goldmult = 1 end
	local timelim = 7
	if ent:IsNPC() then --just in case...
		ent:SetNWBool("npcisdead", true)
		if ent.RainbowChest then
			RewardRainbowChest(ent:GetPos() + Vector(0, 0, ent:OBBMaxs().z + 5))
			if #ent:GetChildren() > 0 then
				for k, m in pairs(ent:GetChildren()) do
					BreakEntity(m)
					m:Remove()
				end
			end
		end
		if ent.gCubes && ent.cCubes then
			ParticleEffect("merasmus_spawn", ent:GetPos(), Angle(0,0,0))
			local gift = ents.Create("cw3_pickup")
			gift:SetPos(ent:GetPos() + ent:OBBCenter())
			gift.ItemID = 7
			gift.Qty = ent.gCubes
			gift:Spawn()
		elseif ent.gCubes then
			ParticleEffect("merasmus_spawn", ent:GetPos(), Angle(0,0,0))
			local gift = ents.Create("cw3_pickup")
			gift:SetPos(ent:GetPos() + ent:OBBCenter())
			gift.ItemID = 5
			gift.Qty = ent.gCubes
			gift:Spawn()
		elseif ent.cCubes then
			ParticleEffect("merasmus_spawn", ent:GetPos(), Angle(0,0,0))
			local gift = ents.Create("cw3_pickup")
			gift:SetPos(ent:GetPos() + ent:OBBCenter())
			gift.ItemID = 6
			gift.Qty = ent.cCubes
			gift:Spawn()
		end
		if ent:GetModelScale() > 1 or ent:GetClass() == "npc_manhack" or ent:GetClass() == "npc_rollermine" then
			if ent.MotorLoop then ent.MotorLoop:Stop() end
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
				gib:SetColor(ent:GetColor())
				gib:SetModelScale(ent:GetModelScale() - 0.75)
				gib.IsDebris = 1
				gib:Spawn()
				timer.Simple(0, function() if IsValid(gib) then if IsValid(gib:GetPhysicsObject()) then gib:GetPhysicsObject():SetVelocity(VectorRand()*300) gib:GetPhysicsObject():AddAngleVelocity(VectorRand()*720) end end end)
				timer.Simple(7, function() if IsValid(gib) then gib.InstantSoftRemove = true end end)
				--timelim = 0
			end
		end
		--else
			local corpse = ents.Create("prop_ragdoll")
			corpse:SetModel(ent:GetModel())
			corpse:SetPos(ent:GetPos())
			corpse:SetAngles(ent:GetAngles())
			corpse:SetColor(Color(255,0,0))
			corpse:SetMaterial(ent:GetMaterial())
			corpse.IsDebris = 1
			corpse:Spawn()
			corpse:EmitSound("rf/flesh.wav")
			corpse:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
			if string.find(ent:GetClass(), "zombie") then
				corpse:SetBodygroup(0, 1)
			end
			timer.Simple(7, function() if IsValid(corpse) then corpse.InstantSoftRemove = true end end)
			timer.Simple(0, function() if IsValid(corpse) then
				for i = 0, corpse:GetPhysicsObjectCount() - 1 do
					local phys = corpse:GetPhysicsObjectNum( i )
					phys:AddVelocity(VectorRand()*500)
					phys:AddAngleVelocity(VectorRand()*720)
				end
			end end)
			ent:SetParent(corpse)
		--end
		if ent.Gold64 && !ent.NPCDead then
			if goldmult > 0 then
				if ent.Prefix && curzone < 80 then --is the NPC to slay not normal?
					ScatterGold(ent, bignummult(ent.Gold64, goldmult), math.random(4, 7), (ent.IsBoss or false)) --money firework!
				else
					SpawnGold(ent, bignummult(ent.Gold64, goldmult), (ent.IsBoss or false)) --packaged up into one nice stack.
				end
			end
		end
		if !noprogress then
			zonekills = zonekills + 1
			if zonekills >= maxzonekills && !BombExists() then
				CreateBomb(ent:GetPos() + Vector(0,0,15))
			end
		end
		ent.Damage64 = {0, 0}
		ent.Gold64 = {0, 0}
		ent.Health64 = {0, 0}
		ent.MaxHealth64 = {0, 0}
		ent.ActiveMat = "null"
		ent:SetMaterial("null")
		ent:SetSchedule(SCHED_DIE)
		ent:SetCondition(67)
		ent:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
		ent.NPCDead = true
		ent.ZeroDamage = true
		ent:SetRenderMode(RENDERMODE_TRANSALPHA)
		ent:SetColor(Color(0,0,0,0))
		timer.Simple(timelim, function() if IsValid(ent) then
			if #ent:GetChildren() > 0 then
				for k, m in pairs(ent:GetChildren()) do
					if not string.find(m:GetClass(), "mr_effect") then
						BreakEntity(m)
					end
					m:Remove()
				end
			end
			ent:Remove()
		end end)
	end
end

concommand.Add("forcerainbowchest", function(ply)
	if ply:IsSuperAdmin() then
		timeuntilnextchest = 0
	end
end)

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
		for k, ent in pairs(ents.FindByClass("cw3_*")) do
			if ent:GetClass() == "cw3_pickup" then
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
					obj:SetRenderMode(RENDERMODE_TRANSALPHA) --make sure we can make it transparent
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
								obj:SetColor(Color(obj:GetColor().r, obj:GetColor().g, obj:GetColor().b, math.max(0.01, obj:GetColor().a - 2.55)))
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
	if inWater then return end
	if Hibernating() then return end
	if ply.IgnoreFallDamageAlways then return end
	local sensitivity = 1
	if game.GetMap() == "dm_lostarena" then
		sensitivity = 0.55
	end
	if game.GetMap() == "gm_construct_5" or game.GetMap() == "gm_construct_10" then
		sensitivity = 0.65
	end
	if ply.jumpboost > CurTime() then sensitivity = math.huge end
	if speed > 750*sensitivity then
		ply:EmitSound("rf/falldamage_heavy.wav")
		if !ply.IgnoreFallDamageOnce then bignumdiv(ply.Health64, 1.5) end
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
				if ply.IgnoreFallDamageOnce then
					ply.IgnoreFallDamageOnce = nil
				else
					bignumdiv(ply.Health64, 5)
					ply.healthstate = math.max(1, ply.healthstate - 1)
				end
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
		timer.Simple(stuntime, function() if IsValid(rag) then rag:Remove() end end)
	end
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

function DamageNumber(ent, num)
	if !ent.DamageTally then ent.DamageTally = {0, 0} end
	bignumadd(ent.DamageTally, num)
	timer.Create(tostring(ent) .. "dmgnum", 0, 1, function() if IsValid(ent) then if ent.DamageTally then SendPopoff("-" .. bignumwrite(ent.DamageTally), ent, Color(255,0,0), Color(255,199,199)) ent.DamageTally = nil end end end)
end

function GetZoneCubeValue()
	return {bignumconvert(math.max(math.Round((25 * (1.04^curzone))/8) + math.random(0,5*curzone),1)),bignumconvert(math.max(math.Round((25 * (1.04^(curzone-25)))/8) + math.random(0,2*curzone), 1))}
end

function ownerlog(msg)
	--PrintMessage(HUD_PRINTTALK, msg)
end

function NewSave(ply)
	if !ply:IsPlayer() then return end
	ply:StripWeapons()
	ply:StripAmmo()
	local dir = sdir .. "/" .. string.Replace(ply:SteamID64(), ".", "_")
	file.CreateDir(dir)
		file.Write(dir .. "/initialjoin.txt", os.date( "Save created at %H:%M:%S BST on %d/%m/%Y" , os.time() ))
		ownerlog("CREATING NEW SAVE DATA: " .. ply:Nick() .. " [" .. ply:SteamID64() .. "]")
		ownerlog(os.date( "Save created at %H:%M:%S BST on %d/%m/%Y" , os.time() ))
		local heroes
		local account
		account = { ["gold"] = {0, 0}, ["timecubes"] = {0, 0}, ["weaponcubes"] = {0, 0}, ["healthcubes"] = {0, 0}, ["shieldcubes"] = {0, 0}, ["prices"] = {{80, 0}, {15, 1}, {600, 2}, {75, 3}, {400, 5}, {245, 8}, {500, 11}, {800, 20}, {335, 35}, {500, 50}}, ["health"] = bignumread("7"), ["shield"] = bignumread("3"), ["block"] = bignumread("12"), ["level"] = {1,0,0,0,0,0,0,0,0,0}, ["fistslevel"] = {1,0,0,0,0,0,0,0,0,0}, ["investment"] = {0, 0}, ["points"] = {0,0,0,0,0,0,0,0,0} }
		heroes = { [1] = {["active"] = true, ["evolution"] = 1, ["maxed"] = false, ["originalclass"] = "tfa_cso_mp7a1", ["class"] = "tfa_cso_mp7a1", ["dmg"] = bignumread("0.67"), ["power"] = bignumread("0.67"), ["level"] = {1,0,0,0,0,0,0,0,0,0}, ["prices"] = {{40, 0}, {3, 1}, {200, 2}, {35, 3}, {200, 5}, {75, 8}, {90, 11}, {410, 20}, {35, 35}, {50, 50}}, ["investment"] = {0, 0}}, [2] = {["active"] = true, ["evolution"] = 1, ["maxed"] = true, ["originalclass"] = "tfa_cso_automagv", ["class"] = "tfa_cso_automagv", ["dmg"] = bignumread("0.83"), ["power"] = bignumread("0.83"), ["level"] = {1,0,0,0,0,0,0,0,0,0}, ["prices"] = {{40, 0}, {3, 1}, {200, 2}, {35, 3}, {200, 5}, {75, 8}, {90, 11}, {410, 20}, {35, 35}, {50, 50}}, ["investment"] = {0, 0}}, [3] = {["active"] = true, ["evolution"] = 1, ["maxed"] = true, ["originalclass"] = "tfa_cso_sealknife", ["class"] = "tfa_cso_sealknife", ["dmg"] = bignumread("2"), ["power"] = bignumread("2"), ["level"] = {1,0,0,0,0,0,0,0,0,0}, ["prices"] = {{40, 0}, {3, 1}, {200, 2}, {35, 3}, {200, 5}, {75, 8}, {90, 11}, {410, 20}, {35, 35}, {50, 50}}, ["investment"] = {0, 0}} }
		ownerlog("WRITING HERO DATA FOR " .. ply:SteamID64())
		file.Write(dir .. "/herodata.txt", util.TableToJSON(heroes))
		ownerlog("WRITING ACCOUNT DATA FOR " .. ply:SteamID64())
		file.Write(dir .. "/accountdata.txt", util.TableToJSON(account))
		ownerlog("SAVE DATA CREATED FOR " .. ply:SteamID64())
		ply.herodata = heroes
		ply.accountdata = account
		ply:Rationalise(true)
		ply:RefreshWeapons()
end

concommand.Add("craftworld3_wipesave", function(ply)
	if !ply.CodeBusy then
		ply.CodeBusy = true
		NewSave(ply)
		ply.Godmode = true
		ply:EmitSound("rf/ko2.mp3", 135, 100)
		ply:EmitSound("rf/eliminated.wav", 135, 80)
		Announce(ply:Nick() .. " bids farewell to this cruel world.", Color(255,0,0), Color(68,0,0), 3)
		ply:CreateRagdoll()
		ply:SetNoDraw(true)
		ply.healthstate = 0
		ply:Freeze(true)
		timer.Simple(10, function() if IsValid(ply) then
			local spawns = ents.FindByClass("info_player_start")
			if #spawns > 0 then
				ply:SetPos(spawns[math.random(#spawns)]:GetPos())
				WarpFX(ply)
			end
			if IsValid(ply:GetRagdollEntity()) then ply:GetRagdollEntity():Remove() end
			ply:SetNoDraw(false)
			ply.healthstate = 5
			ply:Freeze(false)
			ply.Godmode = false
			ply.CodeBusy = false
		end end)
	end
end)

hook.Add("PlayerInitialSpawn","craftworld3_LOADDATA", function(ply)
	ply:LoadCraftworldData()
	timer.Simple(1, function() if IsValid(ply) then ply:Rationalise(true) end end)
	timer.Simple(3, function() ResetZone() end)
end)

hook.Add("PlayerSpawn","craftworld3_PLAYERSPAWN", function(ply)
	timer.Simple(0, function() if IsValid(ply) then WarpFX(ply) if ply.accountdata && ply.herodata then ply:Rationalise(true) end end end)
end)

local ply = FindMetaTable( "Player" )

function ply:LoadCraftworldData()
	local dir = sdir .. "/" .. string.Replace(self:SteamID64(), ".", "_")
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
	self.healthstate = math.Clamp(self.healthstate + qty, 1, 5)
	for i = 1, qty do
		local pulse = ents.Create("cw3_pickup")
		pulse.ItemID = -1
		pulse:SetPos(self:GetPos())
		pulse:Spawn()
		timer.Simple(0, function() if IsValid(pulse) && IsValid(self) then pulse:Use(self,self,3,1) elseif IsValid(pulse) then pulse:Remove() end end)
	end
end

function ply:GainGold(gold)
	SendPopoff("+$" .. bignumwrite(gold), self, Color(255,255,0), Color(0,139,0))
	bignumadd(self.accountdata["gold"], gold)
end

function ply:SpendGold(gold)
	self:EmitSound("mvm/mvm_bought_upgrade.wav")
	SendPopoff("-$" .. bignumwrite(gold), self, Color(255,255,0), Color(189,0,0))
	bignumsub(self.accountdata["gold"], gold)
end

function ply:GainTimeCubes(timecubes)
	bignumadd(self.accountdata["timecubes"],timecubes)
end

function ply:SpendTimeCubes(timecubes)
	self:EmitSound("mvm/mvm_bought_upgrade.wav")
	self:EmitSound("rf/power_use.wav")
	SendPopoff("-g" .. bignumwrite(timecubes), self, Color(0,117,255), Color(189,0,0))
	bignumsub(self.accountdata["timecubes"], timecubes)
end

function ply:GainWeaponCubes(weaponcubes)
	bignumadd(self.accountdata["weaponcubes"], weaponcubes)
end

function ply:SpendWeaponCubes(weaponcubes)
	self:EmitSound("mvm/mvm_bought_upgrade.wav")
	self:EmitSound("rf/power_use.wav")
	SendPopoff("-c" .. bignumwrite(weaponcubes), self, Color(0,193,0), Color(189,0,0))
	bignumsub(self.accountdata["weaponcubes"], weaponcubes)
end

function ply:GiveCubes(variant, qty, emit)
	if !variant then variant = 1 end
	if !qty then qty = 1 end
	if !emit then emit = self:GetPos() + self:OBBCenter() end
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
	local msgs = {"g", "c"}
	SendPopoff(bignumwrite(qty) .. " " .. msgs[variant] .. "Cubes",self,colors[variant],Color(255,255,0))
	local quantity = qty[1]
	quantity = math.Clamp(quantity, 1, 100)
	local num1 = quantity
	local num2 = math.floor(quantity/100)
	num1 = num1 - (num2*100)
	num2 = num2 + (qty[2]*10)
	for a = 1, math.min(num1,16) do
		local cube = ents.Create("cw3_pickup")
		cube:SetPos(emit)
		cube.Qty = {1, 0}
		cube.ItemID = variant
		cube:Spawn()
		timer.Simple(0, function() if IsValid(self) then cube:Use(self,self,3,1) end end)
	end
	for b = 1, num2 do
		local cube = ents.Create("cw3_pickup")
		cube:SetPos(emit)
		cube.Qty = {100, 0}
		cube.ItemID = variant
		cube:Spawn()
		timer.Simple(0, function() if IsValid(self) then cube:Use(self,self,3,1) end end)
	end
end

function ply:RewardWeapon(weapon, dmg)
	local wepdata = weapons.Get(weapon)
	local weapon2 = weapon
	if !wepdata then return end
	if !self:OwnsWeapon(weapon) then
		local maxevoalready = true
		if LookupMaxEvo(weapon) > 1 then maxevoalready = false end
		self:EmitSound("rf/omega.wav", 122, 36)
		self:EmitSound("rf/omega.wav", 122, 36)
		Announce("Acquired a new weapon: " .. wepdata.PrintName, Color(255,255,0), Color(0,0,255), 8, self)
		local randomstrength = dmg or bignumcalc({math.Rand(13,52)*(1.03^curzone),0})
		table.insert(self.herodata, {["active"] = true, ["evolution"] = 1, ["maxed"] = maxevoalready, ["originalclass"] = weapon, ["class"] = weapon2, ["dmg"] = bignumcopy(randomstrength), ["power"] = bignumcopy(randomstrength), ["level"] = {1,0,0,0,0,0,0,0,0,0}, ["prices"] = {{40, 0}, {3, 1}, {200, 2}, {35, 3}, {200, 5}, {75, 8}, {90, 11}, {410, 20}, {35, 35}, {50, 50}}, ["investment"] = {0, 0}})
		self:RefreshWeapons()
	elseif self:WeaponActive(weapon) then
		local strength = dmg or bignumcalc({math.Rand(13,52)*(1.03^curzone),0})
		if bignumcompare(strength, self.herodata[self:GetWeaponIndex(weapon)]["power"]) == 1 then
			self.herodata[self:GetWeaponIndex(weapon)]["level"] = {1, 0, 0, 0, 0, 0, 0, 0, 0, 0}
			self.herodata[self:GetWeaponIndex(weapon)]["dmg"] = bignumcopy(strength)
			self.herodata[self:GetWeaponIndex(weapon)]["power"] = bignumcopy(strength)
			self.herodata[self:GetWeaponIndex(weapon)]["prices"] = {{40, 0}, {3, 1}, {200, 2}, {35, 3}, {200, 5}, {75, 8}, {90, 11}, {410, 20}, {35, 35}, {50, 50}}
			self:GainGold(self.herodata[self:GetWeaponIndex(weapon)]["investment"])
			self.herodata[self:GetWeaponIndex(weapon)]["investment"] = {0, 0}
			self:EmitSound("rf/upgradetraining.wav", 122, 50)
			self:EmitSound("rf/upgradetraining.wav", 122, 50)
			Announce("Weapon Power improved: " .. wepdata.PrintName, Color(255,0,255), Color(0,255,255), 8, self)
		elseif not self.herodata[self:GetWeaponIndex(weapon)]["maxed"] then
			local maxevo = LookupMaxEvo(weapon)
			if self.herodata[self:GetWeaponIndex(weapon)]["evolution"] < maxevo then
				Announce("Weapon evolved: " .. wepdata.PrintName, Color(255,0,255), Color(0,255,255), 8, self)
				self:EmitSound("rf/suitchest_open.wav", 122)
				self:EmitSound("rf/suitchest_open.wav", 122)
				self.herodata[self:GetWeaponIndex(weapon)]["evolution"] = self.herodata[self:GetWeaponIndex(weapon)]["evolution"] + 1
				self.herodata[self:GetWeaponIndex(weapon)]["class"] = weaponevos[self.herodata[self:GetWeaponIndex(weapon)]["originalclass"]][self.herodata[self:GetWeaponIndex(weapon)]["evolution"] - 1]
				self:RefreshWeapons()
			else
				self:GiveCubes(2, bignumcalc({20*curzone, 0}))
			end
			if self.herodata[self:GetWeaponIndex(weapon)]["evolution"] >= maxevo && not self.herodata[self:GetWeaponIndex(weapon)]["maxed"] then
				self:EmitSound("rf/prestige_ready.mp3", 122, 80)
				self:EmitSound("rf/prestige_ready.mp3", 122, 80)
				Announce("Weapon maxed out: " .. wepdata.PrintName, Color(255,0,255), Color(0,255,255), 8, self)
				self.herodata[self:GetWeaponIndex(weapon)]["maxed"] = true
			end
		else
			self:GiveCubes(2, bignumcalc({20*curzone, 0}))
		end
	else
		self:EmitSound("rf/prestige_ready.mp3", 122, 110)
		self:EmitSound("rf/prestige_ready.mp3", 122, 110)
		Announce("Weapon re-acquired: " .. wepdata.PrintName, Color(255,0,255), Color(0,255,255), 8, self)
		self.herodata[self:GetWeaponIndex(weapon)]["active"] = true
		self:RefreshWeapons()
	end
	self:SaveCraftworldData()
end

function SpawnWeapon(pos, weapon, lockto)
	local data = weapons.Get(weapon)
	local username = ""
	if lockto then
		if lockto:IsPlayer() then username = "Belongs to " .. lockto:Name() end
	end
	CustomPickup(pos, data.PrintName, username, data.WorldModel or "models/items/item_item_crate.mdl", "", "rf/pistol.wav", 100, 1, 7, true, lockto, nil, function(p) p.WeaponDrop = true p.WeaponClass = weapon p.RndDmg = bignumcalc({math.Rand(1.3,5.2)*(1.03^curzone),0}) p.PickupName = "[Power " .. bignumwrite(p.RndDmg) .. "] " .. p.PickupName end)
end

--CustomPickup(spawnpos, name, desc, model, material, snd, pitch, size, rarity, physics, lockto, funct, spawnfunct)

function ply:GetSaveHP()
	return self.accountdata["health"]
end

function ply:GetSaveSP()
	return self.accountdata["shield"]
end

function ply:GetSaveBP()
	return self.accountdata["block"]
end

function ply:SetSaveHP(var)
	self.accountdata["health"] = var
end

function ply:SetSaveSP(var)
	self.accountdata["shield"] = var
end

function ply:SetSaveBP(var)
	self.accountdata["block"] = var
end

function ply:OwnsWeapon(weapon)
	local result = false
	for i = 1, #self.herodata do
		if self.herodata[i]["originalclass"] == weapon then
			result = true
		end
	end
	return result
end

function ply:WeaponActive(weapon)
	local result = false
	if self:OwnsWeapon(weapon) then --the weapon has to exist in their save data obviously
		for i = 1, #self.herodata do
			if self.herodata[i]["originalclass"] == weapon then
				result = self.herodata[i]["active"]
			end
		end
	end
	return result
end

function ply:GetBaseWeapon(weapon)
	local result = weapon --return the input if something goes wrong
	for i = 1, #self.herodata do
		if self.herodata[i]["class"] == weapon then
			result = self.herodata[i]["originalclass"]
		end
	end
	return result
end

function ply:GetWeaponIndex(weapon)
	local index = 0
	for i = 1, #self.herodata do
		if self.herodata[i]["class"] == weapon or self.herodata[i]["originalclass"] == weapon then
			index = i
		end
	end
	if index != 0 then return index else return nil end
end

function IsInvincible(ent)
	if ent.Godmode or ent.CheatGodmode or ent.GuardianAngel or ent.TimedGodmode then
		return true
	else
		return false
	end
end

function ply:Rationalise(heal)
	self.MaxHealth64 = self:GetSaveHP()
	self.MaxShield64 = self:GetSaveSP()
	self.MaxBlock64 = self:GetSaveBP()
	if heal then
		self.Health64 = bignumcopy(self.MaxHealth64)
		self.Shield64 = bignumcopy(self.MaxShield64)
		self.Block64 = bignumcopy(self.MaxBlock64)
	end
	self:SaveCraftworldData()
end

function ply:RefreshWeapons()
	self:StripWeapons()
	for i = 1, #self.herodata do
		if self.herodata[i]["active"] then
			if !self:HasWeapon(self.herodata[i]["class"]) then
				local wep = self:Give(self.herodata[i]["class"], true)
				wep:SetClip1(wep:GetMaxClip1())
				wep.InventoryIndex = i
				if self:GetAmmoCount(wep:GetPrimaryAmmoType()) < wep:GetMaxClip1() * 3 then --resupply the player's ammunition to a minimum of 3x mag size if it's too low
					self:GiveAmmo((wep:GetMaxClip1() * 3) - self:GetAmmoCount(wep:GetPrimaryAmmoType()), wep:GetPrimaryAmmoType(), false)
				end
			end
		end
	end
end

function ply:SetLv(lvtype, int, nofx)
	lvtype = math.Clamp(lvtype,1,10)
	local plylv = self.accountdata["level"]
	local restore = false
	local types = {"Level", "Rank", "Star", "Grade", "Spec Ops", "Class", "Stage", "Quality", "Echelon", "Tier"}
	local messages = {"Level Up", "Upgrade", "Promotion", "Training", "Spec Ops", "Reclassification", "Advancement", "Improvement", "Empowerment", "Ameliorate"}
	local snds = {"level","rank","star","training","specops","training","training","star","specops","training"}
	local fx = {"mr_effect4", "mr_effect31", "mr_effect25", "mr_effect106_3", "mr_effect60", "mr_effect94", "mr_effect110", "mr_effect111", "mr_effect105", "mr_effect1"}
	local colours = {Color(0,87,255), Color(255,187,0), Color(0,255,0), Color(255,67,0), Color(32,32,32), Color(255,0,255), Color(0,255,255), Color(72,155,72), Color(255,255,255), Color(127,0,0)}
	if plylv[lvtype] < int then
		if self.accountdata["leveltutorial"] == nil then
			self.accountdata["leveltutorial"] = true
			Announce("Leveling up increases maximum health, shield, and block integrity.", Color(0, 255, 0), Color(0,0,93), 7, self)
			Announce("The big white number at the top left of the HUD is your Power.", Color(0, 255, 0), Color(0,0,93), 7, self)
			Announce("Power is an average measurement of threat and strength.", Color(0, 255, 0), Color(0,0,93), 7, self)
			Announce("But beware; Power only PREDICTS total strength. It's not entirely accurate!", Color(255, 0, 0), Color(0,0,93), 7, self)
			Announce("Reach certain level milestones to unlock alternative leveling systems.", Color(255, 255, 0), Color(0,0,93), 7, self)
		end
		if TrueCraftling() then ResetZone() end --re-scale the power of enemies
		timer.Create(self:SteamID() .. "upgradefx" .. lvtype, 0.1, 1, function() if IsValid(self) then --do it on timer.Create so that particle FX don't spam
			AttachVisualTemp((lvtype/5) + 2, self, fx[lvtype])
		end end)
		local factors = {1, 5 + (plylv[lvtype]), 35 * (plylv[lvtype]*2 + 1), 45 * (plylv[lvtype] + 1), math.min(math.ceil(235 * (1.13^(plylv[lvtype]))),1000), math.min(math.ceil(600 * (1.16^(plylv[lvtype]))), 1600), 1800, 2000, 2200, 2500}
		local amplifier = factors[lvtype]
		local checks = {10, 100, 500, 1000, 2000, 3000, 4000, 6000, 10000}
		for i = 1, int - plylv[lvtype] do
			for c = 1, amplifier do
				self:SetSaveHP(bignummult(self:GetSaveHP(), 1.013 + (((plylv[lvtype] + c)/100) * lvtype)))
				self:SetSaveSP(bignummult(self:GetSaveSP(), 1.013 + (((plylv[lvtype] + c)/100) * lvtype)))
				self:SetSaveBP(bignummult(self:GetSaveBP(), 1.013 + (((plylv[lvtype] + c)/100) * lvtype)))
			end
			if lvtype == 1 then
				if !self.accountdata["points"] then self.accountdata["points"] = {0,0,0,0,0,0,0,0,0} end
				for b = 1, 9 do
					if (plylv[1]+i) % checks[b] == 0 then
						SendPopoff(messages[b+1] .. " Ready", self, colours[b+1], Color(255,255,0))
						self:EmitSound("rf/prestige_ready.mp3", 95, 100)
						self:EmitSound("rf/evolve_v2.mp3", 95, 75)
						self.accountdata["points"][b] = self.accountdata["points"][b] + 1
					end
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

function ply:CurrentWeapon()
	local somethingwentwrong = true
	if !self:GetActiveWeapon().InventoryIndex then return nil end
	local class = self:GetActiveWeapon():GetClass()
	for i = 1, #self.herodata do
		if self.herodata[i]["class"] == class then
			somethingwentwrong = false
			return self.herodata[i]
		end
	end
	if somethingwentwrong then
		cw3error("ply:CurrentWeapon - inventory index defined, but no matches in player's save data")
	end
end

function ply:GetWepEvo(weapon, indexbycurrentclass)
	if not self:OwnsWeapon(weapon) then return nil end
	local indexby = "originalclass"
	local evolution = 1
	if indexbycurrentclass then indexby = "class" end
	for i = 1, #self.herodata do
		if self.herodata[i][indexby] == weapon then
			evolution = self.herodata[i]["evolution"]
		end
	end
	return evolution
end

function LookupMaxEvo(weapon)
	local maxevo = 1
	for i = 1, #wpns do
		if wpns[i] == weapon then
			if weaponevos[weapon] != nil then
				maxevo = 1 + #weaponevos[weapon]
			end
		end
	end
	return maxevo
end

function ply:SetWepLv(wep, lvtype, int, nofx)
	if !wep:IsWeapon() then cw3error("ply:SetWepLv - argument #1 is not a weapon") end
	if wep:GetOwner() != self then cw3error("ply:SetWepLv - argument #1 is a weapon that belongs to a different player") end
	if self:CurrentWeapon() == nil then return end
	self:SelectWeapon(wep:GetClass()) --make sure the weapon to upgrade is the current one
	local data = self:CurrentWeapon()
	lvtype = math.Clamp(lvtype,1,10)
	local weplv = data["level"]
	local types = {"Level", "Rank", "Star", "Grade", "Spec Ops", "Class", "Stage", "Quality", "Echelon", "Tier"}
	local messages = {"Level Up", "Upgrade", "Promotion", "Training", "Spec Ops", "Reclassification", "Advancement", "Improvement", "Empowerment", "Ameliorate"}
	local snds = {"level","rank","star","training","specops","training","training","star","specops","training"}
	local fx = {"mr_effect4", "mr_effect31", "mr_effect25", "mr_effect106_3", "mr_effect60", "mr_effect94", "mr_effect110", "mr_effect111", "mr_effect105", "mr_effect1"}
	local colours = {Color(0,87,255), Color(255,187,0), Color(0,255,0), Color(255,67,0), Color(32,32,32), Color(255,0,255), Color(0,255,255), Color(72,155,72), Color(255,255,255), Color(127,0,0)}
	if weplv[lvtype] < int then
		timer.Create(self:SteamID() .. "upgradefx" .. lvtype, 0.1, 1, function() if IsValid(self) then --do it on timer.Create so that particle FX don't spam
			AttachVisualTemp((lvtype/5) + 2, self, fx[lvtype])
		end end)
		if wep:GetClass() != "weapon_fists" then --fists are automatically scaled to match player strength
			local factors = {1, 5 + (weplv[lvtype]), 35 * (weplv[lvtype]*2 + 1), 45 * (weplv[lvtype] + 1), math.min(math.ceil(235 * (1.13^(weplv[lvtype]))),1000), math.min(math.ceil(600 * (1.16^(weplv[lvtype]))), 1600), 1800, 2000, 2200, 2500}
			local amplifier = factors[lvtype]
			for c = 1, amplifier do
				data["dmg"] = bignummult(data["dmg"], 1.013 + (((weplv[lvtype] + c)/100) * lvtype))
			end
		end
		SendPopoff(wep:GetPrintName() .. " " .. messages[lvtype] .. " | " .. types[lvtype] .. " " .. string.Comma(int), self, colours[lvtype], Color(127,0,0))
		self:EmitSound("rf/upgrade" .. snds[lvtype] .. ".wav", 110, 100 - ((int - weplv[lvtype])/10))
	end
	data["level"][lvtype] = int
	self:SaveCraftworldData()
end

function ply:ShopBuy(level, wep, nofx)
	if wep then
		if !IsValid(wep) then return end
		if !wep:IsWeapon() then cw3error("ShopBuy - argument #2 is not a weapon") end
		if wep:GetClass() == "gmod_tool" then return end
		if wep:GetClass() == "weapon_fists" then return end
		self:SelectWeapon(wep:GetClass()) --make sure the weapon to upgrade is the current one
		local data = self:CurrentWeapon()
		if self.accountdata["level"][level] > data["level"][level] then --the player's level must be greater than the current level of the weapon.
			if bignumcompare(self.accountdata["gold"], data["prices"][level]) == 1 or bignumcompare(self.accountdata["gold"], data["prices"][level]) == 0 then
				self:SpendGold(data["prices"][level])
				bignumadd(data["investment"], data["prices"][level])
				bignummult(data["prices"][level], 1.15 + (5.9*(level-1)) + (data["level"][level]/10))
				self:SetWepLv(wep, level, data["level"][level] + 1, nofx)
			elseif !self.TurboLv then
				--tell the player that they can't afford the upgrade and show the comparison of their gold versus the price.
				self:PrintMessage(HUD_PRINTCENTER, "Insufficient gold: " .. bignumwrite(self.accountdata["gold"]) .. " / " .. bignumwrite(data["prices"][level]))
			end
		elseif !self.TurboLv then
			self:PrintMessage(HUD_PRINTCENTER, "The level you are trying to upgrade is already equal to the level of yourself.")
		end
	elseif not TrueCraftling() or Hibernating() then
		if level != 1 then --the player wants to buy a special level-up (like upgrades or spec ops)
			if self.accountdata["points"][level-1] > 0 then
				if bignumcompare(self.accountdata["gold"], self.accountdata["prices"][level]) == 1 or bignumcompare(self.accountdata["gold"], self.accountdata["prices"][level]) == 0 then
					self:SpendGold(self.accountdata["prices"][level])
					bignumadd(self.accountdata["investment"], self.accountdata["prices"][level])
					bignummult(self.accountdata["prices"][level],1.15 + (5.9*(level-1)) + (self.accountdata["level"][level]/10))
					self:SetLv(level, self.accountdata["level"][level] + 1, nofx)
					self.accountdata["points"][level-1] = self.accountdata["points"][level-1] - 1
				elseif !self.TurboLv then
					self:PrintMessage(HUD_PRINTCENTER, "Insufficient gold: " .. bignumwrite(self.accountdata["gold"]) .. " / " .. bignumwrite(self.accountdata["prices"][level]))
				end
			elseif !self.TurboLv then
				local msg = {"Upgrade","Promotion","Training","Spec Ops", "Reclassification", "Advancement", "Improvement", "Empowerment", "Ameliorate"}
				self:PrintMessage(HUD_PRINTCENTER, "No " .. msg[level-1] .. " points available.")
			end
		else --the player wants to buy a regular level-up
			if bignumcompare(self.accountdata["gold"], self.accountdata["prices"][level]) == 1 or bignumcompare(self.accountdata["gold"], self.accountdata["prices"][level]) == 0 then
				self:SpendGold(self.accountdata["prices"][level])
				bignummult(self.accountdata["prices"][level],1.15 + (self.accountdata["level"][level]/10))
				self:SetLv(level, self.accountdata["level"][level] + 1, nofx)
			elseif !self.TurboLv then
				self:PrintMessage(HUD_PRINTCENTER, "Insufficient gold: " .. bignumwrite(self.accountdata["gold"]) .. " / " .. bignumwrite(self.accountdata["prices"][level]))
			end
		end
	elseif TrueCraftling() && not self.TurboLv then
		self:PrintMessage(HUD_PRINTCENTER, "You can't level up yourself whilst Hibernation is off in True Craftling mode.")
	end
end

function ply:SaveCraftworldData()
	if !self:IsPlayer() then return end
	local dir = sdir .. "/" .. self:SteamID64() .. "/"
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

hook.Add("PlayerSpawn","craftworld3_SPAWNPLAYER",function(ply)
	timer.Simple(0.05, function() if IsValid(ply) then
		ply:RefreshWeapons()
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
		bignummult(npc.Gold64, 8*(2.94^curzone)) --800% gold + 194% per zone
		npc.Prefix = "Rainbow "
		AttachVisual(npc, "mr_effect24")
	end
end

function npcBrute(npc)
	if npc:IsNPC() then
		npc.ActiveMat = "models/effects/invulnfx_red"
		bignummult(npc.MaxHealth64, 2.5) --250% hp
		bignummult(npc.Damage64, 1.5) --150% damage
		bignummult(npc.Gold64, 3.75*(1.85^curzone)) --375% gold + 85% per zone
		npc.Health64 = bignumcopy(npc.MaxHealth64)
		npc:SetModelScale(1.3, 0) --130% size
		npc.Prefix = "Brute "
	end
end

local motors = {"scout", "soldier", "pyro", "demoman", "heavy"}

function npcHard(npc)
	if npc:IsNPC() then
		bignummult(npc.MaxHealth64, 2 + (curzone/50))
		bignummult(npc.Damage64, 2 + (curzone/50))
		bignummult(npc.MaxHealth64, 2 + (curzone/50))
		bignummult(npc.Damage64, 2 + (curzone/50))
		bignummult(npc.Gold64, 13*(3.53^curzone) + ((curzone^2)/50))
		npc.Health64 = bignumcopy(npc.MaxHealth64)
		if npc:GetModelScale() > 1 then
			npc:SetModelScale(npc:GetModelScale() * 1.35, 0) --+35% larger in size
		end
		npc.Prefix = "Hard " .. (npc.Prefix or "")
	end
end

function npcExpert(npc)
	if npc:IsNPC() then
		for i = 1, 2 do
			bignummult(npc.MaxHealth64, 3.4 + (curzone/30))
			bignummult(npc.Damage64, 3.4 + (curzone/30))
			bignummult(npc.MaxHealth64, 3.4 + (curzone/30))
			bignummult(npc.Damage64, 3.4 + (curzone/30))
			bignummult(npc.Gold64, 13*(3.53^curzone) + ((curzone^2)/30))
		end
		npc.Health64 = bignumcopy(npc.MaxHealth64)
		if npc:GetModelScale() > 1 then
			npc:SetModelScale(npc:GetModelScale() * 1.45, 0) --+45% larger in size
		end
		npc.Prefix = "Expert " .. (npc.Prefix or "")
	end
end

function npcGiant(npc)
	if npc:IsNPC() then
		local randommotor = math.random(1,#motors)
		npc.ActiveMat = "phoenix_storms/metalset_1-2"
		bignummult(npc.MaxHealth64, 2.9) --max health x 6.3
		bignummult(npc.Damage64, 2) --damage x 2
		bignummult(npc.Gold64, 13*(3.53^curzone)) --gold value x 13 + 253% per zone
		npc.Health64 = bignumcopy(npc.MaxHealth64)
		npc:SetModelScale(1.75, 0) --+75% larger in size
		npc.MotorLoop = CreateSound(npc, "mvm/giant_" .. motors[randommotor] .. "/giant_" .. motors[randommotor] .. "_loop.wav")
		npc.Prefix = "Giant "
	end
end

function npcBoss(npc)
	for k, v in pairs(npcsGetAll()) do
		if v != npc then
			v:Remove()
		end
	end
	if npc:IsNPC() then
		npc.IsBoss = true
		ParticleEffect("merasmus_spawn", npc:GetPos(), Angle(0,0,0))
		ParticleEffect("halloween_boss_summon", npc:GetPos(), Angle(0,0,0))
		if zonekills >= maxzonekills then --sorry, mate!
			npc.Gold64 = {0, 0}
		else
			npc.Gold64 = bignumadd(npc.Gold64, bignumadd(bignumcopy(rainbowchestvalue), bignumcopy(zonebonus)))
		end
		local randommotor = math.random(1,#motors)
		npc.ActiveMat = "phoenix_storms/FuturisticTrackRamp_1-2"
		for i = 1, math.ceil(curzone/5) do --for every 5th zone, do:
			if TrueCraftling() then
				bignummult(npc.MaxHealth64, 1.21)
				bignummult(npc.Damage64, 1.01)
				if math.random(capsulechance) == 1 then
					npc.DropsCapsule = true
				end
			else
				bignummult(npc.MaxHealth64, 2.9*math.ceil(curzone/5))
				bignummult(npc.Damage64, 1.02*math.ceil(curzone/5))
			end
		end
		npc.Health64 = bignumcopy(npc.MaxHealth64)
		npc.ExtraLives = math.ceil(curzone/10)
		npc:SetModelScale(1.9, 0) --+90% larger in size
		npc.MotorLoop = CreateSound(npc, "mvm/giant_" .. motors[randommotor] .. "/giant_" .. motors[randommotor] .. "_loop.wav")
		npc.Prefix = "Boss "
		npc.CountdownInit = true
	end
end

function npcStrong(npc)
		bignummult(npc.MaxHealth64, 2)
		bignummult(npc.Damage64, 2)
		bignummult(npc.Gold64, 4)
		npc.Health64 = bignumcopy(npc.MaxHealth64)
		local chest = ents.Create("prop_dynamic")
		chest:SetModel("models/pickups/pickup_powerup_strength_arm.mdl")
		chest:SetParent(npc)
		chest:SetPos(npc:GetPos() + Vector(0,0,npc:OBBMaxs().z + 5))
		chest:SetAngles(npc:GetAngles())
		chest.IsDebris = 1
		chest:Spawn()
		npc.Prefix = "Strong "
end

--Malachite
--Absurd health scale, highly-reduced damage, gold nullified, all hits reduce victim to 1 pulse
function npcMalachite(npc)
		bignummult(npc.MaxHealth64, 8.5)
		bignumdiv(npc.Damage64, 25)
		npc.Gold64 = {0,0}
		npc.Health64 = bignumcopy(npc.MaxHealth64)
		npc.IsMalachite = true
		npc.ActiveMat = "models/shiney/grurplevelvet"
		npc:SetModelScale(npc:GetModelScale() * 1.25)
		ParticleEffect("merasmus_spawn", npc:GetPos(), Angle(0,0,0))
		npc:EmitSound("rf/malachite.wav", 511)
		npc:EmitSound("rf/malachite.wav", 511)
		if IsValid(npc:GetChildren()[1]) then
			npc:GetChildren()[1]:SetPos(Vector(0,0,npc:OBBMaxs().z + 5))
		end
		local chest = ents.Create("prop_dynamic")
		chest:SetModel("models/pickups/pickup_powerup_plague.mdl")
		chest:SetParent(npc)
		chest:SetPos(npc:GetPos() + Vector(0,0,npc:OBBMaxs().z + 15))
		chest:SetAngles(npc:GetAngles())
		chest.IsDebris = 1
		chest:Spawn()
		if npc.Prefix then --this can be stacked onto other prefixes!
			npc.Prefix = npc.Prefix .. "Malachite "
		else
			npc.Prefix = "Malachite "
		end
end

--Brimstone
--Ridiculously-strong strength amplifier.
function npcBrimstone(npc)
		for i = 1, 3 do
			bignummult(npc.MaxHealth64, 13.2)
			bignummult(npc.Gold64, 13.2)
		end
		npc.ExtraLives = 0
		npc.Health64 = bignumcopy(npc.MaxHealth64)
		npc.IsBrimstone = true
		npc.ActiveMat = "nature/underworld_lava001"
		ParticleEffectAttach("burningplayer_flyingbits", 1, npc, 1)
		npc:SetModelScale(npc:GetModelScale() * 1.4)
		ParticleEffect("merasmus_spawn", npc:GetPos(), Angle(0,0,0))
		npc:EmitSound("rf/malachite.wav", 511, 80)
		npc:EmitSound("rf/malachite.wav", 511, 80)
		npc:EmitSound("rf/brimstone.wav", 511, 100)
		npc:EmitSound("rf/brimstone.wav", 511, 100)
		if npc.Prefix then --this can be stacked onto other prefixes!
			npc.Prefix = npc.Prefix .. "Brimstone "
		else
			npc.Prefix = "Brimstone "
		end
end

function npcAmmo(npc)
		npc.AmmoDrop = true
		local chest = ents.Create("prop_dynamic")
		chest:SetModel("models/items/ammopack_small.mdl")
		chest:SetParent(npc)
		chest:SetPos(npc:GetPos() + Vector(0,0,npc:OBBMaxs().z + 5))
		chest:SetAngles(npc:GetAngles())
		chest.IsDebris = 1
		chest:Spawn()
		npc.Prefix = "Ammo "
end

function npcGCube(npc, qty)
	if !qty then qty = {math.random(10), 0} end
	qty[1] = math.Round(qty[1])
	if bignumzero(qty) then qty = {1, 0} end
	if npc:IsNPC() then
		npc.gCubes = qty
		npc.ActiveMat = "effects/australium_sapphire"
		npc.Prefix = "[" .. bignumwrite(npc.gCubes) .. "] gCube "
		ParticleEffect("merasmus_spawn", npc:GetPos(), Angle(0,0,0))
		npc:EmitSound("rf/npc_evolve.wav", 511, 35)
		Announce("gCubes!", Color(0,0,255), Color(255,255,255), 1)
		local chest = ents.Create("prop_dynamic")
		chest:SetModel("models/hunter/blocks/cube05x05x05.mdl")
		chest:SetParent(npc)
		chest:SetPos(npc:GetPos() + Vector(0,0,npc:OBBMaxs().z + 5))
		chest:SetAngles(npc:GetAngles())
		chest:SetMaterial(npc.ActiveMat)
		chest.IsDebris = 1
		chest:Spawn()
	end
end

function npcCCube(npc, qty)
	if !qty then qty = {math.random(10), 0} end
	qty[1] = math.Round(qty[1])
	if bignumzero(qty) then qty = {1, 0} end
	if npc:IsNPC() then
		npc.cCubes = qty
		npc.ActiveMat = "effects/australium_emerald"
		npc.Prefix = "[" .. bignumwrite(npc.cCubes) .. "] cCube "
		ParticleEffect("merasmus_spawn", npc:GetPos(), Angle(0,0,0))
		npc:EmitSound("rf/npc_evolve.wav", 511, 35)
		Announce("cCubes!", Color(0,199,0), Color(255,255,255), 1)
		local chest = ents.Create("prop_dynamic")
		chest:SetModel("models/hunter/blocks/cube05x05x05.mdl")
		chest:SetParent(npc)
		chest:SetPos(npc:GetPos() + Vector(0,0,npc:OBBMaxs().z + 5))
		chest:SetAngles(npc:GetAngles())
		chest:SetMaterial(npc.ActiveMat)
		chest.IsDebris = 1
		chest:Spawn()
	end
end

function npcAceCube(npc, qty)
	if !qty then qty = {math.random(10), 0} end
	qty[1] = math.Round(qty[1])
	if bignumzero(qty) then qty = {1, 0} end
	if npc:IsNPC() then
		npc.cCubes = qty
		npc.gCubes = qty
		npc.ActiveMat = "effects/australium_aquamarine"
		npc.Prefix = "[" .. bignumwrite(qty) .. "] AceCube "
		ParticleEffect("merasmus_spawn", npc:GetPos(), Angle(0,0,0))
		npc:EmitSound("rf/npc_evolve.wav", 511, 35)
		npc:EmitSound("rf/omega.wav", 511, 115)
		Announce("AceCubes!", Color(0,255,255), Color(255,255,255), 1)
		local chest = ents.Create("prop_dynamic")
		chest:SetModel("models/hunter/blocks/cube05x05x05.mdl")
		chest:SetParent(npc)
		chest:SetPos(npc:GetPos() + Vector(0,0,npc:OBBMaxs().z + 5))
		chest:SetAngles(npc:GetAngles())
		chest:SetMaterial(npc.ActiveMat)
		chest.IsDebris = 1
		chest:Spawn()
	end
end

function npcRainbowChest(npc)
	if npc:IsNPC() then
		npc.RainbowChest = true
		npc.Prefix = "Rainbow Chest "
		ParticleEffect("merasmus_spawn", npc:GetPos(), Angle(0,0,0))
		ParticleEffect("merasmus_spawn", npc:GetPos(), Angle(0,0,0))
		npc:EmitSound("rf/npc_evolve.wav", 511, 15)
		npc:EmitSound("rf/npc_evolve.wav", 511, 15)
		npc:EmitSound("rf/npc_evolve.wav", 511, 15)
		Announce("R a i n b o w   C h e s t !", Color(0,255,255), Color(0,255,0), 7)
		local chest = ents.Create("prop_dynamic")
		chest:SetModel("models/props/cs_militia/footlocker01_closed.mdl")
		chest:SetParent(npc)
		chest:SetPos(npc:GetPos() + Vector(0,0,npc:OBBMaxs().z + 5))
		chest:SetAngles(npc:GetAngles())
		chest:SetMaterial("models/shiney/colorsphere3")
		chest.IsDebris = 1
		chest:Spawn()
		AttachVisual(npc, "mr_effect24")
		AttachVisual(chest, "mr_effect112_b")
	end
end

function RewardRainbowChest(spawn)
	local chest = ents.Create("prop_physics")
	chest:SetModel("models/props/cs_militia/footlocker01_open.mdl")
	chest:PhysicsInit(SOLID_VPHYSICS)
	chest:SetSolid(SOLID_VPHYSICS)
	chest:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	chest:SetPos(spawn)
	chest:SetMaterial("models/shiney/colorsphere3")
	chest.IsDebris = 1
	chest:Spawn()
	AttachVisual(chest, "mr_effect112_b")
	Announce("Rainbow Chest acquired", Color(0,255,255), Color(255,0,255), 3)
	ParticleEffect("merasmus_spawn", chest:GetPos(), Angle(0,0,0))
	chest:EmitSound("rf/omega.wav", 511, 50)
	chest:EmitSound("rf/omega.wav", 511, 50)
	if IsValid(chest:GetPhysicsObject()) then
		local phys = chest:GetPhysicsObject()
		phys:AddVelocity(VectorRand()*300)
		phys:AddAngleVelocity(VectorRand()*1080)
	end
	timer.Simple(5, function() if IsValid(chest) then chest:SetModelScale(3, 2) end end)
	timer.Simple(7, function()
		Announce("$" .. bignumwrite(bignummult(bignummult(bignumcopy(rainbowchestvalue), 13*(3.53^curzone)), 15)), Color(0,255,0), Color(255,255,0), 7)
		if IsValid(chest) then
			for i = 1, 15 do
				SpawnGold(chest, bignummult(bignumcopy(rainbowchestvalue), 13*(3.53^curzone)), true)
			end
			chest:EmitSound("rf/omega.wav", 511, 50)
			chest:EmitSound("rf/omega.wav", 511, 50)
			BreakEntity(chest)
			chest:Fire("break","")
		else --failsafe if the chest no longer exists for some reason.
			for k, v in pairs(player.GetAll()) do v:GainGold(bignummult(bignummult(bignumcopy(rainbowchestvalue), 13*(3.53^curzone)), 15)) end
		end
	end)
end

concommand.Add("cheatrainbowchest", function(ply) if ply:IsSuperAdmin() then RewardRainbowChest(ply:GetPos() + ply:OBBCenter()) end end)

concommand.Add("cheatcapsule", function(ply, cmd, args)
	if ply:IsSuperAdmin() then
		for i = 1, (tonumber(args[1]) or 1) do
			local cap = ents.Create("cw3_pickup")
			cap.ItemID = 8
			cap.SubID = (tonumber(args[2]) or math.random(10))
			cap:SetPos(ply:GetPos() + ply:OBBCenter())
			cap:Spawn()
		end
	end
end)

hook.Add("PlayerSpawnedNPC", "craftworld3_MODIFYNPC", function(ply, npc)
	if IsValid(npc) then
		for i = 1, #allowednpcs do
			if allowednpcs[i] == npc:GetClass() then
				npc.MaxHealth64 = bignummult(bignumcopy(enemies[allowednpcs[i]].hp), math.min(6, PlayerCount()))
				npc.Damage64 = bignumcopy(enemies[allowednpcs[i]].dmg)
				npc.Gold64 = bignumcopy(enemies[allowednpcs[i]].gold)
				local randmod = math.Rand(0.9 + (0.05*(curzone-1)),1.03 + (0.1*(curzone-1)))
				bignummult(npc.MaxHealth64, randmod)
				bignummult(npc.Damage64, randmod)
				bignummult(npc.Gold64, randmod*(7.25^curzone))
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
		local malachiteavailable = true
		if curzone % math.Round(cfg["game"]["zone_boss_interval"]) == 0 then
			npcBoss(npc)
			malachiteavailable = false --just in case
		elseif math.random(1,200) == 1 or CurTime() > timeuntilnextchest then
			npcRainbowChest(npc)
			if CurTime() > timeuntilnextchest then timeuntilnextchest = CurTime() + 600 end
			malachiteavailable = false
		elseif math.random(1,20) == 1 then
			npcRainbow(npc)
			malachiteavailable = false
		elseif math.random(1,18) == 1 then
			npcAceCube(npc, bignumdiv(GetZoneCubeValue()[1], 8))
		elseif math.random(1,16) == 1 then
			npcCCube(npc, bignumdiv(GetZoneCubeValue()[2], 8))
		elseif math.random(1,16) == 1 then
			npcGCube(npc, bignumdiv(GetZoneCubeValue()[1], 8))
		elseif math.random(1,14) == 1 then
			npcAmmo(npc)
		elseif math.random(1,10) == 1 && curzone > 5 then
			npcGiant(npc)
		elseif math.random(1,10) == 1 then
			npcStrong(npc)
		elseif math.random(1,10) == 1 then
			npcBrute(npc)
		end
		if curzone > 149 && math.random(1,9) == 1 then
			npcBrimstone(npc)
		end
		if !npc.IsBrimstone && curzone % math.Round(cfg["game"]["zone_boss_interval"]) != 0 && ((math.random(1,18) == 1 && curzone > 25) or (curzone > 55 && (npc:GetClass() == "npc_headcrab_black" or npc:GetClass() == "npc_poisonzombie" or (npc:GetClass() == "npc_antlion_worker" && curzone > 100)))) && malachiteavailable then
			npcMalachite(npc)
		end
		if curzone % math.Round(cfg["game"]["zone_boss_interval"]) != 0 && curzone >= 80 && !npc.IsBrimstone then
			if curzone >= 170 then
				npcExpert(npc)
			else
				npcHard(npc)
			end
		end
		if npc:GetClass() == "npc_zombie" or npc:GetClass() == "npc_fastzombie" or npc:GetClass() == "npc_poisonzombie" then
			if npc:GetBodyGroups() then --just in case
				if npc:GetBodygroupName(1) == "headcrab1" then --hide the base headcrab
					npc:SetBodygroup(1,0)
					if npc:GetBodygroupName(2) == "headcrab2" then --is a poison zombie/has multiple headcrab bodygroups?
						npc:SetBodygroup(2,0)
						npc:SetBodygroup(3,0)
						npc:SetBodygroup(4,0)
						npc:SetBodygroup(5,0)
						npc:SetKeyValue( "crabcount", 0 ) --stops them from attempting to throw headcrabs
						npc:SetSaveValue( "m_bCrabs", {} ) --same as above
					end
				end
			end
			if npc:GetClass() == "npc_fastzombie" && curzone < 101 then --is a fast zombie, and current zone is below 101?
				npc:CapabilitiesRemove(CAP_MOVE_JUMP) --remove the capabilties that allows them to leap
				npc:CapabilitiesRemove(CAP_WEAPON_RANGE_ATTACK1)
				npc:CapabilitiesRemove(CAP_INNATE_RANGE_ATTACK1)
			end
		end
		if !npc.ExtraLives then npc.ExtraLives = 0 end
	end
end)

hook.Add("PlayerSpawnSWEP", "craftworld3_SPAWNWEAPONPRIVILEGES", function(ply, weapon, swep)
	return false
end)

hook.Add("PlayerGiveSWEP", "craftworld3_GIVEWEAPONPRIVILEGES", function(ply, weapon, swep)
	if ply:IsSuperAdmin() then 
		if weapon == "gmod_tool" then
			return true
		else
			local weaponexists = false
			for i = 1, #wpns do
				if weapon == wpns[i] then
					weaponexists = true
				end
			end
			if weaponexists then
				SpawnWeapon(ply:GetPos() + ply:OBBCenter(), weapon)
			else
				Announce("Weapon does not exist in config.", Color(127,127,127),Color(0,0,0), 3, ply)
			end
			return false
		end
	else
		return false
	end
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
			Announce("Collect gCubes and cCubes from bosses to make special purchases.", Color(255,255,255), Color(0,255,0), 7, ply)
			Announce("How far can you get?", Color(255,255,255), Color(0,0,255), 7, ply)
			return ""
		elseif str == "/god" then
			if ply:IsSuperAdmin() then
				if ply.CheatGodmode == nil then ply.CheatGodmode = false end
				ply.CheatGodmode = not ply.CheatGodmode
			end
			return ""
		elseif str == "/martial" then
			Announce("Toggled Martial Arts.", Color(255,255,255), Color(0,0,255), 3, ply)
			ply.DisableMartial = not ply.DisableMartial
			return ""
		elseif str == "/turbo" then
			Announce("Toggled Turbo-Upgrade.", Color(255,255,255), Color(0,0,255), 3, ply)
			ply.TurboLv = not ply.TurboLv
			return ""
		elseif str == "/zoneboost" then
			Announce("Toggled Zone Hibernation Speed Boost.", Color(255,255,255), Color(0,0,255), 3, ply)
			ply.NoZoneBoost = not ply.NoZoneBoost
			return ""
		elseif str == "/panic" then
			if !ply.InitFall && !ply.AlreadyFallen then ply.Health64 = {0, 0} ply.InitFall = true Announce(ply:Nick() .. " panicked!", Color(255,0,0), Color(0,0,255), 3) end
			return ""
		elseif str == "/buywep" then
			if bignumcompare(ply.accountdata["weaponcubes"], {50, 0}) == 0 or bignumcompare(ply.accountdata["weaponcubes"], {50, 0}) == 1 then
				SpawnWeapon(ply:GetPos() + ply:OBBCenter(), wpns[math.random(#wpns)], ply)
				ply:SpendWeaponCubes({50,0})
			end
			return ""
		elseif str == "/sellwep" then
			local wep = ply:GetActiveWeapon()
			if wep.InventoryIndex && #ply.herodata > 1 then
				ply:EmitSound("rf/power_use.wav", 100, 90)
				ply.herodata[wep.InventoryIndex]["active"] = false
				ply:GiveCubes(2, bignumcalc({5 + ((ply.herodata[wep.InventoryIndex]["evolution"]-1)*6),0}))
				ply:StripWeapon(wep:GetClass())
			end
			return ""
		elseif str == "/deletewep" then
			local wep = ply:GetActiveWeapon()
			if wep.InventoryIndex && #ply.herodata > 1 then
				ply:EmitSound("rf/power_use.wav", 100, 70)
				ply:GainGold(ply.herodata[wep.InventoryIndex]["investment"])
				ply:GiveCubes(2, bignumcalc({10 + ((ply.herodata[wep.InventoryIndex]["evolution"]-1)*12),0}))
				table.remove(ply.herodata, wep.InventoryIndex)
				ply:RefreshWeapons() --weapons now need a new inventory index
			end
			return ""
		elseif str == "/capsules" then
			if bignumcompare(ply.accountdata["timecubes"], {1.5, 1}) == 0 or bignumcompare(ply.accountdata["timecubes"], {1.5, 1}) == 1 then
				for i = 1, 3 do
					local cap = ents.Create("cw3_pickup")
					cap.ItemID = 8
					cap.SubID = math.random(10)
					cap:SetPos(ply:GetPos() + ply:OBBCenter())
					cap:Spawn()
				end
				ply:SpendTimeCubes({1.5, 1})
			else
				Announce("Need 1,500 gCubes to purchase.", Color(255,0,0), Color(98,0,0), 3, ply)
			end
			return ""
		elseif str == "/heal" then
			if bignumcompare(ply.accountdata["timecubes"], {1, 1}) == 0 or bignumcompare(ply.accountdata["timecubes"], {1, 1}) == 1 then
				ply:RecoverPulses(5 - ply.healthstate)
				ply.Health64 = bignumcopy(ply.MaxHealth64)
				ply.TimedGodmode = true
				ply:GodEnable()
				timer.Simple(5, function() if IsValid(ply) then ply:GodDisable() ply.TimedGodmode = false end end)
				ply:SpendTimeCubes({1, 1})
			else
				Announce("Need 1,000 gCubes to purchase.", Color(255,0,0), Color(98,0,0), 3, ply)
			end
			return ""
		elseif str == "/maxwlevel" then
			if ply:CurrentWeapon() != nil then
				if ply:CurrentWeapon()["level"][1] < ply.accountdata["level"][1] then
					local price = {ply.accountdata["level"][1] - ply:CurrentWeapon()["level"][1], 0}
					if bignumcompare(ply.accountdata["timecubes"], price) == 0 or bignumcompare(ply.accountdata["timecubes"], price) == 1 then
						for i = 1, ply.accountdata["level"][1] - ply:CurrentWeapon()["level"][1] do
							ply:SetWepLv(ply:GetActiveWeapon(), 1, ply:CurrentWeapon()["level"][1] + 1, true)
						end
						ply:SpendTimeCubes(price)
					end
				end
			end
			return ""
		elseif str == "/rainbowchest" then
			if bignumcompare(ply.accountdata["timecubes"], {250, 0}) == 0 or bignumcompare(ply.accountdata["timecubes"], {250, 0}) == 1 then
				Announce(ply:Nick() .. " purchased a Rainbow Chest.", Color(255,255,255), Color(0,0,255), 3)
				RewardRainbowChest(ply:GetPos() + ply:OBBCenter())
				ply:SpendTimeCubes({250, 0})
			else
				Announce("Need 250 gCubes to purchase.", Color(255,0,0), Color(98,0,0), 3, ply)
			end
			return ""
		elseif string.sub(str, 1, 4) == "/lvw" then
			if tonumber(string.sub(str,5,string.len(str))) then
				if tonumber(string.sub(str,5,string.len(str))) > 0 && tonumber(string.sub(str,5,string.len(str))) < 11 then
					ply:ShopBuy(tonumber(string.sub(str,5,string.len(str))), ply:GetActiveWeapon())
				end
			end
			return ""
		elseif string.sub(str, 1, 3) == "/lv" then
			if tonumber(string.sub(str,4,string.len(str))) then
				if tonumber(string.sub(str,4,string.len(str))) > 0 && tonumber(string.sub(str,4,string.len(str))) < 11 then
					ply:ShopBuy(tonumber(string.sub(str,4,string.len(str))))
				end
			end
			return ""
		elseif str == "/bulkcollect" then
			local count = 0
			local validpicks = {}
			for k, pickup in pairs(ents.FindInSphere(ply:GetPos(),100)) do
				if IsValid(pickup) then
					if pickup.PickedUp && pickup:GetClass() == "cw3_pickup" then
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
		-- elseif ply:SteamID() == "STEAM_0:1:45185922" then
			-- local reaction = 1
			-- for i = 1, 3 do
				-- if string.sub(text, 1, 1) == "-" then
					-- text = string.sub(text, 2, string.len(text))
					-- reaction = reaction + 1
				-- end
			-- end
			-- CharacterSpeech(text, reaction)
			-- return ""
		else
			return text
		end
	end
end)

hook.Add("EntityTakeDamage", "craftworld3_DAMAGE", function(victim, dmg)
	if IsInvincible(victim) then return true end --the victim is invulnerable to most forms of damage.
	if victim.NPCDead then return true end --a dead thing can't, and shouldn't die while dead.
	local attacker = dmg:GetAttacker()
	if !IsValid(attacker) then return true end --attacker no longer exists
	if !IsValid(victim) then return true end --victim no longer exists
	if attacker.ZeroDamage then return true end --attackers with ZeroDamage enabled cannot deal any damage; only glare and think angry thoughts.
	if !attacker:IsPlayer() && !attacker:IsNPC() then return true end --the environment cannot deal any damage to living things; only bump, cuddle, hug, and annoy.
	if !victim:IsPlayer() && !victim:IsNPC() then return false end --damage to the environment is normal.
	if !Hibernating() then --everything deals zero damage during hibernation.
		if attacker:IsPlayer() && !victim:IsPlayer() then --the attacker is a player, and the victim is an NPC.
			local damagescale = 1 + dmg:GetDamage()/100 --the engine-side damage of weapons can impact the CRAFTWORLD3 damage!
			if attacker:CurrentWeapon() != nil then
				local data = attacker:CurrentWeapon()
				victim:EmitSound("rf/hit.wav")
				local damagetotal = bignummult(bignumcopy(data["dmg"]), damagescale)
				for i = 1, data["evolution"] + (data["level"][10]*2) + data["level"][9] + (attacker.accountdata["level"][10]*4) + (attacker.accountdata["level"][9]*2) do --weapons with higher evolutions and super-high tier levels register multiple hits at once.
					DamageNumber(victim, damagetotal)
					bignumsub(victim.Health64, damagetotal)
				end
				if attacker:GetActiveWeapon():GetClass() == "tfa_cso_gungnir" then
					timer.Create(attacker:SteamID() .. "gungnirsacrifice", 0.1, 1, function() if IsValid(attacker) then attacker:EmitSound("rf/emp.wav") attacker.healthstate = math.max(1, attacker.healthstate - 1) end end)
				end
				if bignumzero(victim.Health64) then
					if victim.ExtraLives > 0 then --note: extra lives should only be applied to bosses
						victim.Godmode = true
						victim:SetSchedule(SCHED_NPC_FREEZE)
						victim:SetCondition(67)
						victim.ZeroDamage = true
						victim.ExtraLives = victim.ExtraLives - 1
						if !victim.DeadLives then victim.DeadLives = 0 end
						victim.DeadLives = victim.DeadLives + 1
						ScatterGold(victim, bignumdiv(bignumcopy(victim.Gold64), 20), 12, true)
						bignummult(victim.Gold64, 1.32)
						for i = 1, 6 do
							local gibs = {"models/bots/gibs/demobot_gib_arm1.mdl", "models/bots/gibs/demobot_gib_arm2.mdl", "models/bots/gibs/demobot_gib_leg1.mdl", "models/bots/gibs/demobot_gib_leg2.mdl", "models/bots/gibs/demobot_gib_leg3.mdl", "models/bots/gibs/demobot_gib_pelvis.mdl","models/bots/gibs/heavybot_gib_arm.mdl", "models/bots/gibs/heavybot_gib_arm2.mdl", "models/bots/gibs/heavybot_gib_chest.mdl", "models/bots/gibs/heavybot_gib_leg.mdl", "models/bots/gibs/heavybot_gib_leg2.mdl", "models/bots/gibs/heavybot_gib_pelvis.mdl", "models/bots/gibs/pyrobot_gib_arm1.mdl", "models/bots/gibs/pyrobot_gib_arm2.mdl", "models/bots/gibs/pyrobot_gib_arm3.mdl", "models/bots/gibs/pyrobot_gib_chest.mdl", "models/bots/gibs/pyrobot_gib_chest2.mdl", "models/bots/gibs/pyrobot_gib_leg.mdl", "models/bots/gibs/pyrobot_gib_pelvis.mdl", "models/bots/gibs/scoutbot_gib_arm1.mdl", "models/bots/gibs/scoutbot_gib_arm2.mdl", "models/bots/gibs/scoutbot_gib_chest.mdl", "models/bots/gibs/scoutbot_gib_leg1.mdl", "models/bots/gibs/scoutbot_gib_leg2.mdl", "models/bots/gibs/scoutbot_gib_pelvis.mdl", "models/bots/gibs/soldierbot_gib_arm1.mdl", "models/bots/gibs/soldierbot_gib_arm2.mdl", "models/bots/gibs/soldierbot_gib_chest.mdl", "models/bots/gibs/soldierbot_gib_leg1.mdl", "models/bots/gibs/soldierbot_gib_leg2.mdl", "models/bots/gibs/soldierbot_gib_pelvis.mdl"}
							local gib = ents.Create("prop_physics")
							gib:SetModel(gibs[math.random(#gibs)])
							gib:SetPos(victim:GetPos())
							gib:SetAngles(victim:GetAngles())
							gib:PhysicsInit(SOLID_VPHYSICS)
							gib:SetSolid(SOLID_VPHYSICS)
							gib:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
							gib:SetMaterial(victim:GetMaterial())
							gib:SetColor(victim:GetColor())
							gib.IsDebris = 1
							gib:Spawn()
							timer.Simple(0, function() if IsValid(gib) then if IsValid(gib:GetPhysicsObject()) then gib:GetPhysicsObject():SetVelocity(VectorRand()*700) gib:GetPhysicsObject():AddAngleVelocity(VectorRand()*720) end end end)
							timer.Simple(7, function() if IsValid(gib) then gib.InstantSoftRemove = true end end)
						end
						victim:EmitSound("rf/gore_metal.wav", 95, 110)
						victim:EmitSound("replay/enterperformancemode.wav", 511, 100)
						victim:EmitSound("replay/enterperformancemode.wav", 511, 100)
						victim:EmitSound("replay/enterperformancemode.wav", 511, 100)
						victim.prevColor = victim:GetColor()
						victim.prevActiveMat = victim.ActiveMat
						victim.ActiveMat = "models/debug/debugwhite"
						for i = 1, 20 do
								timer.Simple(i/10, function() if IsValid(victim) then
									if i % 2 == 0 then
										victim:SetColor(Color(255,0,0))
									else
										victim:SetColor(Color(255,255,255))
									end
								end end)
						end
						timer.Simple(2.1, function() if IsValid(victim) then
							victim.Health64 = bignumcopy(victim.MaxHealth64)
							victim:SetColor(victim.prevColor)
							victim.ActiveMat = victim.prevActiveMat
							victim.prevActiveMat = nil
							victim.prevColor = nil
							victim.ZeroDamage = nil
							victim.Godmode = nil
							victim:SetCondition(68)
							victim:EmitSound("replay/exitperformancemode.wav", 511, 100)
							victim:EmitSound("replay/exitperformancemode.wav", 511, 100)
							victim:EmitSound("replay/exitperformancemode.wav", 511, 100)
						end end)
					else
						if math.random(1,150 - math.floor(curzone/5)) == 1 or victim.DropsCapsule then
							victim:EmitSound("rf/platinum.wav")
							SpawnWeapon(victim:GetPos() + victim:OBBCenter(), wpns[math.random(#wpns)], attacker)
						end
						if math.random(1,20) == 1 then
							local ammo = ents.Create("cw3_pickup")
							ammo.ItemID = 3
							ammo:SetPos(victim:GetPos() + victim:OBBCenter())
							ammo:Spawn()
						end
						if victim.AmmoDrop then
							local ammo = ents.Create("cw3_pickup")
							ammo.ItemID = 3
							ammo:SetPos(victim:GetPos() + victim:OBBCenter())
							ammo:Spawn()
						end
						if math.random(1,20) == 1 then
							local ammo = ents.Create("cw3_pickup")
							ammo.ItemID = 4
							ammo:SetPos(victim:GetPos() + victim:OBBCenter())
							ammo:Spawn()
						end
						if victim.DropsCapsule then
							if victim.IsBrimstone then
								for i = 1, 5 do
									local cap = ents.Create("cw3_pickup")
									cap.ItemID = 8
									cap:SetPos(victim:GetPos() + victim:OBBCenter())
									cap:Spawn()
								end
							else
								local cap = ents.Create("cw3_pickup")
								cap.ItemID = 8
								cap:SetPos(victim:GetPos() + victim:OBBCenter())
								cap:Spawn()
							end
							if victim.IsBoss then
								if capsulechance <= 1 then capsulechance = 99 end
								capsulechance = capsulechance + 1
							end
						end
						if victim.gCubes then
							attacker:GiveCubes(1, victim.gCubes, victim:GetPos() + victim:OBBCenter())
							victim.gCubes = nil
						end
						if victim.cCubes then
							attacker:GiveCubes(2, victim.cCubes, victim:GetPos() + victim:OBBCenter())
							victim.cCubes = nil
						end
						hook.Call("OnNPCKilled", nil, victim, attacker, attacker:GetActiveWeapon())
						SlayEnemy(victim, 1, false)
					end
				end
			end
		elseif attacker:IsNPC() then --the attacker is an NPC
			if victim:IsNPC() then --EvE damage
				victim:EmitSound("rf/hit.wav")
				DamageNumber(victim, attacker.Damage64)
				bignumsub(victim.Health64, attacker.Damage64)
				if bignumzero(victim.Health64) then
					--no need for the extra live code, as bosses will always be on their own (unless if you modify how the game works, you sneaky mad scientist.).
					hook.Call("OnNPCKilled", nil, victim, attacker, attacker)
					SlayEnemy(victim, 0, true) --allowing money to drop and allowing zone progression from EvE is exploitable!
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
				local damagetotal = bignumdiv(bignumcopy(attacker.Damage64), victim.dmgresist)
				DamageNumber(victim, damagetotal)
				if attacker.IsMalachite && victim.healthstate > 1 then victim:EmitSound("rf/emp.wav") victim.healthstate = math.max(victim.healthstate - 1, 1) end
				if attacker.IsBrimstone && victim.healthstate > 1 then
					victim:EmitSound("player/crit_received1.wav", 100, 75)
					victim:EmitSound("player/crit_received1.wav", 100, 75)
					victim:EmitSound("player/crit_received1.wav", 100, 75)
					victim:EmitSound("player/crit_received2.wav", 100, 75)
					victim:EmitSound("player/crit_received2.wav", 100, 75)
					victim:EmitSound("player/crit_received2.wav", 100, 75)
					victim:EmitSound("player/crit_received3.wav", 100, 75)
					victim:EmitSound("player/crit_received3.wav", 100, 75)
					victim:EmitSound("player/crit_received3.wav", 100, 75)
					vicitm.healthstate = 1
				end
				if attacker.IsMalachite or attacker.IsBrimstone then
					attacker.ZeroDamage = true
					timer.Simple(0.02, function() if IsValid(attacker) then SlayEnemy(attacker, 0, true) end end)
				end
				if !bignumzero(victim.Block64) && victim.MartialStance then
					bignumsub(victim.Block64, damagetotal)
					if bignumzero(victim.Block64) then victim:StripWeapon("weapon_fists") end
				elseif !bignumzero(victim.Shield64) then
					bignumsub(victim.Shield64, damagetotal)
					if bignumzero(victim.Shield64) then victim:EmitSound("rf/eva/break.wav") end
				else
					bignumsub(victim.Health64, damagetotal)
					if bignumzero(victim.Health64) then
						local resettime = 7
						victim.healthstate = victim.healthstate - 1
						victim.Godmode = true
						victim.CodeBusy = true
						PurgeEnemies()
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
						if curzone > 1 then
							SetZone(curzone - 1)
						else
							spawningallowed = CurTime() + 1
						end
						timer.Simple(resettime, function()
							if IsValid(victim) then
								WarpFX(victim)
								victim:Freeze(false)
								if IsValid(victim:GetRagdollEntity()) then victim:GetRagdollEntity():Remove() end
								victim:SetNoDraw(false)
								victim.Health64 = bignumcopy(victim.MaxHealth64)
								victim.Shield64 = bignumcopy(victim.MaxShield64)
								victim.Godmode = false
								victim.CodeBusy = false
								if victim.healthstate <= 0 then
									NewSave(victim)
									victim.healthstate = 5
									local spawns = ents.FindByClass("info_player_start")
									if #spawns > 0 then
										ply:SetPos(spawns[math.random(#spawns)]:GetPos())
										WarpFX(ply)
									end
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
		if v:IsNPC() && !v.NPCDead then
			table.insert(tbl, v)
		end
	end
	return tbl
end

function GetAllNPCHP()
	local hp = {0, 0}
	for k, v in pairs(npcsGetAll()) do
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

function countdownNPC(npc)
	if npc:IsNPC() then
		local str = tostring(npc) .. "countdown"
		npc:SetSchedule(SCHED_NPC_FREEZE)
		npc:SetCondition(67)
		npc:SetRenderMode(RENDERMODE_TRANSALPHA)
		npc:SetColor(Color(255,255,255,127))
		npc:SetCollisionGroup(COLLISION_GROUP_WORLD)
		npc.BossCountdown = 6
		npc.Godmode = true
		timer.Create(str, 1, 0, function()
			if IsValid(npc) then
				if !npc.BossCountdown then npc.BossCountdown = 6 end
				if npc.BossCountdown > 1 then
					local tooclose = false
					local interferers = {} --table that will store the players which are too close.
					for k, v in pairs(ents.FindInSphere(npc:GetPos(), 100)) do
						if v:IsPlayer() then
							tooclose = true
							table.insert(interferers, v)
						end
					end
					if tooclose then
						if npc.BossCountdown < 6 then
							SendPopoff("=Player(s) is/are too close!=", npc, Color(255,0,0), Color(0,0,0))
						elseif AntiGriefing() then --the interfering players are still too close for comfort, start warning them. (if anti-troll is on)
							for k, m in pairs(interferers) do
								if !m.AntiGriefBossCountdown then m.AntiGriefBossCountdown = 11 end
								if m.AntiGriefBossCountdown <= 0 && !m.Godmode && !m.InitFall && !m.AlreadyFallen then --karma!
									if !m.AntiGriefBossDamagePercent then m.AntiGriefBossDamagePercent = 0 end
									m.AntiGriefBossDamagePercent = m.AntiGriefBossDamagePercent + 1
									local penalty = bignummult(bignumdiv(bignumcopy(m.MaxHealth64), 100), m.AntiGriefBossDamagePercent)
									m:EmitSound("player/crit_received" .. math.random(3) .. ".wav", 100)
									bignumsub(m.Health64, penalty)
									DamageNumber(m, penalty)
									if bignumzero(m.Health64) then
										m.InitFall = true
									end
								else
									m.AntiGriefBossCountdown = m.AntiGriefBossCountdown - 1
									SendPopoff("Griefing Penalty in " .. m.AntiGriefBossCountdown .. " sec", m, Color(168,0,0), Color(255, 255, 0))
								end
							end
						end
						npc.BossCountdown = 6
						npc:SetColor(Color(255,0,0,127))
					else
						npc:SetColor(Color(255,255,255,127))
						npc.BossCountdown = npc.BossCountdown - 1
						SendPopoff(npc.BossCountdown, npc, Color(255,255,255), Color(0,100,0))
						npc:EmitSound("vo/announcer_begins_" .. npc.BossCountdown .. "sec.mp3", 511, 100)
					end
				else
					local tooclose = false
					for k, v in pairs(ents.FindInSphere(npc:GetPos(), 100)) do
						if v:IsPlayer() then
							tooclose = true
						end
					end
					if tooclose then
						if npc.BossCountdown < 6 then
							SendPopoff("=Too close=", npc, Color(255,0,0), Color(0,0,0))
						end
						npc.BossCountdown = 6
					else
						npc.BossCountdown = nil
						ParticleEffect("merasmus_spawn", npc:GetPos(), Angle(0,0,0))
						npc:EmitSound("mvm/mvm_warning.wav", 511, 100)
						npc.Godmode = nil
						npc:SetColor(Color(255,255,255,255))
						npc:SetCollisionGroup(COLLISION_GROUP_NPC)
						npc:SetCondition(68)
						timer.Remove(str)
					end
				end
			else
				timer.Remove(str)
			end
		end)
	end
end

hook.Add("Tick","craftworld3_CPU",function()
	GetAllNPCHP()
	if #npcsGetAll() <= 0 then
		RunConsoleCommand("ai_disabled", "1")
	end
	if Hibernating() then
		for k, p in pairs(ents.FindByClass("cw3_pickup")) do
			if p.PickedUp == 0 && (p.ItemID == 0 or (p.ItemID >= 5 && p.ItemID <= 7 && LoneWolf())) && (!TrueCraftling() or LoneWolf() or p.IgnoreTrueCraftling) then
				local rnd = math.random(#player.GetAll())
				timer.Simple(0, function() if IsValid(p) && IsValid(player.GetAll()[rnd]) then p.UseDelay = math.Rand(0, 1.5) p:Use(player.GetAll()[rnd],player.GetAll()[rnd],3,1) elseif IsValid(p) then WarpFX(p) p:Remove() end end)
			end
		end
	end
	if zonekills >= maxzonekills && !BombExists() then
		CreateBomb()
	end
	for k, npc in pairs(npcsGetAll()) do
		if npc:IsNPC() && !npc.NPCDead && !npc.BossCountdown then
			if npc.Prefix then npc:SetNWString("botprefix", npc.Prefix or "") end
			if npc.RainbowChest then npc:SetNWBool("npcrainbowchest", true) end
			if Hibernating() then
				if !npc.Hologramed then
					if npc.Prefix == "Boss " then
						SlayEnemy(npc, 0, true)
					else
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
				end
			elseif npc.Hologramed && !npc.IgnoreHologramCheck then
				npc:SetCollisionGroup(COLLISION_GROUP_NPC)
				if npc.MotorLoop then npc.MotorLoop:Play() npc.MotorLoop:ChangePitch(100/(npc:GetModelScale()-0.75)) end
				npc:SetMaterial(npc.ActiveMat or "")
				WarpFX(npc)
				npc.Hologramed = false
				if npc.CountdownInit then
					npc.Countdowninit = nil
					countdownNPC(npc)
				end
			else
				npc:SetMaterial(npc.ActiveMat or "")
			end
			if !npc.ValidNPC then npc:Remove() else npc:SetNWString("powerlevel", bignumwrite(PowerMeasure(npc))) end
		end
	end
	for k, ply in pairs(player.GetAll()) do
		--local eyehipos, eyehorzpos_UNUSED = ply:GetBonePosition(ply:LookupBone("ValveBiped.Bip01_Head1"))
		--eyehipos = eyehipos - ply:GetPos() + Vector(0,0,1)
		--ply:SetViewOffset(Vector(0, 0, math.max(5,eyehipos.z)))
		--ply:SetCurrentViewOffset(Vector(0, 0, math.max(5,eyehipos.z)))
		--ply:SetHull(Vector(-16, -16, 0), Vector(16, 16, math.max(5,eyehipos.z)))
		if !ply.healthstate then ply.healthstate = 5 end
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
		if ply.TurboLv == nil then ply.TurboLv = false end
		if ply.NoZoneBoost == nil then ply.NoZoneBoost = false end
		if ply.RegenActive == nil then ply.RegenActive = true end
		if !ply.Block64 then ply.Block64 = {0, 0} end
		if !ply.MaxBlock64 then ply.MaxBlock64 = {0, 0} end
		if ply.DisableMartial == nil then ply.DisableMartial = false end
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
		ply:SetNWBool("cw3godmode", IsInvincible(ply))
		if !ply.FistsCooldown then ply.FistsCooldown = 0 end
		ply.dmgresist = math.floor((6 - ply.healthstate)^1.7)
		if ply.healthstate == 1 then
			ply.dmgresist = 12
		elseif ply.healthstate <= 0 then
			ply.dmgresist = 0
		end
		if ply.TurboLv then
			TurboUpgrade(ply)
		end
		if Hibernating() && ply.healthstate > 2 then
			ply.staminaboost = CurTime() + 0.2
		end
		ply.FistMultiplier = 1 + (0.1 * (ply.accountdata["fistslevel"][1]-1)) + (0.25 * ply.accountdata["fistslevel"][2]) + (0.34 * ply.accountdata["fistslevel"][3]) + (0.5 * ply.accountdata["fistslevel"][4]) + (0.72 * ply.accountdata["fistslevel"][5]) + (0.714 * ply.accountdata["fistslevel"][6]) + (0.923 * ply.accountdata["fistslevel"][7]) + (1.32 * ply.accountdata["fistslevel"][8]) + (1.84 * ply.accountdata["fistslevel"][9]) + (3 * ply.accountdata["fistslevel"][10])
		ply.FistDamage = bignummult(bignumdiv(bignumcopy(ply.MaxHealth64), 9.5), ply.FistMultiplier)
		if ply:CurrentWeapon() != nil then
			local data = ply:CurrentWeapon()
			local wep = ply:GetActiveWeapon()
			wep:SetNWString("weapondamage", bignumwrite(data["dmg"]) or 0)
			wep:SetNWString("weaponpower", bignumwrite(data["power"]) or 0)
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
		if bignumzero(ply.Block64) then ply:StripWeapon("weapon_fists") ply.FistsCooldown = math.max(CurTime() + 1, ply.FistsCooldown) end
		if ply.accountdata then
			local resrc = {"gold", "timecubes", "weaponcubes"}
			for i = 1, #resrc do
				ply:SetNWString("account_" .. resrc[i], bignumwrite(ply.accountdata[resrc[i]]))
			end
			if ply:HasWeapon("tfa_cso_gungnir") then
				if ply.accountdata["gungnirtutorial"] == nil then
					ply.accountdata["gungnirtutorial"] = true
					Announce("The Gungnir's true form is a very powerful artefact.", Color(255,255,255), Color(0,0,93), 7, ply)
					Announce("It is capable of eradicating a massive horde of enemies with one blow.", Color(255,255,255), Color(0,0,93), 7, ply)
					Announce("But beware; damaging at least one enemy with the Gungnir sacrifices a Pulse.", Color(255,0,0), Color(0,0,93), 7, ply)
					Announce("Do not fear accidental death with this weapon...", Color(255,255,255), Color(0,0,93), 7, ply)
					Announce("...because it will safely deactivate if you are on your last Pulse.", Color(255,255,255), Color(0,0,93), 7, ply)
					Announce("Be careful, and use this godlike weapon wisely.", Color(255,255,255), Color(0,0,93), 7, ply)
				end
				ply:SetAmmo(5 * (ply.healthstate-1), "slam") --for the gungnir
			end
			if !ply:HasWeapon("gmod_tool") && ply:IsSuperAdmin() then
				ply:Give("gmod_tool")
			end
			if !ply:HasWeapon("weapon_fists") && ply.FistsCooldown < CurTime() && ply.healthstate > 2 && !ply.DisableMartial then
				ply:Give("weapon_fists")
			elseif ply.FistsCooldown < CurTime() && ply.healthstate > 2 && !ply.DisableMartial then
				local wep = ply:GetWeapon("weapon_fists")
				wep:SetNWString("weapondamage", bignumwrite(ply.FistDamage) or 0)
				wep:SetNWString("weaponpower", bignumwrite(ply.FistDamage) or 0)
				wep:SetNWInt("weaponlevel", ply.accountdata["fistslevel"][1] or 0)
				wep:SetNWInt("weaponrank", ply.accountdata["fistslevel"][2] or 0)
				wep:SetNWInt("weaponstar", ply.accountdata["fistslevel"][3] or 0)
				wep:SetNWInt("weapongrade", ply.accountdata["fistslevel"][4] or 0)
				wep:SetNWInt("weaponspecops", ply.accountdata["fistslevel"][5] or 0)
				wep:SetNWInt("weaponclass", ply.accountdata["fistslevel"][6] or 0)
				wep:SetNWInt("weaponstage", ply.accountdata["fistslevel"][7] or 0)
				wep:SetNWInt("weaponquality", ply.accountdata["fistslevel"][8] or 0)
				wep:SetNWInt("weaponechelon", ply.accountdata["fistslevel"][9] or 0)
				wep:SetNWInt("weapontier", ply.accountdata["fistslevel"][10] or 0)
			elseif ply:HasWeapon("weapon_fists") then
				ply:StripWeapon("weapon_fists")
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
			if ply:GetActiveWeapon():GetMaxClip1() >= 200 then ply:GetActiveWeapon():SetNWInt("actualammo", ply:GetActiveWeapon():Clip1()) end
		end
		ply:SetNWInt("healthstate", ply.healthstate)
		if ply.PrestigeDown != 0 then
			ply:GodEnable()
			ply.PrestigeDownGodmode = true
		elseif ply.PrestigeDownGodmode then
			ply.PrestigeDownGodmode = nil
			ply:GodDisable()
		end
		local walkspeed = 160 - (10 * (5-ply.healthstate))
		local runspeed = 320 - (20 * (5-ply.healthstate))
		if ply.stamina <= 0 then
			walkspeed = walkspeed / 1.5
			runspeed = walkspeed
			ApplyStatus(ply, "Exhaustion Fatigue", 1, math.huge, "none", "models/props_2fort/frog.mdl", true)
		else
			RemoveStatus(ply, "Exhaustion Fatigue")
		end
		if IsValid(ply:GetActiveWeapon()) && ply.healthstate > 2 then
			if ply:GetActiveWeapon():GetClass() == "weapon_fists" && !Hibernating() then
				walkspeed = walkspeed / 1.5
				runspeed = runspeed / 1.5
				ApplyStatus(ply, "Martial Stance", 1, math.huge, "none", "models/weapons/c_models/c_boxing_gloves/c_boxing_gloves.mdl", true)
				ply.dmgresist = ply.dmgresist + 1
			elseif GetStatusQuantity(ply, "Martial Stance") >= 1 then
				RemoveStatus(ply, "Martial Stance")
				if !Hibernating() then ply.FistsCooldown = CurTime() + 7 end
			end
		end
		if ply.FistsCooldown >= CurTime() && ply.healthstate > 2 then
			ApplyStatus(ply, "Martial Stance Cooldown", 1, math.huge, "none", "models/weapons/c_models/c_boxing_gloves/c_boxing_gloves_xmas.mdl", true)
		else
			RemoveStatus(ply, "Martial Stance Cooldown")
		end
		if Hibernating() then ply.FistsCooldown = 0 end
		if ply:IsSprinting() && !ply:IsProne() && ply:GetVelocity() != Vector(0,0,0) && ply:OnGround() then
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
			ApplyStatus(ply, "Double Speed", 1, math.huge, "none", "models/pickups/pickup_powerup_agility.mdl", true)
		else
			RemoveStatus(ply, "Double Speed")
		end
		if ply.healthstate > 2 && ply.healthstate <= 4 then
			ApplyStatus(ply, "Crippled", 5 - ply.healthstate, math.huge, "none", "models/Gibs/HGIBS_spine.mdl", true)
		else
			RemoveStatus(ply, "Crippled")
		end
		if ply.healthstate <= 2 then
			ApplyStatus(ply, "Incapacitated", 1, math.huge, "none", "models/Gibs/HGIBS_scapula.mdl", true)
		else
			RemoveStatus(ply, "Incapacitated")
		end
		if IsInvincible(ply) then
			ApplyStatus(ply, "Godmode", 1, math.huge, "none", "models/pickups/pickup_powerup_uber.mdl", true)
		else
			RemoveStatus(ply, "Godmode")
		end
		if Hibernating() && !ply.NoZoneBoost && ply:GetMoveType() != MOVETYPE_NOCLIP && ply.healthstate > 2 then
			walkspeed = 1000
			runspeed = 1500
			ApplyStatus(ply, "Zone Hibernation Speed Boost", 1, math.huge, "none", "models/pickups/pickup_powerup_agility.mdl", true)
		else
			RemoveStatus(ply, "Zone Hibernation Speed Boost")
		end
		if ply.IgnoreFallDamageOnce && !ply.IgnoreFallDamageAlways && !ply.Godmode then
			ApplyStatus(ply, "Next Fall Damage Negation", 1, math.huge, "none", "models/weapons/w_models/w_shovel.mdl", true)
		else
			RemoveStatus(ply, "Next Fall Damage Negation")
		end
		if (ply.IgnoreFallDamageAlways or Hibernating()) && !ply.Godmode then
			ApplyStatus(ply, "Fall Damage Negation", 1, math.huge, "none", "models/items/hevsuit.mdl", true)
		else
			RemoveStatus(ply, "Fall Damage Negation")
		end
		if ply:GetMoveType() == MOVETYPE_NOCLIP then
			ApplyStatus(ply, "Noclip", 1, math.huge, "none", "models/props_halloween/ghost_no_hat_red.mdl", true)
		else
			RemoveStatus(ply, "Noclip")
		end
		if ply.dmgresist then
			if ply.dmgresist > 1 then
				ApplyStatus(ply, "Damage Resistance", ply.dmgresist - 1 - GetStatusQuantity(ply, "Damage Resistance"), math.huge, "none", "models/pickups/pickup_powerup_resistance.mdl")
			else
				RemoveStatus(ply, "Damage Resistance")
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
			if bignumcompare(ply.Health64, bignumdiv(bignumcopy(ply.MaxHealth64), 10)) == 1 then
				timer.Simple(0.2, function() if IsValid(ply) then ply.AlreadyFallen = nil ply.InitFall = nil end end)
				ply:EmitSound("misc/halloween/spell_blast_jump.wav")
				ParticleEffectAttach( "spell_cast_wheel_blue", 1, ply, 2 )
				if !Hibernating() then bignumsub(ply.Health64, bignumdiv(bignumcopy(ply.MaxHealth64), 10)) end
				ply:SetVelocity(Vector(0,0,900 + (-ply:GetVelocity().z)))
			else
				ply:EmitSound("rf/player_fall.wav")
				ply.DontRegen = true
				if ply.healthstate <= 1 then
					ply.Health64 = {1, 0}
				else
					ply.Health64 = bignumcopy(ply.MaxHealth64)
				end
				ply.Shield64 = bignumcopy(ply.MaxShield64)
				ply.Block64 = bignumcopy(ply.MaxBlock64)
				ply.healthstate = math.max(1, ply.healthstate - 1)
				ply:CreateRagdoll()
				ply:SetNoDraw(true)
				ply.Godmode = true
				ply:Freeze(true)
				local reappeartime = 5
				--if ply:WaterLevel() < 2 then reappeartime = 1 end
				timer.Simple(reappeartime, function() if IsValid(ply) then
				ply.Godmode = false
				ply:SetNoDraw(false)
				ply:Freeze(false)
				ply:SetPos(ents.FindByClass("info_player*")[math.random(#ents.FindByClass("info_player_start"))]:GetPos() + Vector(0,0,1))
				ply.IgnoreFallDamageOnce = true
				timer.Simple(10, function() if IsValid(ply) then ply.IgnoreFallDamageOnce = nil end end)
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
		ply:SetNWString("powerlevel", bignumwrite(PowerMeasure(ply)))
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
			if thing.PropChecked && thing:WaterLevel() >= 1 && !thing.SubmergeBroken && !thing.IgnoreSoftRemove then
				thing:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
				BreakEntity(thing, true)
				timer.Simple(3, function() if IsValid(thing) then if thing:GetMaxHealth() > 1 then thing:Fire("break","") end end end)
				thing.SubmergeBroken = true
				thing.IgnoreSoftRemove = true
			end
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
				SlayEnemy(thing, 0, true)
			end
			for k, hurt in pairs(ents.FindInSphere(thing:GetPos(),3)) do
				if hurt:GetClass() == "trigger_hurt" then
					SlayEnemy(thing, 0, true)
				end
			end
		end
		thing:SetNWInt("npclives", (thing.ExtraLives or 0))
		--thing:SetNWInt("npcsuperlives", thing.NPCSuperlives)
		thing:SetNWInt("npcdeaths", (thing.DeadLives or 0))
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
		if IsInvincible(ply) then --pay no attention to players under the influence of godmode
			ply:SetNoTarget(true)
		else
			ply:SetNoTarget(false)
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
		ply:SetNWString("64bp", bignumwrite(ply.Block64))
		ply:SetNWString("64mbp", bignumwrite(ply.MaxBlock64))
		--ply:SetNWInt("prestige", ply.Prestige)
		ply:SetNWInt("prestige", ply.healthstate or 0)
		ply:SetNWInt("prestigedown", ply.PrestigeDown)
		--ply:SetNWInt("deadstige", ply.Deadstige)
		ply:SetNWInt("deadstige", 5 - (ply.healthstate or 0))
		ply:SetNWFloat("playerregentime", ply.RegenerationTime)
		if ply:IsFrozen() then
			ply:SetVelocity(ply:GetVelocity() / -1)
		end
		if bignumcompare(ply.Health64, ply.MaxHealth64) == 1 then
			ply.Health64 = bignumcopy(ply.MaxHealth64)
		end
		if bignumcompare(ply.Shield64, ply.MaxShield64) == 1 then
			ply.Shield64 = bignumcopy(ply.MaxShield64)
		end
		if bignumcompare(ply.Block64, ply.MaxBlock64) == 1 then
			ply.Block64 = bignumcopy(ply.MaxBlock64)
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
		if !ply.ChestKeys then ply.ChestKeys = 0 end
		if ply.RegenerationTime > 0 then
			if !HasStatus(ply,"Regen") then
				ApplyStatus(ply, "Regen", 1, math.huge, "none", "models/worms/healthcrate.mdl")
			end
		else
			if HasStatus(ply,"Regen") then
				RemoveStatus(ply, "Regen")
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
				ply.Block64 = {0, 0}
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