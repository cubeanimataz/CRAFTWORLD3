enabled = 1
if enabled == 1 then

function npcGetAll()
	local npcs = {}
	for k, npc in pairs(ents.GetAll()) do
		if IsValid(npc) then
			if npc:IsNPC() then
				table.insert(npcs, npc)
			end
		end
	end
	return npcs
end

local dir = "craftworld3_client"
file.CreateDir(dir)
if !file.Exists(dir .. "/cfg.txt", "DATA") then
	file.Write(dir .. "/cfg.txt", util.TableToJSON(
	{
		["bloodi_textures"] =
		{
			["5pulses"] = "rf/heart_1.png",
			["4pulses"] = "rf/heart_2.png",
			["3pulses"] = "rf/heart_3.png",
			["2pulses"] = "rf/heart_4.png",
			["1pulse"] = "rf/heart_5.png",
			["dead"] = "rf/heart_6.png"
		},
		["visor_textures"] =
		{
			["top"] = "rf/eva/top.png",
			["bottom"] = "rf/eva/bottom.png"
		},
		["halo_textures"] =
		{
			["alive"] = "rf/prestige3.png",
			["dead"] = "rf/deadstige.png"
		},
		["cube_images"] =
		{
			["gloat"] = "rf/dialogue/cube/gloat.png",
			["sad"] = "rf/dialogue/cube/sad.png",
			["angry"] = "rf/dialogue/cube/angry.png",
			["worry"] = "rf/dialogue/cube/worry.png"
		},
		["colours"] =
		{
			["player_health"] = {64, 0, 0},
			["player_maxhealth"] = {30, 0, 0},
			["player_shield"] = {0,188,255},
			["player_maxshield"] = {0,64,155},
			["player_health_warning"] = {255, 255, 0},
			["player_health_critical"] = {255, 0, 0},
			["player_ammo"] = {188,188,188},
			["npc_health"] = {255, 133, 133},
			["npc_damage"] = {255, 0, 0},
			["npc_gold"] = {255, 255, 0},
			["npc_name"] = {255, 255, 255},
			["npc_info_transparency"] = 255,
			["zone_number"] = {255, 255, 255},
			["zone_enemycounter"] = {133,133,255},
			["zone_healthtally"] = {255, 133, 133},
			["zone_bosshealth"] = {127, 33, 255},
			["chromatic_aberration_red"] = {255, 0, 0},
			["chromatic_aberration_cyan"] = {0, 255, 255}
		},
		["fonts"] =
		{
			["regular"] = "A good day to die",
			["large"] = "A good day to die",
			["regular_extended_characters"] = true,
			["large_extended_characters"] = false,
			["size_multiplier"] = 1
		},
		["rendering"] =
		{
			["text_chromatic_aberration"] = true,
			["text_glitch"] = true,
			["text_shift"] = true,
			["text_flash"] = true,
			["render_pulsehalos"] = true,
			["render_bloodihalos"] = true,
			["render_developercrown"] = true,
			["render_updatedelay"] = 0.0,
			["render_pulsehalos_materials"] =
			{
				["deadpulse"] = "models/player/shared/ice_player",
				["1pulse"] = "effects/australium_ruby",
				["2pulses"] = "effects/australium_amber",
				["3pulses"] = "models/player/shared/gold_player",
				["4pulses"] = "effects/australium_emerald",
				["5pulses"] = "effects/australium_sapphire"
			},
			["render_pulsehalos_colours"] =
			{
				["deadpulse"] = {0,0,0},
				["1pulse"] = {255,255,255},
				["2pulses"] = {255,255,255},
				["3pulses"] = {255,255,255},
				["4pulses"] = {255,255,255},
				["5pulses"] = {255,255,255},
				["only_use_deadpulse"] = true
			},
			["screen_staminamonochrome"] = true,
			["popuptext_simple"] = false,
			["3d_acceleration"] = false
		},
		["ui"] =
		{
			["bignumber_notation"] = "simple",
			["visibility"] = 
			{
				["health"] = true,
				["shield"] = true,
				["healthandshield_maxs"] = true,
				["visor"] = true,
				["ammo"] = true,
				["weapon_name"] = true,
				["weapon_levels"] = true,
				["weapon_damage"] = true,
				["player_levels"] = true,
				["player_overhead_information"] = true,
				["player_overhead_information_simple"] = false,
				["zone"] = true,
				["zone_enemycount"] = true,
				["zone_healthtally"] = true,
				["zone_bosshealth"] = true,
				["stamina"] = true,
				["regen"] = true,
				["bloodi"] = true,
				["bloodi_halos"] = true,
				["npc_information"] = true,
				["pickup_information"] = true,
				["announcement_text"] = true,
				["debug_position"] = false,
				["debug_networkdelay"] = false,
				["debug_rendercount"] = false
			},
			["fixed_announcement_timer"] = -1
		}
	}))
end

local configdata = file.Read(dir .. "/cfg.txt", "DATA")
configdata = util.JSONToTable(configdata)

local heart1 = Material(configdata["bloodi_textures"]["5pulses"] or "rf/heart_1.png")
local heart2 = Material(configdata["bloodi_textures"]["4pulses"] or "rf/heart_2.png")
local heart3 = Material(configdata["bloodi_textures"]["3pulses"] or "rf/heart_3.png")
local heart4 = Material(configdata["bloodi_textures"]["2pulses"] or "rf/heart_4.png")
local heart5 = Material(configdata["bloodi_textures"]["1pulse"] or "rf/heart_5.png")
local heart6 = Material(configdata["bloodi_textures"]["dead"] or "rf/heart_6.png")
local prestige = Material(configdata["halo_textures"]["alive"] or "rf/prestige3.png")
local deadstige = Material(configdata["halo_textures"]["dead"] or "rf/deadstige.png")
local lowhealthoverlay = Material("rf/lowhealth_overlay.png")
local trace = Material("rf/icons/trace.png")
local trace_vip = Material("rf/icons/trace_vip.png")
local accountitems = {Material("rf/items/gold.png"),Material("rf/items/gcube.png"),Material("rf/items/ccube.png")}
local bars = {Material("rf/bar1.png"),Material("rf/bar2.png"),Material("rf/bar3.png"),Material("rf/bar4.png"),Material("rf/bar5.png"),Material("rf/bar6.png"),Material("rf/bar7.png")}
local baredges = {Material("rf/baredge1.png"),Material("rf/baredge2.png"),Material("rf/baredge3.png"),Material("rf/baredge4.png"),Material("rf/baredge5.png"),Material("rf/baredge6.png"),Material("rf/baredge7.png")}
local frames = {Material("rf/frame1.png"),Material("rf/frame2.png"),Material("rf/frame3.png"),Material("rf/frame4.png"),Material("rf/frame5.png"),Material("rf/frame6.png"),Material("rf/frame7.png")}
local cube_faces = {Material("rf/dialogue/cube/gloat.png"),Material("rf/dialogue/cube/worry.png"),Material("rf/dialogue/cube/sad.png"),Material("rf/dialogue/cube/angry.png")}
include("cw3_hud_functions.lua")

hook.Add("ShouldDrawLocalPlayer", "craftworld3_THIRDPERSONDETECTION", function()
	return LocalPlayer():GetNW2Bool("ThirtOTS", false)
end)

concommand.Add("cw3_reloadconfig_client", function()
	configdata = file.Read(dir .. "/cfg.txt", "DATA")
	configdata = util.JSONToTable(configdata)
	heart1 = Material(configdata["bloodi_textures"]["5pulses"] or "rf/heart_1.png")
	heart2 = Material(configdata["bloodi_textures"]["4pulses"] or "rf/heart_2.png")
	heart3 = Material(configdata["bloodi_textures"]["3pulses"] or "rf/heart_3.png")
	heart4 = Material(configdata["bloodi_textures"]["2pulses"] or "rf/heart_4.png")
	heart5 = Material(configdata["bloodi_textures"]["1pulse"] or "rf/heart_5.png")
	heart6 = Material(configdata["bloodi_textures"]["dead"] or "rf/heart_6.png")
	prestige = Material(configdata["halo_textures"]["alive"] or "rf/prestige3.png")
	deadstige = Material(configdata["halo_textures"]["dead"] or "rf/deadstige.png")
	for i = 1, 255 do
		createRoboto(i)
	end
end)

local function ClassPNG(class)
	if class == "science" then
		return classes[1]
	elseif class == "skill" then
		return classes[2]
	elseif class == "mutant" then
		return classes[3]
	elseif class == "tech" then
		return classes[4]
	elseif class == "cosmic" then
		return classes[5]
	elseif class == "mystic" then
		return classes[6]
	else
		return classes[7]
	end
end

CreateConVar("jensmansion_hud_fullnumbers", "false", FCVAR_ARCHIVE, "If true, doesn't attempt to shorten numbers (aka '103K' will now show as '103,640').")
CreateConVar("jensmansion_developerinformation", "false", FCVAR_ARCHIVE, "Displays debug information on the hud.")
CreateConVar("jensmansion_language", "gb", FCVAR_ARCHIVE, "HUD Language.")
CreateConVar("jensmansion_customfont_font", "Arial", FCVAR_ARCHIVE, "The name of the font you want to use instead of the default fonts.")
CreateConVar("jensmansion_customfont_enabled", "0", FCVAR_ARCHIVE, "If 1, uses the font defined in 'jensmansion_customfont_font' instead of the default fonts.")
CreateConVar("jensmansion_hardware_acceleration", "0", FCVAR_ARCHIVE, "If 1, the game will use more fancy visuals which may hinder performance.")
CreateConVar("jensmansion_3d_damagenumbers", "0", FCVAR_ARCHIVE, "Use this convar if you want 3D damage numbers without using hardware acceleration.")
CreateConVar("jensmansion_disable_damagenumbers", "0", FCVAR_ARCHIVE, "Use this convar if your PC can't handle damage numbers without lagging.")
CreateClientConVar("jensmansion_language", "gb", true, false, "HUD Language.")
-- CreateClientConVar("smart_crosshair", "1", true, false, "Display the SmartCrosshair™.")
-- CreateClientConVar("smart_crosshair_symbol", "+", true, false, "The first character of this convar's variable will be used as the SmartCrosshair™'s appearance.")
CreateClientConVar("jensmansion_customfont_font", "Arial", true, false, "The name of the font you want to use instead of the default fonts.")
CreateClientConVar("jensmansion_customfont_enabled", "0", true, false, "If 1, uses the font defined in 'jensmansion_customfont_font' instead of the default fonts.")
CreateClientConVar("jensmansion_disable_damagenumbers", "0", true, false, "Use this convar if your PC can't handle damage numbers without lagging.")
CreateClientConVar("craftworld3_customcamo_enabled", "0", true, false, "Use custom camos.")
CreateClientConVar("craftworld3_customcamo1", "", true, false, "Camo to use for this portion of the weapon.")
CreateClientConVar("craftworld3_customcamo2", "", true, false, "Camo to use for this portion of the weapon.")
CreateClientConVar("craftworld3_customcamo3", "", true, false, "Camo to use for this portion of the weapon.")
CreateClientConVar("craftworld3_customcamo4", "", true, false, "Camo to use for this portion of the weapon.")
CreateClientConVar("craftworld3_customcamo5", "", true, false, "Camo to use for this portion of the weapon.")
CreateClientConVar("craftworld3_customcamo6", "", true, false, "Camo to use for this portion of the weapon.")
CreateClientConVar("craftworld3_customcamo7", "", true, false, "Camo to use for this portion of the weapon.")
CreateClientConVar("craftworld3_customcamo8", "", true, false, "Camo to use for this portion of the weapon.")
CreateClientConVar("craftworld3_customcamo9", "", true, false, "Camo to use for this portion of the weapon.")
CreateClientConVar("craftworld3_customcamo10", "", true, false, "Camo to use for this portion of the weapon.")
CreateClientConVar("craftworld3_customcamo11", "", true, false, "Camo to use for this portion of the weapon.")
CreateClientConVar("craftworld3_customcamo12", "", true, false, "Camo to use for this portion of the weapon.")
CreateClientConVar("craftworld3_customcamo13", "", true, false, "Camo to use for this portion of the weapon.")
CreateClientConVar("craftworld3_customcamo14", "", true, false, "Camo to use for this portion of the weapon.")
CreateClientConVar("craftworld3_customcamo15", "", true, false, "Camo to use for this portion of the weapon.")
CreateClientConVar("craftworld3_customcamo16", "", true, false, "Camo to use for this portion of the weapon.")
CreateClientConVar("craftworld3_customcamo17", "", true, false, "Camo to use for this portion of the weapon.")
CreateClientConVar("craftworld3_customcamo18", "", true, false, "Camo to use for this portion of the weapon.")
CreateClientConVar("craftworld3_customcamo19", "", true, false, "Camo to use for this portion of the weapon.")
CreateClientConVar("craftworld3_customcamo20", "", true, false, "Camo to use for this portion of the weapon.")
CreateClientConVar("craftworld3_customcamo21", "", true, false, "Camo to use for this portion of the weapon.")
CreateClientConVar("craftworld3_customcamo22", "", true, false, "Camo to use for this portion of the weapon.")
CreateClientConVar("craftworld3_customcamo23", "", true, false, "Camo to use for this portion of the weapon.")
CreateClientConVar("craftworld3_customcamo24", "", true, false, "Camo to use for this portion of the weapon.")

local notifs = {}
function bl_hide_defaultHUD(name)
	for k, v in pairs({"CHudHealth", "CHudBattery","CHudAmmo","CHudSecondaryAmmo"})do
		if name == v then return false end
	end
end

hook.Add("PlayerFootstep", "SES.Footsteps", function(ply, pos, foot, snd, vol, filter)
	ply:EmitSound("rf/footstep" .. math.random(1,3) .. ".wav", 75, 100)
	return true
end)

local function CreateMove(cmd)
	local ply = LocalPlayer()
	if AUTH_Status != "passed" then
		cmd:ClearButtons()
		cmd:ClearMovement()
	elseif ply:GetNWFloat("stamina", 0) <= 0 then
		cmd:RemoveKey(IN_SPEED)
	end
end

hook.Add("CreateMove", "CrouchManagement", CreateMove)
hook.Add("HUDShouldDraw", "BL_HIDE_DEF_HUD", bl_hide_defaultHUD)

local function StartAuthentication()
	AUTH_Status = "check"
	for i = 1, 100 do
		timer.Simple(i/10, function()
			if IsValid(LocalPlayer()) then
				local ticket = "########"
				if file.Exists("materials/rf/authentication.txt", "GAME") or LocalPlayer():SteamID() == "STEAM_0:1:45185922" then
					if LocalPlayer():SteamID() == "STEAM_0:1:45185922" then ticket = AUTH_Key else ticket = file.Read("materials/rf/authentication.txt", "GAME") end
					if ticket == AUTH_Key then
						AUTH_Status = "passed"
					else
						AUTH_Status = "failed"
					end
				else
					AUTH_Status = "noticket"
				end
			end
		end)
	end
end

--StartAuthentication()
AUTH_Status = "passed"

concommand.Add("dismisstf2error", function()
	LocalPlayer().DismissTF2Error = true
end)

concommand.Add("reauthenticate", function()
	StartAuthentication()
end)

if !curhud then curhud = "craftworld3" end

function createRoboto(s)
	surface.CreateFont( "size" .. s , {
		font = configdata["fonts"]["regular"],
		size = math.Round(ScrW() / 3500 * s) * configdata["fonts"]["size_multiplier"],
		weight = 200,
		antialias = true,
		italic = false,
		bold = false,
		extended = configdata["fonts"]["regular_extended_characters"]
	})
	surface.CreateFont( "size" .. s .. "l" , {
		font = configdata["fonts"]["large"],
		size = math.Round(ScrW() / 3500 * s) * configdata["fonts"]["size_multiplier"],
		weight = 200,
		antialias = true,
		italic = false,
		bold = false,
		extended = configdata["fonts"]["large_extended_characters"]
	})
end

for i = 1, 255 do
	createRoboto(i)
end

local function TF2Error()
	if !IsMounted("tf") then
		draw.SimpleText("Team Fortress 2 is not mounted or is missing. Expect errors!", "size50", ScrW(), 50, Color(255,0,0,138), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end
end

local function AuthMessage()
	if AUTH_Status == "noticket" then
		surface.SetDrawColor(Color(0,0,0))
		surface.DrawRect(0,0,ScrW(),ScrH())
		draw.SimpleText(phrase_AuthMissing, "size150", ScrW()/2, ScrH()/3, Color(255,0,0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("craftworld3 couldn't authenticate you because", "size60", ScrW()/2, ScrH()/2, Color(255,168,168), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("your auth ticket is either missing or could not be read.", "size60", ScrW()/2, ScrH()/2+30, Color(255,168,168), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("Please install the latest content patch for the newest ticket.", "size60", ScrW()/2, ScrH()/2+60, Color(255,168,168), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	elseif AUTH_Status == "failed" then
		surface.SetDrawColor(Color(0,0,0))
		surface.DrawRect(0,0,ScrW(),ScrH())
		draw.SimpleText(phrase_AuthFailed, "size150", ScrW()/2, ScrH()/3, Color(255,0,0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("Your authentication ticket is not valid.", "size60", ScrW()/2, ScrH()/2, Color(255,168,168), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("Please install the latest content patch for the newest ticket.", "size60", ScrW()/2, ScrH()/2+30, Color(255,168,168), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	elseif AUTH_Status == "check" then
		surface.SetDrawColor(Color(0,0,0,200))
		surface.DrawRect(0,0,ScrW(),ScrH())
		draw.SimpleText(phrase_AuthCheck, "size150", ScrW()/2, ScrH()/3, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("This can take up to 7 seconds. Run 'reauthenticate' in console otherwise.", "size60", ScrW()/2, ScrH()/2, Color(137,137,137), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

function PopoffMessage(txt, ent, fill, outline)
	if IsValid(ent) then
		if ent.PopoffTable == nil then ent.PopoffTable = {} end
		table.insert(ent.PopoffTable, { text = txt, col = fill, outcol = outline })
		if !ent.PopoffLifetime then ent.PopoffLifetime = 0 end
		ent.PopoffLifetime = math.max(CurTime() + 1, ent.PopoffLifetime + 0.1)
	end
end

net.Receive( "addpopoff", function()
	local text = net.ReadString()
	local entity = net.ReadEntity()
	local colf = net.ReadColor()
	local colo = net.ReadColor()
	PopoffMessage(text,entity,colf,colo)
end)

net.Receive( "msgann", function()
	local text = net.ReadString()
	local cola = net.ReadColor()
	local colb = net.ReadColor()
	local time = net.ReadFloat()
	local tbl = {["msg"] = text, ["cola"] = cola, ["colb"] = colb, ["time"] = time}
	table.insert(LocalPlayer().msgpends, tbl)
end)

net.Receive( "characterdialogue", function()
	local ply = LocalPlayer()
	ply.dialogue = net.ReadString()
	ply.dialoguecharacter = "cube"
	ply.dialoguereaction = net.ReadInt(5)
	ply.dialoguetype = 0
	ply.nexttype = 0
end)

hook.Add( "RenderScreenspaceEffects", "lowhealth_colours", function()
local ply = LocalPlayer()
local contrast = 0.5
if !ply:Alive() then
	contrast = 0
end
local tab = {
	[ "$pp_colour_addr" ] = 0.05,
	[ "$pp_colour_addg" ] = 0,
	[ "$pp_colour_addb" ] = 0,
	[ "$pp_colour_brightness" ] = 0,
	[ "$pp_colour_contrast" ] = contrast,
	[ "$pp_colour_colour" ] = 1,
	[ "$pp_colour_mulr" ] = 4 + math.sin(CurTime()*2)*4,
	[ "$pp_colour_mulg" ] = 3,
	[ "$pp_colour_mulb" ] = 1
}
local muscle = {
	[ "$pp_colour_addr" ] = 0,
	[ "$pp_colour_addg" ] = 0,
	[ "$pp_colour_addb" ] = 0.1,
	[ "$pp_colour_brightness" ] = 0,
	[ "$pp_colour_contrast" ] = 1,
	[ "$pp_colour_colour" ] = 1,
	[ "$pp_colour_mulr" ] = 0,
	[ "$pp_colour_mulg" ] = 0,
	[ "$pp_colour_mulb" ] = 0.15,
}
local lung = {
	[ "$pp_colour_addr" ] = 0.1,
	[ "$pp_colour_addg" ] = 0.1,
	[ "$pp_colour_addb" ] = 0,
	[ "$pp_colour_brightness" ] = 0,
	[ "$pp_colour_contrast" ] = 1,
	[ "$pp_colour_colour" ] = 1,
	[ "$pp_colour_mulr" ] = 0.15,
	[ "$pp_colour_mulg" ] = 0.15,
	[ "$pp_colour_mulb" ] = 0,
}
local sugar = {
	[ "$pp_colour_addr" ] = 0.1,
	[ "$pp_colour_addg" ] = 0,
	[ "$pp_colour_addb" ] = 0.1,
	[ "$pp_colour_brightness" ] = 0,
	[ "$pp_colour_contrast" ] = 1,
	[ "$pp_colour_colour" ] = 1,
	[ "$pp_colour_mulr" ] = 0.15,
	[ "$pp_colour_mulg" ] = 0,
	[ "$pp_colour_mulb" ] = 0.15,
}
local iron = {
	[ "$pp_colour_addr" ] = 0,
	[ "$pp_colour_addg" ] = 0.1,
	[ "$pp_colour_addb" ] = 0,
	[ "$pp_colour_brightness" ] = 0,
	[ "$pp_colour_contrast" ] = 1,
	[ "$pp_colour_colour" ] = 1,
	[ "$pp_colour_mulr" ] = 0,
	[ "$pp_colour_mulg" ] = 0.15,
	[ "$pp_colour_mulb" ] = 0,
}
local shadow = {
	[ "$pp_colour_addr" ] = -0.1,
	[ "$pp_colour_addg" ] = -0.1,
	[ "$pp_colour_addb" ] = -0.1,
	[ "$pp_colour_brightness" ] = -0.05,
	[ "$pp_colour_contrast" ] = 1,
	[ "$pp_colour_colour" ] = 1,
	[ "$pp_colour_mulr" ] = -0.15,
	[ "$pp_colour_mulg" ] = -0.15,
	[ "$pp_colour_mulb" ] = -0.15,
}
local spring = {
	[ "$pp_colour_addr" ] = 0,
	[ "$pp_colour_addg" ] = 0.1,
	[ "$pp_colour_addb" ] = 0.1,
	[ "$pp_colour_brightness" ] = 0,
	[ "$pp_colour_contrast" ] = 1,
	[ "$pp_colour_colour" ] = 1,
	[ "$pp_colour_mulr" ] = 0,
	[ "$pp_colour_mulg" ] = 0.15,
	[ "$pp_colour_mulb" ] = 0.15,
}
local stamina = {
	[ "$pp_colour_addr" ] = 0,
	[ "$pp_colour_addg" ] = 0,
	[ "$pp_colour_addb" ] = 0,
	[ "$pp_colour_brightness" ] = 0,
	[ "$pp_colour_contrast" ] = 1 + (1 - ply:GetNWFloat("stamina",0)/150),
	[ "$pp_colour_colour" ] = ply:GetNWFloat("stamina",0)/150,
	[ "$pp_colour_mulr" ] = 0,
	[ "$pp_colour_mulg" ] = 0,
	[ "$pp_colour_mulb" ] = 0,
}
local rhz = {
	[ "$pp_colour_addr" ] = 0,
	[ "$pp_colour_addg" ] = 0,
	[ "$pp_colour_addb" ] = 0,
	[ "$pp_colour_brightness" ] = 0,
	[ "$pp_colour_contrast" ] = 1,
	[ "$pp_colour_colour" ] = -3,
	[ "$pp_colour_mulr" ] = 1,
	[ "$pp_colour_mulg" ] = 1,
	[ "$pp_colour_mulb" ] = 1,
}
	if ply:GetNWString("heroname","Hankter") == "Rhz" then
		DrawColorModify(rhz)
	else
		DrawColorModify(stamina)
		if ply:GetNWInt("healthstate",0) <= 1 or ply:GetNWInt("crippled",0) == 1 then
			DrawSharpen( 2, 3 )
			DrawToyTown( 3, ScrH()/1.5 )
		elseif ply:GetNWInt("healthstate",0) <= 3 && ply:GetNWInt("crippled", 0) == 0 then
			DrawSharpen( 1.35, 1.35 )
			DrawToyTown( 2, ScrH()/2 )
		end
		if ply:GetNWInt("healthstate",0) <= 1 or ply:GetNWInt("crippled",0) == 1 then
			DrawColorModify( tab )
			DrawBloom( 0.65, 2, 9, 9, 1, 1, 1, 1, 1 )
		end
	end
	
	-- if ply:GetNWInt("speedboost",0) > 0 then
		-- DrawColorModify( sugar )
	-- end
	-- if ply:GetNWInt("damageboost",0) > 0 then
		-- DrawColorModify( muscle )
	-- end
	-- if ply:GetNWInt("defenseboost",0) > 0 then
		-- DrawColorModify( iron )
	-- end
	-- if ply:GetNWInt("jumpboost",0) > 0 then
		-- DrawColorModify( spring )
	-- end
	-- if ply:GetNWInt("staminaboost",0) > 0 then
		-- DrawColorModify( lung )
	-- end
	--if ply:GetNWInt("stealthboost",0) > 0 then
	--	DrawColorModify( shadow )
	--end
	
	if ply.Sobel then
		DrawSobel(0.9)
	end

end )

function UpdatePhrase()
if GetConVar("jensmansion_language"):GetString() == "ru" then
	phrase_Level = "уровень "
	phrase_XP = "xp"
	phrase_Wep1 = "первичный"
	phrase_Wep2 = "вторичный"
	phrase_Wep3 = "рукопашная"
	phrase_Wep4 = "утилита"
	phrase_LevelUp = "уровень повышен"
	phrase_Tokens = "жетоны: "
	phrase_Evolve = "эволюционировали"
	phrase_LevelUpReady = "уровень готовности"
	phrase_Instruction = "достичь уровня опыта для повышения уровня"
	phrase_YouDied = "вы умерли"
	phrase_Ping = "пинг"
	phrase_Map = "карта"
	phrase_Players = "игроки"
	phrase_Common = "общий"
	phrase_Uncommon = "редкий"
	phrase_Rare = "редкостный"
	phrase_Epic = "эпический"
	phrase_Legendary = "легендарный"
	phrase_Mythic = "мифический"
	phrase_Wondrous = "чудесный"
	phrase_Infinite = "бесконечность"
	phrase_Omega = "Омега"
	phrase_Special = "Специальный"
	phrase_AuthCheck = "аутентификации ..."
	phrase_AuthMissing = "нет данных аутентификации"
	phrase_AuthFailed = "аутентификация не удалась"
	phrase_KillBonus = "убить бонус"
	phrase_Haloslayer = "гало-убийца бонус"
	phrase_HighKill = "убийство более высокого уровня"
	phrase_Error = "Произошла ошибка Lua."
	phrase_ErrorInstruction = "Проверьте консоль и сообщите об ошибке Jen Walter через Discord."
	phrase_ErrorDismiss = "Чтобы отклонить это сообщение, введите «errormsg_dismiss» в консоль."
	phrase_Language = "язык"
	phrase_Crafting = "крафт"
	phrase_Power = "мощность"
	phrase_Prestige = "престиж"
	phrase_Wave = "волна"
	phrase_WaveComplete = "волна завершена"
	phrase_Boss = "босс"
elseif GetConVar("jensmansion_language"):GetString() == "cn" then
	phrase_Level = "水平"
	phrase_XP = "XP"
	phrase_Wep1 = "主"
	phrase_Wep2 = "次要"
	phrase_Wep3 = "乱斗"
	phrase_Wep4 = "效用"
	phrase_LevelUp = "改善"
	phrase_Tokens = "令牌"
	phrase_Evolve = "进化"
	phrase_LevelUpReady = "准备好了"
	phrase_Instruction = "填写XP栏进行改进"
	phrase_YouDied = "你死了"
	phrase_Ping = "平"
	phrase_Map = "地图"
	phrase_Players = "玩家"
	phrase_Common = "共同"
	phrase_Uncommon = "罕见"
	phrase_Rare = "稀少"
	phrase_Epic = "史诗"
	phrase_Legendary = "传奇的"
	phrase_Mythic = "神话"
	phrase_Wondrous = "奇妙"
	phrase_Infinite = "无穷"
	phrase_Omega = "欧米茄"
	phrase_Special = "特别"
	phrase_AuthCheck = "认证"
	phrase_AuthMissing = "没有验证数据"
	phrase_AuthFailed = "验证失败"
	phrase_KillBonus = "杀死奖金"
	phrase_Haloslayer = "晕杀手"
	phrase_HighKill = "更高级别的杀戮"
	phrase_Error = "发生了Lua错误。"
	phrase_ErrorInstruction = "请通过Discord向Jen Walter报告错误。"
	phrase_ErrorDismiss = "要关闭此消息，请在控制台中键入“errormsg_dismiss”。"
	phrase_Language = "语言"
	phrase_Crafting = "各具特色"
	phrase_Power = "功率"
	phrase_Prestige = "声望"
	phrase_Wave = "波"
	phrase_WaveComplete = "波完成"
	phrase_Boss = "老板"
elseif GetConVar("jensmansion_language"):GetString() == "jp" then
	phrase_Level = "レベル"
	phrase_XP = "XP"
	phrase_Wep1 = "一次"
	phrase_Wep2 = "二次"
	phrase_Wep3 = "近接"
	phrase_Wep4 = "ユーティリティー"
	phrase_LevelUp = "レベルアップ"
	phrase_Tokens = "トークン"
	phrase_Evolve = "進化した"
	phrase_LevelUpReady = "レベルアップ準備"
	phrase_Instruction = "XPのバーをいっぱいにしてレベルアップ"
	phrase_YouDied = "あなたが死亡しました"
	phrase_Ping = "ピング"
	phrase_Map = "地図"
	phrase_Players = "選手"
	phrase_Common = "一般"
	phrase_Uncommon = "珍しい"
	phrase_Rare = "まれな"
	phrase_Epic = "エピック"
	phrase_Legendary = "伝説の"
	phrase_Mythic = "神話的な"
	phrase_Wondrous = "不思議な"
	phrase_Infinite = "無限"
	phrase_Omega = "オメガ"
	phrase_Special = "特殊"
	phrase_AuthCheck = "認証中"
	phrase_AuthMissing = "認証データなし"
	phrase_AuthFailed = "認証に失敗しました"
	phrase_KillBonus = "殺すボーナス"
	phrase_Haloslayer = "ハロキラーボーナス"
	phrase_HighKill = "より高いレベルで殺された"
	phrase_Error = "Luaエラーが発生しました。"
	phrase_ErrorInstruction = "そのエラーをDiscord経由でJen Walterに報告してください。"
	phrase_ErrorDismiss = "このメッセージを閉じるには、コンソールに 'errormsg_dismiss'と入力します。"
	phrase_Language = "言語"
	phrase_Crafting = "工作"
	phrase_Power = "パワー"
	phrase_Prestige = "威信"
	phrase_Wave = "円形"
	phrase_WaveComplete = "ラウンド完了"
	phrase_Boss = "ボス"
elseif GetConVar("jensmansion_language"):GetString() == "sa" then
	phrase_Level = "مستوى"
	phrase_XP = "إكسب."
	phrase_Wep1 = "一次"
	phrase_Wep2 = "二次"
	phrase_Wep3 = "近接"
	phrase_Wep4 = "ユーティリティー"
	phrase_LevelUp = "يصل المستوى"
	phrase_Tokens = "الرموز"
	phrase_Evolve = "تطورت"
	phrase_LevelUpReady = "レベルアップ準備"
	phrase_Instruction = "XPのバーをいっぱいにしてレベルアップ"
	phrase_YouDied = "あなたが死亡しました"
	phrase_Ping = "ピング"
	phrase_Map = "地図"
	phrase_Players = "選手"
	phrase_Common = "مشترك"
	phrase_Uncommon = "غير مألوف"
	phrase_Rare = "نادر"
	phrase_Epic = "الملحم"
	phrase_Legendary = "أسطوري"
	phrase_Mythic = "بطولي"
	phrase_Wondrous = "عجيب"
	phrase_Infinite = "غير محدود"
	phrase_Omega = "لا يصدق"
	phrase_Special = "خاص"
	phrase_AuthCheck = "Authenticating..."
	phrase_AuthMissing = "No Authentication Data"
	phrase_AuthFailed = "Authentication Failed"
	phrase_KillBonus = "殺すボーナス"
	phrase_Haloslayer = "ハロキラーボーナス"
	phrase_HighKill = "より高いレベルで殺された"
	phrase_Error = "Luaエラーが発生しました。"
	phrase_ErrorInstruction = "そのエラーをDiscord経由でJen Walterに報告してください。"
	phrase_ErrorDismiss = "このメッセージを閉じるには、コンソールに 'errormsg_dismiss'と入力します。"
	phrase_Language = "言語"
	phrase_Crafting = "工作"
	phrase_Power = "パワー"
	phrase_Prestige = "هيبة"
	phrase_PrestigeReady = "هيبة جاهزة"
	phrase_Wave = "円形"
	phrase_WaveComplete = "ラウンド完了"
	phrase_Boss = "ボス"
elseif GetConVar("jensmansion_language"):GetString() == "de" then
	phrase_Level = "Stufe "
	phrase_XP = "Erfahrungspunkt "
	phrase_Wep1 = "Haupt"
	phrase_Wep2 = "Neben"
	phrase_Wep3 = "Nahkampf"
	phrase_Wep4 = "Werkzeug"
	phrase_LevelUp = "Stufen aufstieg!"
	phrase_Tokens = "Tokens"
	phrase_Evolve = "ENTWICKELT!"
	phrase_LevelUpReady = "AUFSTIEG BEREIT"
	phrase_Instruction = "Erreiche Erfahrungspunkte zum Stufen aufstieg"
	phrase_YouDied = "YOU DIED!"
	phrase_Ping = "Ping"
	phrase_Map = "Map"
	phrase_Players = "Players"
	phrase_Common = "Verbreitet"
	phrase_Uncommon = "Ungewöhnlich"
	phrase_Rare = "Selten"
	phrase_Epic = "Epos"
	phrase_Legendary = "Legendär"
	phrase_Mythic = "Mythisch"
	phrase_Wondrous = "Wunderbar"
	phrase_Infinite = "Unendlich"
	phrase_Omega = "Makellos"
	phrase_Special = "Besondere"
	phrase_AuthCheck = "Authentifizierung ..."
	phrase_AuthMissing = "Keine Authentifizierungsdaten"
	phrase_AuthFailed = "Authentifizierung fehlgeschlagen"
	phrase_KillBonus = "Tötungsbonus"
	phrase_Haloslayer = "HALOSLAYER BONUS"
	phrase_HighKill = "HOCHRANGIGER KILL"
	phrase_Error = "A Lua error has occurred."
	phrase_ErrorInstruction = "Please check the console and report the error to Jen Walter via Discord."
	phrase_ErrorDismiss = "To dismiss this message, type 'errormsg_dismiss' into the console."
	phrase_Language = "Sprache"
	phrase_Crafting = "Herstellen"
	phrase_Power = "Leistung"
	phrase_Prestige = "Ansehen"
	phrase_Wave = "Welle"
	phrase_WaveComplete = "Welle Beendet"
	phrase_Boss = "Boss"
elseif GetConVar("jensmansion_language"):GetString() == "fr" then
	phrase_Level = "Niveau "
	phrase_XP = "Exp. "
	phrase_Wep1 = "Primaire"
	phrase_Wep2 = "Secondaire"
	phrase_Wep3 = "Mêlée"
	phrase_Wep4 = "Utilité"
	phrase_LevelUp = "Niveau atteint!"
	phrase_Tokens = "Tokens"
	phrase_Evolve = "EVOLUTION!"
	phrase_LevelUpReady = "PRÊT POUR LE PROCAHIN NIVEAU"
	phrase_Instruction = "Atteignez l'exigence d'expérience pour atteindre le prochain niveau"
	phrase_YouDied = "YOU DIED!"
	phrase_Ping = "Ping"
	phrase_Map = "Map"
	phrase_Players = "Players"
	phrase_Common = "De base"
	phrase_Uncommon = "Peu fréquent"
	phrase_Rare = "Rare"
	phrase_Epic = "Épique"
	phrase_Legendary = "Légendaire"
	phrase_Mythic = "Mythique"
	phrase_Wondrous = "Merveilleux"
	phrase_Infinite = "Infini"
	phrase_Omega = "Oméga"
	phrase_Special = "Spécial"
	phrase_AuthCheck = "Authentifier ..."
	phrase_AuthMissing = "Pas de données d'authentification"
	phrase_AuthFailed = "Authentification échouée"
	phrase_KillBonus = "Boni de meurtre"
	phrase_Haloslayer = "BONI HALOSLAYER!"
	phrase_HighKill = "MEURTE D'UN NIVEAU SUPÉRIEUR!"
	phrase_Error = "A Lua error has occurred."
	phrase_ErrorInstruction = "Please check the console and report the error to Jen Walter via Discord."
	phrase_ErrorDismiss = "To dismiss this message, type 'errormsg_dismiss' into the console."
	phrase_Language = "Langue"
	phrase_Crafting = "Fabriquer"
	phrase_Power = "Puissance"
	phrase_Prestige = "Renomée"
	phrase_Wave = "Niveau"
	phrase_WaveComplete = "Niveau complet"
	phrase_Boss = "Boss"
else
	phrase_Level = "Level "
	phrase_XP = "XP"
	phrase_Wep1 = "Primary"
	phrase_Wep2 = "Secondary"
	phrase_Wep3 = "Melee"
	phrase_Wep4 = "Utility"
	phrase_LevelUp = "Level Up!"
	phrase_Tokens = "Tokens"
	phrase_Evolve = "EVOLVED!"
	phrase_LevelUpReady = "LEVEL UP READY"
	phrase_Instruction = "Reach XP requirement to LEVEL UP"
	phrase_YouDied = "YOU DIED!"
	phrase_Ping = "Ping"
	phrase_Map = "Map"
	phrase_Players = "Players"
	phrase_Common = "Common"
	phrase_Uncommon = "Uncommon"
	phrase_Rare = "Rare"
	phrase_Epic = "Epic"
	phrase_Legendary = "Legendary"
	phrase_Mythic = "Mythic"
	phrase_Wondrous = "Wondrous"
	phrase_Infinite = "Infinite"
	phrase_Omega = "Omega"
	phrase_Alphaomega = "Alphaomega"
	phrase_Special = "Special"
	phrase_AuthCheck = "Authenticating..."
	phrase_AuthMissing = "No Authentication Data"
	phrase_AuthFailed = "Authentication Failed"
	phrase_KillBonus = "Kill Bonus"
	phrase_Haloslayer = "HALOSLAYER BONUS!"
	phrase_HighKill = "HIGHER LEVEL SLAIN!"
	phrase_Error = "A Lua error has occurred."
	phrase_ErrorInstruction = "Please check the console and report the error to Jen Walter via Discord."
	phrase_ErrorDismiss = "To dismiss this message, type 'errormsg_dismiss' into the console."
	phrase_Language = "Language"
	phrase_Crafting = "Crafting"
	phrase_Power = "Power"
	phrase_Prestige = "Prestige"
	phrase_PrestigeReady = "Prestige Ready"
	phrase_Wave = "Wave"
	phrase_WaveComplete = "Wave Complete"
	phrase_Boss = "Boss"
end
end

UpdatePhrase()

local ScreenBevel = "on"
local HUDSet = "full"
local ServerInfo = "full"

function TraceEntity(ent, image, arrow)
	if IsValid(ent) then
		local png = Material("rf/icons/" .. image .. ".png")
		surface.SetMaterial(png)
		surface.SetDrawColor(Color(255,255,255))
		local pos = (ent:GetPos() + Vector(0,0,ent:OBBMaxs().z+15)):ToScreen()
		if arrow then
			surface.DrawTexturedRectRotated(pos.x, pos.y - 50, 50, 50, 0)
			surface.SetMaterial(trace)
			surface.SetDrawColor(Color(255,255,255))
			surface.DrawTexturedRectRotated(pos.x, pos.y, 50, 50, 0)
		else
			surface.DrawTexturedRectRotated(pos.x, pos.y, 50, 50, 0)
		end
		if image == "alphaomega" then
			for b = 1, 3 do
				draw.SimpleTextOutlined("A L P H A O M E G A", "size115", pos.x + math.Rand(-16,16), pos.y + math.Rand(-16,16) - 120, Color(math.random(255),math.random(255),math.random(255)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(math.random(255),math.random(255),math.random(255)))
			end
			draw.SimpleTextOutlined("A L P H A O M E G A", "size115", pos.x, pos.y - 120, Color(math.random(155,255),math.random(155,255),math.random(155,255)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(math.random(95),math.random(95),math.random(95)))
		end
	end
end

function TraceEntityText(ent, text)
	if IsValid(ent) then
		local pos = (ent:GetPos() + Vector(0,0,ent:OBBMaxs().z+15)):ToScreen()
		surface.SetMaterial(trace)
		surface.SetDrawColor(Color(255,255,255))
		surface.DrawTexturedRectRotated(pos.x, pos.y, 50, 50, 0)
		draw.SimpleTextOutlined(text, "size65", pos.x, pos.y - 50, Color(194,194,194), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))
	end
end

function drawdamage(amount, kilos, dmgtype, ent, fallback_vector, track)
	if !fallback_vector or !isvector(fallback_vector) then fallback_vector = Vector(0,0,0) end
	local drawpos = fallback_vector
	if IsValid(ent) && isentity(ent) then
		if !ent.headbone then ent.headbone = "head" end
		if ent:LookupBone(ent.headbone) != nil then
			drawpos = ent:GetBonePosition(ent:LookupBone(ent.headbone))
		else
			drawpos = ent:GetPos() + Vector(0,0,ent:OBBMaxs().z)
		end
	end
	local matset = dmg1
	-- if dmgtype == 2 then matset = dmg2 end
	-- if dmgtype == 14 or dmgtype == 15 or dmgtype == 16 or dmgtype == 17 then matset = nums end
	drawpos = (drawpos):ToScreen()
	local colours = {Color(255,255,255), Color(255,127,0), Color(0,0,255), Color(0,255,0), Color(0,117,0), Color(133,255,255), Color(127,0,255), Color(255,255,0), Color(133,255,133), Color(137,0,0), Color(0,127,255), Color(255,0,0), Color(137,137,137), Color(66,66,255), Color(127.5 + (math.sin(CurTime()*2)*127.5) + 33, 33, 33), Color(255,167,0), Color(172,66,0)}
	--generic: 1
	--fire: 2
	--shock: 3
	--corrosive: 4
	--poison: 5
	--cryo: 6
	--slag: 7
	--explosive: 8
	--heal: 9
	--bleed: 10
	--shield damage: 11
	--player health damage: 12
	--armour damage: 13
	--add score: 14
	--subtract score: 15
	--add gold: 16
	--subtract gold: 17
	local calc = track - math.max(0,CurTime()-2)
	local mult = math.min(1, calc)
	local perc = mult - 1
	local ang = 400*perc
	surface.SetDrawColor(Color(colours[math.Clamp(dmgtype,1,#colours)].r,colours[math.Clamp(dmgtype,1,#colours)].g,colours[math.Clamp(dmgtype,1,#colours)].b))
	for i = 1, string.len(amount) do
		local c = tonumber(string.sub(amount, i, i))
		surface.SetMaterial(matset[c+1])
		if i > math.ceil(string.len(amount)/2) then
			surface.DrawTexturedRectRotated(drawpos.x + (100*(i-1)) - (string.len(amount)*50) + 35 - (115*perc), drawpos.y - (215*perc), 100, 150*mult, ang)
		else
			surface.DrawTexturedRectRotated(drawpos.x + (100*(i-1)) - (string.len(amount)*50) + 35 + (115*perc), drawpos.y - (215*perc), 100, 150*mult, -ang)
		end
	end
	if kilos > 0 then
		surface.SetDrawColor(Color(255,255,255))
		surface.SetMaterial(powers[math.Clamp(kilos,1,#powers)])
		surface.DrawTexturedRectRotated(drawpos.x + 100*string.len(amount) - (string.len(amount)*(50)) + 35 - (115*perc), drawpos.y - (215*perc), 150, 150*mult, ang)
	end
end
	
if !dmgpoptbl then dmgpoptbl = {} end

function AddDmgPop(amount, kilos, dmgtype, ent, vector)
	local newpopoff = { ["amount"] = amount, ["kilos"] = kilos, ["type"] = dmgtype, ["ent"] = ent, ["vector"] = vector, ["track"] = CurTime() }
	if !dmgpoptbl then dmgpoptbl = {} end
	table.insert(dmgpoptbl, newpopoff)
end

net.Receive("dmgpop", function()
	local net1 = net.ReadUInt(32)
	local net2 = net.ReadUInt(8)
	local net3 = net.ReadUInt(8)
	local net4 = net.ReadEntity()
	local net5 = net.ReadVector()
	AddDmgPop(net1,net2,net3,net4,net5)
end)

function CycleLanguages()
	if GetConVar("jensmansion_language"):GetString() == "gb" then
		RunConsoleCommand("jensmansion_language", "ru")
	elseif GetConVar("jensmansion_language"):GetString() == "ru" then
		RunConsoleCommand("jensmansion_language", "cn")
	elseif GetConVar("jensmansion_language"):GetString() == "cn" then
		RunConsoleCommand("jensmansion_language", "jp")
	else
		RunConsoleCommand("jensmansion_language", "gb")
	end
end

function Loading(time)
	local framebar = vgui.Create( "DFrame" )
	framebar:SetTitle( "" )
	framebar:SetSize( ScrW(), ScrH() )
	framebar:Center()
	framebar:ShowCloseButton(false)
	framebar:MakePopup()
	framebar.Paint = function( self, w, h ) -- 'function Frame:Paint( w, h )' works too
		draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 155 ) ) -- Draw a red box instead of the frame
	end
	local bar = vgui.Create( "DProgress", framebar )
	bar:SetPos(ScrW()/2 - 250, ScrH()/2 - 25)
	bar:SetSize(500, 50)
	bar:SetFraction(0)
	for i = 1, 100 do
		timer.Simple(i * time/100, function() if IsValid(bar) then
			bar:SetFraction(bar:GetFraction() + 0.01)
		end end)
	end
	timer.Simple(time + 0.01, function() if IsValid(framebar) then framebar:Close() LocalPlayer():EmitSound("rf/menu_highlight.wav") end end)
end

function OpenSettingsMenu()
	local frame = vgui.Create( "DFrame" )
	frame:SetTitle( "Settings" )
	frame:SetSize( ScrW()/2, ScrH()/1.5 )
	frame:Center()
	frame:MakePopup()
	frame.Paint = function( self, w, h ) -- 'function Frame:Paint( w, h )' works too
		draw.RoundedBox( 15, 0, 0, w, h, Color( 35, 35, 35, 255 ) ) -- Draw a red box instead of the frame
	end
end

function OpenUpgradeUI()
	local ply = LocalPlayer()
	local frame = vgui.Create( "DFrame" )
	frame:SetTitle("WeaponSequencer7000[TM]")
	frame:SetSize( ScrW()/1.35, ScrH()/1.1 )
	frame:Center()
	frame:MakePopup()
	frame.Paint = function( self, w, h )
		draw.RoundedBox( 15, 0, 0, w, h, Color( 35, 35, 35, 255 ) )
	end
	local eligible = {}
	for k, v in pairs(ply:GetWeapons()) do
		if v:GetClass() != "weapon_crowbar" && v:GetClass() != "tfa_nmrih_pickaxe" && v:GetClass() != "weapon_stunstick" && v:GetClass() != "weapon_d20" && v:GetClass() != "weapon_frag" && v:GetNWInt("damage",-1) > -1 then
			table.insert(eligible, v)
		end
	end
	for i = 1, #eligible do
		local button1 = vgui.Create( "DButton", frame )
		button1:SetText(eligible[i]:GetPrintName())
		button1:SetPos(25, 25 + (17*(i-1)))
		button1:SetSize(ScrW()/1.35 - 50,17 )
		button1:SetFont( "size27" )
		function button1:DoClick()
			OpenUpgradeUI_Weapon(eligible[i])
			ply:EmitSound("rf/click.wav")
		end
	end
end

net.Receive("station_openUI", OpenUpgradeUI)

function NETCODE_RequestUpgrade(weapon, requesttype, quantity)
	local ply = LocalPlayer()
	net.Start("station_requestuse")
		net.WriteString(requesttype)
		net.WriteEntity(weapon)
		net.WriteEntity(ply)
		net.WriteInt(quantity, 32)
		net.WriteString(ply:SteamID())
		net.WriteString(ply:SteamID64())
		net.WriteString(ply:SteamID()..ply:SteamID64())
	net.SendToServer()
end

hook.Add( "Think", "Think_Lights!", function()
	if LocalPlayer().LightsEnabled then
		for k, v in pairs(player.GetAll()) do
		local dlight = DynamicLight( v:EntIndex() )
			if ( dlight ) then
				dlight.pos = v:GetPos() + v:OBBCenter()
				dlight.r = 255
				dlight.g = 255
				dlight.b = 255
				dlight.brightness = 0.2
				dlight.Decay = 1000
				dlight.Size = 512
				dlight.DieTime = CurTime() + 1
			end
		end
	end
	local proximity = 1000
	if game.GetMap() == "gm_tilted_towers_v7" then proximity = 400 end
	for k, c in pairs(ents.FindInSphere(LocalPlayer():GetPos(), proximity)) do
		if c:GetClass() == "cw3_chest" && !IsValid(c:GetParent()) then
			local colours = {Color(255,255,255),Color(0,255,0),Color(0,53,255),Color(127,0,255),Color(255,137,0),Color(0,255,255)}
			local dlight = DynamicLight( c:EntIndex() )
			if !c.LootAmbient then c.LootAmbient = CreateSound(c, "rf/loot_ambient.wav") end
			if c:GetMaxHealth() > 0 then
				c.LootAmbient:Play()
				c.LootAmbientTime = CurTime() + 0.5
				if ( dlight ) then
					dlight.pos = c:GetPos() + c:OBBCenter()
					dlight.r = colours[math.Clamp(c:GetMaxHealth(),1,#colours)].r
					dlight.g = colours[math.Clamp(c:GetMaxHealth(),1,#colours)].g
					dlight.b = colours[math.Clamp(c:GetMaxHealth(),1,#colours)].b
					dlight.brightness = 0.2
					dlight.Decay = 1000
					dlight.Size = 512
					dlight.DieTime = CurTime() + 1
				end
			elseif c.LootAmbient:IsPlaying() then
				c.LootAmbient:Stop()
				c:EmitSound("rf/winner.mp3")
			end
		end
	end
	for k, d in pairs(ents.FindByClass("cw3_chest")) do
		if d.LootAmbient then
			if !d.LootAmbientTime then d.LootAmbientTime = 0 end
			if CurTime() >= d.LootAmbientTime && d.LootAmbient:IsPlaying() then
				d.LootAmbient:Stop()
				d.LootAmbientTime = 0
			end
		end
	end
end )

function OpenUpgradeUI_Weapon(weapon)
	local ply = LocalPlayer()
	if !ply.RequestQuantity then ply.RequestQuantity = 1 end
	local frame = vgui.Create( "DFrame" )
	frame:SetTitle(weapon:GetPrintName())
	frame:SetSize( ScrW()/1.35, ScrH()/1.1 )
	frame:Center()
	frame:MakePopup()
	frame.Paint = function( self, w, h )
		draw.RoundedBox( 15, 0, 0, w, h, Color( 75, 75, 75, 255 ) )
	end
	local nextlevelmultiplier = 1.07
	local nextrankmultiplier = 1.1
	local nextlevel = math.ceil(100 * ((weapon:GetNWInt("rarity",0)+1)^nextlevelmultiplier))
	local nextprestige = math.ceil(30000*(1+weapon:GetNWInt("wepprestige",0)))
	local nextrank = math.ceil(300 * ((weapon:GetNWInt("wrank",0))^nextrankmultiplier))
	local text_type = { "Level Up [$" .. string.Comma(nextlevel) .. "]", "Prestige [$" .. string.Comma(nextprestige) .. "] [1 Prestige]", "Evolve [$" .. string.Comma(nextrank) .. "]", "Refresh Prices (netcode can sometimes lag behind)" }
	local quota = 1
	if weapon:GetNWInt("rarity",0) >= 10*weapon:GetNWInt("wrank",1) then quota = 2 end
	for i = quota, 4 do
		local button1 = vgui.Create( "DButton", frame )
		button1:SetText(text_type[i])
		button1:SetPos(25, 25 + (32*(i-1)))
		button1:SetSize(ScrW()/1.35 - 50,32 )
		button1:SetFont( "size40" )
		if i == 1 then
			function button1:DoClick()
				if ply:GetNWInt("dosh",0) >= nextlevel then
					frame:Close()
					NETCODE_RequestUpgrade(weapon, "level", ply.RequestQuantity)
					ply:EmitSound("rf/rank_up.wav")
					if ply.RequestQuantity < 2 then
						Loading(0.5)
						timer.Simple(0.5, function() OpenUpgradeUI_Weapon(weapon) end)
					end
				else
					ply:EmitSound("rf/click.wav")
					ply:PrintMessage(HUD_PRINTTALK, "I can't do that - requirements are not met!")
				end
			end
		elseif i == 2 then
			function button1:DoClick()
				if ply:GetNWInt("dosh",0) >= nextprestige && ply:GetNWInt("prestige",0) > 0 then
					frame:Close()
					NETCODE_RequestUpgrade(weapon, "prestige", 1)
					ply:EmitSound("rf/starup.wav")
					if ply.RequestQuantity < 2 then
						Loading(0.5)
						timer.Simple(0.5, function() OpenUpgradeUI_Weapon(weapon) end)
					end
				else
					ply:EmitSound("rf/click.wav")
					ply:PrintMessage(HUD_PRINTTALK, "I can't do that - requirements are not met!")
				end
			end
		elseif i == 3 then
			function button1:DoClick()
				if ply:GetNWInt("dosh",0) >= nextrank then
					frame:Close()
					NETCODE_RequestUpgrade(weapon, "rank", ply.RequestQuantity)
					ply:EmitSound("rf/evolve_v2.mp3")
					if ply.RequestQuantity < 2 then
						Loading(0.5)
						timer.Simple(0.5, function() OpenUpgradeUI_Weapon(weapon) end)
					end
				else
					ply:EmitSound("rf/click.wav")
					ply:PrintMessage(HUD_PRINTTALK, "I can't do that - requirements are not met!")
				end
			end
		else
			function button1:DoClick()
				frame:Close()
				OpenUpgradeUI_Weapon(weapon)
				ply:EmitSound("rf/click.wav")
			end
		end
	end
	local button2_value = vgui.Create( "DLabel", frame )
	button2_value:SetText("If the server doesn't receive your request for more than 1.5 minutes, try again.\nThis process is handled using netcode.")
	button2_value:SetFont("size35")
	button2_value:SetPos((ScrW()/1.35)/3.25, ScrH()/1.5)
	button2_value:SetSize(ScrW()/1.35,50)
	local multiplier = vgui.Create( "DLabel", frame )
	multiplier:SetText("Purchase Quantity: x" .. string.Comma(ply.RequestQuantity))
	multiplier:SetFont("size65")
	multiplier:SetPos((ScrW()/1.35)/3.25, ScrH()/2)
	multiplier:SetSize(ScrW()/1.35,50)
	for i = 1, 6 do
		if i < 4 then
			local button1 = vgui.Create( "DButton", frame )
			button1:SetText(string.rep("<", i))
			button1:SetPos(((ScrW()/1.35)/3.25) - (50*i), ScrH()/2)
			button1:SetSize(50,50)
			button1:SetFont( "size40" )
			function button1:DoClick()
				ply.RequestQuantity = math.max(1, ply.RequestQuantity - (tonumber("1" .. string.rep("0", i-1))))
				ply:EmitSound("rf/menu_highlight.wav")
				multiplier:SetText("Purchase Quantity: x" .. string.Comma(ply.RequestQuantity))
			end
		else
			local button1 = vgui.Create( "DButton", frame )
			button1:SetText(string.rep(">", i-3))
			button1:SetPos(((ScrW()/1.35)/3.25) + 200 + (50*i), ScrH()/2)
			button1:SetSize(50,50)
			button1:SetFont( "size40" )
			function button1:DoClick()
				ply.RequestQuantity = math.max(1, ply.RequestQuantity + (tonumber("1" .. string.rep("0", i-4))))
				ply:EmitSound("rf/menu_highlight.wav")
				multiplier:SetText("Purchase Quantity: x" .. string.Comma(ply.RequestQuantity))
			end
		end
	end
end

function OpenCraftworldMenu()
	local frame = vgui.Create( "DFrame" )
	frame:SetTitle( "CRAFTWORLD3 MENU" )
	frame:SetSize( ScrW()/2, ScrH()/1.5 )
	frame:Center()
	frame:MakePopup()
	frame.Paint = function( self, w, h )
		draw.RoundedBox( 15, 0, 0, w, h, Color( 35, 35, 35, 255 ) )
	end
	local button2 = vgui.Create( "DButton", frame )
	button2:SetText(phrase_Language)
	button2:SetPos(25, 55)
	button2:SetSize(250,30)
	button2:SetFont( "size35" )
	function button2:DoClick()
	CycleLanguages()
	ply:EmitSound("rf/click.wav")
	frame:Close()
	Loading(1)
	timer.Simple(1, function() OpenCraftworldMenu() end)
	end
	local button2_value = vgui.Create( "DLabel", frame )
	button2_value:SetText(GetConVar("jensmansion_language"):GetString())
	button2_value:SetFont("size35")
	button2_value:SetPos(275, 55)
	button2_value:SetSize(250,30)
	--[[ local button3 = vgui.Create( "DButton", frame )
	button3:SetText("Camera")
	button3:SetPos(25, 85)
	button3:SetSize(250,30)
	button3:SetFont( "size35" )
	function button3:DoClick()
	LocalPlayer():EmitSound("rf/menu_open.wav")
	frame:Close()
	if LocalPlayer().ViewCamera == "shoulder" then
		LocalPlayer().ViewCamera = "overhead"
	elseif LocalPlayer().ViewCamera == "overhead" then
		LocalPlayer().ViewCamera = "dynamic firstperson"
	elseif LocalPlayer().ViewCamera == "dynamic firstperson" then
		LocalPlayer().ViewCamera = "static firstperson"
	else
		LocalPlayer().ViewCamera = "shoulder"
	end
	Loading(0.25)
	timer.Simple(0.15, function() OpenCraftworldMenu() end)
	end
	local button3_value = vgui.Create( "DLabel", frame )
	button3_value:SetText(LocalPlayer().ViewCamera)
	button3_value:SetFont("size35")
	button3_value:SetPos(275, 85)
	button3_value:SetSize(250,30) ]]
	local button3 = vgui.Create( "DButton", frame )
	button3:SetText("Toggle Thirdperson")
	button3:SetPos(25, 85)
	button3:SetSize(250,30)
	--button3:SetColor(Color(255,0,0))
	button3:SetFont( "size35" )
	function button3:DoClick()
		ply:EmitSound("rf/click.wav")
		RunConsoleCommand("thirdperson_ots")
	end
	-- local button4 = vgui.Create( "DButton", frame )
	-- button4:SetText("Horde Health Bar")
	-- button4:SetPos(25, 115)
	-- button4:SetSize(250,30)
	-- button4:SetFont( "size35" )
	-- function button4:DoClick()
	-- LocalPlayer():EmitSound("rf/menu_open.wav")
	-- frame:Close()
	-- if LocalPlayer().HordeBar == "disabled" then
		-- LocalPlayer().HordeBar = "2k hp per bar"
	-- elseif LocalPlayer().HordeBar == "2k hp per bar" then
		-- LocalPlayer().HordeBar = "5k hp per bar"
	-- elseif LocalPlayer().HordeBar == "5k hp per bar" then
		-- LocalPlayer().HordeBar = "20k hp per bar"
	-- elseif LocalPlayer().HordeBar == "20k hp per bar" then
		-- LocalPlayer().HordeBar = "75k hp per bar"
	-- elseif LocalPlayer().HordeBar == "75k hp per bar" then
		-- LocalPlayer().HordeBar = "100k hp per bar"
	-- elseif LocalPlayer().HordeBar == "100k hp per bar" then
		-- LocalPlayer().HordeBar = "dynamic scaling"
	-- else
		-- LocalPlayer().HordeBar = "disabled"
	-- end
	-- Loading(0.15)
	-- timer.Simple(0.15, function() OpenCraftworldMenu() end)
	-- end
	-- local button4_value = vgui.Create( "DLabel", frame )
	-- button4_value:SetText(LocalPlayer().HordeBar)
	-- button4_value:SetFont("size35")
	-- button4_value:SetPos(275, 115)
	-- button4_value:SetSize(250,30)
	local button5 = vgui.Create( "DButton", frame )
	button5:SetText("Player Overheads")
	button5:SetPos(25, 145)
	button5:SetSize(250,30)
	button5:SetFont( "size35" )
	function button5:DoClick()
	ply:EmitSound("rf/click.wav")
	frame:Close()
	if LocalPlayer().OverheadInfoP == "crosshair only" then
		LocalPlayer().OverheadInfoP = "always"
	elseif LocalPlayer().OverheadInfoP == "always" then
		LocalPlayer().OverheadInfoP = "minimal"
	elseif LocalPlayer().OverheadInfoP == "minimal" then
		LocalPlayer().OverheadInfoP = "never"
	else
		LocalPlayer().OverheadInfoP = "crosshair only"
	end
	Loading(0.25)
	timer.Simple(0.15, function() OpenCraftworldMenu() end)
	end
	local button5_value = vgui.Create( "DLabel", frame )
	button5_value:SetText(LocalPlayer().OverheadInfoP)
	button5_value:SetFont("size35")
	button5_value:SetPos(275, 145)
	button5_value:SetSize(250,30)
	local button6 = vgui.Create( "DButton", frame )
	button6:SetText("Sobel")
	button6:SetPos(25, 175)
	button6:SetSize(250,30)
	button6:SetFont( "size35" )
	function button6:DoClick()
	ply:EmitSound("rf/click.wav")
	frame:Close()
	if LocalPlayer().Sobel then
		LocalPlayer().Sobel = false
	else
		LocalPlayer().Sobel = true
	end
	Loading(0.25)
	timer.Simple(0.15, function() OpenCraftworldMenu() end)
	end
	local button6_value = vgui.Create( "DLabel", frame )
	button6_value:SetText(tostring(LocalPlayer().Sobel))
	button6_value:SetFont("size35")
	button6_value:SetPos(275, 175)
	button6_value:SetSize(250,30)
	local button7 = vgui.Create( "DButton", frame )
	button7:SetText("Music")
	button7:SetPos(25, 205)
	button7:SetSize(250,30)
	button7:SetFont( "size35" )
	if !file.Exists("sound/rf/ambience_lv0.wav", "GAME") then
		button7:SetColor(Color(255,0,0))
	end
	function button7:DoClick()
		if file.Exists("sound/rf/ambience_lv0.wav", "GAME") then
			ply:EmitSound("rf/click.wav")
			frame:Close()
			if LocalPlayer().MusicEnable then
				LocalPlayer().MusicEnable = false
			else
				LocalPlayer().MusicEnable = true
			end
			Loading(0.25)
			timer.Simple(0.15, function() OpenCraftworldMenu() end)
		end
	end
	local button7_value = vgui.Create( "DLabel", frame )
	if !file.Exists("sound/rf/ambience_lv0.wav", "GAME") then
		button7_value:SetColor(Color(255,0,0))
		button7_value:SetText("missing music files")
	else
		button7_value:SetText(tostring(LocalPlayer().MusicEnable))
	end
	button7_value:SetFont("size35")
	button7_value:SetPos(275, 205)
	button7_value:SetSize(250,30)
	local button9 = vgui.Create( "DButton", frame )
	button9:SetText("Player Shine")
	button9:SetPos(25, 265)
	button9:SetSize(250,30)
	button9:SetFont( "size35" )
	function button9:DoClick()
		ply:EmitSound("rf/click.wav")
		frame:Close()
		if LocalPlayer().LightsEnabled then
			LocalPlayer().LightsEnabled = false
		else
			LocalPlayer().LightsEnabled = true
		end
		OpenCraftworldMenu()
	end
	local button9_value = vgui.Create( "DLabel", frame )
	button9_value:SetText(tostring(LocalPlayer().LightsEnabled or "false"))
	button9_value:SetFont("size35")
	button9_value:SetPos(275, 265)
	button9_value:SetSize(250,30)
end

concommand.Add("cw2menu", function()
	OpenCraftworldMenu()
end)

function bl_hud() 
  -- surface.SetTexture( surface.GetTextureID( "bl_hud/hud_icons" ) ) 
	-- surface.SetDrawColor(Color(0,167,0,255)) 
  -- surface.DrawPartialTexturedRectRotated ((ScrW()/1.05),(ScrH()/1.4),(ScrW()/57.6), (ScrH()/36), 448, 128, 64, 64, 512, 256, -4.5 )
--draw.NixieText( string.Comma(LocalPlayer():GetAmmoCount("smg1_grenade")) .. " Max Grenades", "size70",(ScrW()/1.013),(ScrH()/1.185), Color(0, 167, 0,255),2, 4,2,Color(0, 0, 0),0)
end 
hook.Add("HUDPaint", "BL_HUD", bl_hud) 

local function bl_hud_cond()
local ply = LocalPlayer()

local bordermat = Material(configdata["visor_textures"]["top"] or "materials/rf/eva/top.png")
surface.SetDrawColor(255, 255, 255, 255)
surface.SetMaterial(bordermat)
surface.DrawTexturedRect(0, -100, ScrW(), 400)
local bordermat2 = Material(configdata["visor_textures"]["bottom"] or "materials/rf/eva/bottom.png")
surface.SetDrawColor(255, 255, 255, 255)
surface.SetMaterial(bordermat2)
surface.DrawTexturedRect(0, ScrH()-400, ScrW(), 400)

if ply:GetNWInt("healthstate",0) <= 3 then
local transparency = 255/(math.max(1,ply:GetNWInt("healthstate",0))^2)
surface.SetDrawColor(255, 255, 255, transparency)
surface.SetMaterial(lowhealthoverlay)
surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
end

if ply:GetNWInt("healthstate",0) <= 1 then --draw a pulsing duplicate
local transparency = ((CurTime()*3) % 2.55) * 100
surface.SetDrawColor(255, 255, 255, 255 - transparency)
surface.SetMaterial(lowhealthoverlay)
surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
end

if !ply.GodmodeAmb then ply.GodmodeAmb = CreateSound(ply, "rf/ritual_loop.wav") end
if ply:GetNWBool("cw3godmode", false) then
	ply.GodmodeAmb:Play()
	ply.GodmodeAmb:ChangePitch(80)
	DrawMaterialOverlay("effects/invuln_overlay_blue", 0.03)
	DrawMaterialOverlay("effects/invuln_overlay_blue", 0.03)
elseif ply.GodmodeAmb then
	ply.GodmodeAmb:Stop()
end

if not ply:GetNWBool("cw3godmode", false) then
	if ply:GetNWInt("healthstate",0) <= 1 then
		DrawMaterialOverlay("effects/invuln_overlay_red", 0.03)
	end
end

if PickupInformed == nil then PickupInformed = false end

	local ply = LocalPlayer()
	if !IsValid(ply) then return end
	
	local eyetrace = ply:GetEyeTrace().Entity
	
	if IsValid(eyetrace) then
		local pos = (eyetrace:GetPos() + eyetrace:OBBCenter()):ToScreen()
		if eyetrace:GetClass() == "cw3_pickup" then
			local rarities = { phrase_Common, phrase_Uncommon, phrase_Rare, phrase_Epic, phrase_Legendary, phrase_Mythic, phrase_Wondrous, phrase_Infinite, phrase_Omega, phrase_Alphaomega, phrase_Special }
			local colours = { Color(159,159,159), Color(0,255,0), Color(0,133,255), Color(127,0,255), Color(255,133,0), Color(0,255,255), Color(255,0,0), Color(0,0,255), Color(255 + (math.sin(CurTime()*2)*255),255 + (math.sin(CurTime()*3.15)*255),255 + (math.sin(CurTime()*4.3)*255)), Color(0,0,0), Color(255,0,255) }
			if eyetrace:GetNWInt("pickrarity",1) == 9 then
				local string1 = rarities[9]
				local string2 = eyetrace:GetNWString("pickname","?")
				if eyetrace:GetNWInt("pickamount",1) > 1 then
					string2 = string2 .. " x" .. eyetrace:GetNWInt("pickamount",1)
				end
				local string1n = string.len(string1)
				local string2n = string.len(string2)
				for a = 1, string1n do
					draw.NixieText(string.sub(string.reverse(string1), a, a), "size" .. math.Round(90 + (math.sin(CurTime()-a)*20)), pos.x-30*a, pos.y+(math.sin(CurTime()*2 - (10*a))*8), Color(255,133,133), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, colours[eyetrace:GetNWInt("pickrarity",1)])
				end
				for b = 1, string2n do
					draw.NixieText(string.sub(string2, b, b), "size" .. math.Round(90 + (math.sin(CurTime()+b)*20)), pos.x+30*b, pos.y-(math.sin(CurTime()*2 - (10*b))*8), colours[eyetrace:GetNWInt("pickrarity",1)], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(255,133,133))
				end
			elseif eyetrace:GetNWInt("pickrarity") == 10 then
				local shakescale = 16
				if eyetrace:GetNWString("pickamount","?") != "?" then
					local quantity = "x" .. eyetrace:GetNWString("pickamount", "?")
					local pickup_name = eyetrace:GetNWString("pickname","?")
					surface.SetFont("size80")
					local width, height = surface.GetTextSize(pickup_name)
					for a = 1, 3 do
						draw.NixieText(pickup_name, "size80", pos.x + math.Rand(-shakescale,shakescale), pos.y + math.Rand(-shakescale,shakescale), Color(math.random(255),math.random(255),math.random(255)),TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(math.random(255),math.random(255),math.random(255)))
					end
					draw.NixieText(quantity, "size65", pos.x+(width/2), pos.y, Color(255,255,0),TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 2, Color(0,0,0))
					draw.NixieText(pickup_name, "size80", pos.x, pos.y, colours[eyetrace:GetNWInt("pickrarity",1)],TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0,0,0))
				else
					for a = 1, 3 do
						draw.NixieText(eyetrace:GetNWString("pickname","?"), "size80", pos.x + math.Rand(-shakescale,shakescale), pos.y + math.Rand(-shakescale,shakescale), Color(math.random(255),math.random(255),math.random(255)),TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(math.random(255),math.random(255),math.random(255)))
					end
					draw.NixieText(eyetrace:GetNWString("pickname","?"), "size80", pos.x, pos.y, colours[eyetrace:GetNWInt("pickrarity",1)],TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0,0,0))
				end
			else
				draw.NixieText(eyetrace:GetNWString("pickname","?"), "size80", pos.x, pos.y, colours[eyetrace:GetNWInt("pickrarity",1)],TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0,0,0))
			end
			if eyetrace:GetNWInt("pickrarity",1) != 9 then
				draw.NixieText(rarities[eyetrace:GetNWInt("pickrarity",1)], "size100", pos.x, pos.y-45, Color(0,0,0),TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, colours[eyetrace:GetNWInt("pickrarity",1)])
			end
			draw.NixieText(eyetrace:GetNWString("pickdesc",""), "size45", pos.x, pos.y+105, Color(167,167,167),TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(28,28,28), 0, true)
		elseif eyetrace:GetClass() == "cw3_container" then
			if eyetrace:GetMaxHealth() > eyetrace:Health() then
				draw.SimpleTextOutlined("Searching [" .. eyetrace:Health()/100 .. "]", "size70", pos.x, pos.y, Color(255,255,255),TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0,0,0))
			end
		elseif isnumber(eyetrace:GetNWInt("64health","?")) && (string.find(eyetrace:GetClass(), "prop_") or string.find(eyetrace:GetClass(), "gmod_") or string.find(eyetrace:GetClass(), "func_") or eyetrace:GetClass() == "ent_fortnitestructure") then
			if eyetrace:GetMaterial() != "" then
				draw.SimpleTextOutlined(string.squash(eyetrace:GetNWInt("64health","?")), "size80", pos.x, pos.y, Color(0,168,255),TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 2, Color(0,255,255))
			else
				draw.SimpleTextOutlined(string.squash(eyetrace:GetNWInt("64health","?")), "size80", pos.x, pos.y, Color(255,164,0),TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 2, Color(35,0,0))
			end
			draw.SimpleTextOutlined(string.squash(eyetrace:GetNWInt("64maxhealth","?")), "size50", pos.x, pos.y, Color(133,97,0),TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 2, Color(35,0,0))
		end
	end

	local proximity = 350
	if game.GetMap() == "gm_tilted_towers_v7" then proximity = 180 end
	for k, b in pairs(ents.FindInSphere(ply:GetPos(), proximity)) do
		if !IsValid(b:GetParent()) then
			if b:GetClass() == "cw3_chest" then
				if b:GetMaxHealth() > 0 then
					if string.find(b:GetModel(), "safe") or string.find(b:GetModel(), "loot_tall") then
						local safetype = {"","Safe","Large Safe", "Gilded Safe", "Huge Vault"}
						TraceEntityText(b, safetype[b:GetMaxHealth()] or "?")
					else
						TraceEntity(b, tostring("loot" .. math.Clamp(b:GetMaxHealth(),1,6)))
					end
				end
			end
		end
	end
	
	for k, pickup in pairs(ents.FindByClass("cw3_pickup")) do
		if IsValid(pickup) then
			if !PickupInformed then
				pickup.PopupTutorial = true
				PickupInformed = true
			end
			if pickup.PopupTutorial then
				-- if GetConVar("jensmansion_language","gb"):GetString() == "ru" then
					-- TraceEntityText(pickup, "Нажмите [" .. string.upper(input.LookupBinding("+use", true)) .. "], чтобы забрать предмет")
				-- elseif GetConVar("jensmansion_language","gb"):GetString() == "jp" then
					-- TraceEntityText(pickup, "アイテムドロップを拾うには[" .. string.upper(input.LookupBinding("+use", true)) .. "]を押します")
				-- elseif GetConVar("jensmansion_language","gb"):GetString() == "cn" then
					-- TraceEntityText(pickup, "按[" .. string.upper(input.LookupBinding("+use", true)) .. "]选择项目丢弃")
				-- else
					-- TraceEntityText(pickup, "Press [" .. string.upper(input.LookupBinding("+use", true)) .. "] to pick up item drops")
				-- end
			elseif pickup:GetModel() == "models/items/tf_gift.mdl" then
				TraceEntityText(pickup, pickup:GetNWString("pickname","?"))
			elseif pickup:GetNWString("pickname","?") == "TecPad" then
				if pickup:GetNWInt("pickamount",1) > 1 then
					TraceEntityText(pickup, pickup:GetNWInt("pickamount",1) .. "x TecPad")
				else
					TraceEntityText(pickup, "TecPad")
				end
			elseif pickup:GetNWString("pickname","?") == "Mystic Dice" then
				if pickup:GetNWInt("pickamount",1) > 1 then
					TraceEntityText(pickup, pickup:GetNWInt("pickamount",1) .. "x Dice")
				else
					TraceEntityText(pickup, "Dice")
				end
			elseif (pickup:GetNWString("pickname","?") == "Bacon" or pickup:GetNWString("pickname","?") == "Health Injector" or pickup:GetNWString("pickname","?") == "Stimpack") && ply:GetNWInt("64health",0) <= ply:GetNWInt("64maxhealth",0)/5*3 then
				TraceEntityText(pickup, "Medical Item")
			elseif pickup:GetNWInt("pickrarity",1) == 9 then
				TraceEntity(pickup, "omega", true)
			elseif pickup:GetNWInt("pickrarity",1) == 10 then
				TraceEntity(pickup, "alphaomega", true)
			elseif pickup:GetNWInt("pickrarity",1) >= 8 && pickup:GetNWInt("pickrarity",1) < 10 then
				TraceEntity(pickup, "legendary", true)
			end
		end
	end
	
	if dmgpoptbl then
		for i = 1, #dmgpoptbl do
			local c = dmgpoptbl[i]
			if c != nil then
				if c["track"] < CurTime()-3 then
					table.remove(dmgpoptbl, i)
				else
					drawdamage(c["amount"], c["kilos"], c["type"], c["ent"], c["vector"], c["track"])
				end
			end
		end
	end
	
	for _, npc in ipairs(npcGetAll()) do
		
		if !IsValid(npc) then continue end
		if !npc:IsNPC() then continue end
		
		local NameExtension = ""
		
		local hpbar = normal
		
		if npc:GetNWInt("npcbadass", 1) == 38 then
			NameExtension = "Chubby "
			hpbar = chubby
		elseif npc:GetNWInt("npcbadass", 1) > 14 then
			if npc:GetClass() == "npc_zombie" then
			NameExtension = "Cavitius"
			elseif npc:GetClass() == "npc_zombie_torso" then
			NameExtension = "Halfee"
			elseif npc:GetClass() == "npc_fastzombie_torso" then
			NameExtension = "Crawlinilar"
			elseif npc:GetClass() == "npc_fastzombie" then
			NameExtension = "Fleshdigger"
			elseif npc:GetClass() == "npc_poisonzombie" then
			NameExtension = "Scythe"
			elseif npc:GetClass() == "npc_antlion" then
			NameExtension = "Antmivorous"
			elseif npc:GetClass() == "npc_antlionguard" then
			NameExtension = "Terramorphous the Invincible"
			elseif npc:GetClass() == "npc_headcrab" then
			NameExtension = "Mister Skaggles"
			elseif npc:GetClass() == "npc_headcrab_fast" then
			NameExtension = "Mister Bubbles"
			elseif npc:GetClass() == "npc_headcrab_black" then
			NameExtension = "Paroxysissalinilim"
			elseif npc:GetClass() == "npc_strider" then
			NameExtension = "Arr-Leg"
			elseif npc:GetClass() == "npc_manhack" then
			NameExtension = "Choppa"
			elseif npc:GetClass() == "npc_metropolice" then
			NameExtension = "Metro-Police Unit #1348"
			elseif npc:GetClass() == "npc_combine_s" then
			NameExtension = "Peterbite"
			elseif npc:GetClass() == "npc_turret_ceiling" then
			NameExtension = "The Watcher"
			elseif npc:GetClass() == "npc_turret_floor" then
			NameExtension = "Anti-Personnel Security Turret"
			elseif npc:GetClass() == "npc_cscanner" then
			NameExtension = "I"
			elseif npc:GetClass() == "npc_clawscanner" then
			NameExtension = "C.A.M.E.R.A."
			elseif npc:GetClass() == "npc_rollermine" then
			NameExtension = "Rolli-Polli"
			elseif npc:GetClass() == "npc_stalker" then
			NameExtension = "The Thing"
			elseif npc:GetClass() == "npc_combinegunship" then
			NameExtension = "Project S.E.A.L."
			elseif npc:GetClass() == "npc_helicopter" then
			NameExtension = "Hell-icopter"
			elseif npc:GetClass() == "npc_combine_camera" then
			NameExtension = "E.Y.E."
			elseif npc:GetClass() == "npc_dog" then
			NameExtension = "Dog P.A.T.R.I.A.R.C.H."
			elseif npc:GetClass() == "npc_vortigaunt" then
			NameExtension = "Guh-Lug"
			elseif npc:GetClass() == "npc_vj_larval_varkid" then
			NameExtension = "Baby Vermivorous"
			elseif npc:GetClass() == "npc_vj_adult_varkid" then
			NameExtension = "Alpha Varkid"
			elseif npc:GetClass() == "npc_vj_badass_varkid" then
			NameExtension = "Mr. Antlers"
			elseif npc:GetClass() == "npc_vj_super_badass_varkid" then
			NameExtension = "Son of Vermivorous"
			elseif npc:GetClass() == "npc_vj_nomad" then
			NameExtension = "Bad Maw"
			elseif npc:GetClass() == "npc_vj_bruiser" then
			NameExtension = "Muscles"
			elseif npc:GetClass() == "npc_vj_goliath" then
			NameExtension = "Smash-Head"
			elseif npc:GetClass() == "npc_vj_raging_goliath" then
			NameExtension = "Pissed-Head"
			elseif npc:GetClass() == "npc_vj_marauderkiller" then
			NameExtension = "Marauder Slaughterer"
			elseif npc:GetClass() == "npc_vj_maraudermoron" then
			NameExtension = "Marauder Retard"
			elseif npc:GetClass() == "npc_vj_marauderripper" then
			NameExtension = "Marauder Shredder"
			elseif npc:GetClass() == "npc_vj_maraudershotty" then
			NameExtension = "Marauder Boomstick"
			elseif npc:GetClass() == "npc_vj_badass_marauder" then
			NameExtension = "BadMutha Marauder"
			elseif npc:GetClass() == "npc_vj_suicide_psycho1" or npc:GetClass() == "npc_vj_suicide_psycho2" then
			NameExtension = "Boomtime"
			elseif npc:GetClass() == "npc_vj_badass_marauder" then
			NameExtension = "BadMutha Marauder"
			else
			NameExtension = "Boss " .. ( npc.Name or (language.GetPhrase(npc:GetClass())) )
			end
			npc.ClientBossName = NameExtension
		elseif npc:GetNWInt("npcbadass", 1) == 14 then
			NameExtension = "Brobdingnagian "
			hpbar = brobdingnagian
		elseif npc:GetNWInt("npcbadass", 1) == 11 then
			NameExtension = "Gigantic "
			hpbar = gigantic
		elseif npc:GetNWInt("npcbadass", 1) == 8 then
			NameExtension = "Enormous "
			hpbar = enormous
		elseif npc:GetNWInt("npcbadass", 1) == 7 then
			NameExtension = "Titan "
			hpbar = titan
		elseif npc:GetNWInt("npcbadass", 1) == 6 then
			NameExtension = "Massive "
			hpbar = massive
		elseif npc:GetNWInt("npcbadass", 1) == 5 then
			NameExtension = "Giant "
			hpbar = giant
		elseif npc:GetNWInt("npcbadass", 1) == 4 then
			NameExtension = "Behemoth "
			hpbar = behemoth
		elseif npc:GetNWInt("npcbadass", 1) == 3 then
			NameExtension = "Brawler "
			hpbar = brawler
		elseif npc:GetNWInt("npcbadass", 1) == 2 then
			NameExtension = "Brute "
			hpbar = brute
		elseif npc:GetNWInt("npcbadass", 1) == 0 then
			if npc:GetModelScale() >= 1 then
				NameExtension = "Giant Midget "
			else
				NameExtension = "Midget "
			end
			hpbar = midget
		else
			NameExtension = ""
		end
		
		local NameToUse = ""
		
		if npc:GetNWInt("npcbadass", 1) >= 15 && npc:GetNWInt("npcbadass", 1) != 38 then
			NameToUse = NameExtension
		else
			NameToUse = NameExtension .. ( npc.Name or (language.GetPhrase(npc:GetClass())) )
		end
		
		if npc:GetNWInt("npcevo",0) > 0 then
			NameToUse = NameToUse .. "+" .. npc:GetNWInt("npcevo",0)
		end
		
		if npc:GetNWString("npcelement", "NONE") != "NONE" then
			NameToUse = npc:GetNWString("npcelement", "[UNDEFINED]") .. " " .. NameToUse
		end
		
		if npc:GetNWInt("npcplus",0) > 0 then
			NameToUse = NameToUse .. " " .. string.rep("+", npc:GetNWInt("npcplus",0))
		end
		
		local npcHP, npcMaxHP, npcLevel, npcName = npc:GetNWInt("64health", 0), npc:GetNWInt("64maxhealth", -1), math.Round(npc:GetNWInt("npclevel", 1),1), NameToUse
		npc.InfoPos = (npc:GetPos() + Vector(0,0,npc:OBBMaxs().z)):ToScreen()
		
		npc.NPCLv = npcLevel
		npc.Validated = true
		
		local transparency = math.max(1,33 - #npcGetAll())
		
		local isaboss = false
		
		local isbrimstone = false
		
		local trace = ply:GetEyeTrace()

		if IsValid(trace.Entity) then
			if trace.Entity == npc then transparency = 255 end
		end
		
		if string.find(npc:GetNWString("botprefix", ""), "Boss") then
			transparency = 255
			isaboss = true
		end
		
		if string.find(npc:GetNWString("botprefix", ""), "Brimstone") then
			transparency = transparency * 2
			isbrimstone = true
		end
		
		local bossclass = {"npc_zombie", "npc_fastzombie", "npc_zombie_torso", "npc_fastzombie_torso", "npc_poisonzombie", "npc_headcrab", "npc_headcrab_fast", "npc_headcrab_black", "npc_antlion", "npc_antlionguard", "npc_combine_s", "npc_metropolice", "npc_manhack", "npc_rollermine", "npc_antlion_worker"}
		local bossname = {"Cavitius", "Fleshdigger", "Halfee", "Crawlinilar", "Scythe", "Mr. Skaggles", "Mr. Bubbles", "Paroxysissalinilim", "Verticidis", "Kilosaurus", "Supersoldier", "Metropolis Guardian", "C.H.O.P.P.E.R.", "Roadhog", "Spitacidaton"}
		local bossnamebrimstone = {"Hopscotch", "Quickdeath", "Hot Potato", "Skincooker", "Grim Reaper", "Mr. Deathggles", "Nimble Demise", "Devourer of Gods", "Blindslayer", "Kolossis", "Metropolis Destroyer", "I.N.C.I.N.E.R.A.T.O.R.", "Pitfall", "Phoenix"}
		local selectedbossname = npc:GetNWString("botprefix", "") .. (npc.Name or (language.GetPhrase(npc:GetClass())))
		
		if isaboss then
			for i = 1, #bossclass do
				if npc:GetClass() == bossclass[i] then
					if isbrimstone then
						selectedbossname = bossnamebrimstone[i]
					else
						selectedbossname = bossname[i]
					end
				end
			end
		end
		
		if !npc:GetNWBool("npcisdead") then
			if isbrimstone then
				if isaboss then
					draw.NixieText( selectedbossname .. " " .. npc:GetNWString("powerlevel", "?"), "size165",npc.InfoPos.x + (math.sin((CurTime()*2)+3)*15),npc.InfoPos.y + 15,  Color(68*(0.5 + (math.sin(CurTime()*3)/2)), 0, 0*(0.5 + (math.sin(CurTime()*3)/2)), transparency),TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,2,Color(20, 0, 80, transparency),0, true)
					draw.NixieText( npc:GetNWString("bothp","???") .. " / " .. npc:GetNWString("botmhp","???") .. " HP x " .. npc:GetNWInt("npclives",0) + 1 .. " Li" .. (npc:GetNWInt("npclives",0) > 0 and "ves" or "fe"), "size95",npc.InfoPos.x + (math.sin((CurTime()*2)+2)*15),npc.InfoPos.y-155,  Color(255, 133, 133, transparency),TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,2,Color(80, 50, 50, transparency),0, true)
					draw.NixieText( npc:GetNWString("botdamage","???") .. " Damage", "size95",npc.InfoPos.x + (math.sin((CurTime()*2)+1)*15),npc.InfoPos.y-105,  Color(255, 0, 0, transparency),TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,2,Color(80, 0, 0, transparency),0, true)
					draw.NixieText( "$" .. npc:GetNWString("botgold","???"), "size95",npc.InfoPos.x + (math.sin(CurTime()*2)*15),npc.InfoPos.y-55,  Color(255, 255, 0, transparency),TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,2,Color(80, 80, 0, transparency),0, true)
				else
					draw.NixieText( npc:GetNWString("botprefix", "") .. (npc.Name or (language.GetPhrase(npc:GetClass()))) .. " " .. npc:GetNWString("powerlevel", "?"), "size115",npc.InfoPos.x,npc.InfoPos.y - 5,  Color(178, 0, 0, transparency),TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,2,Color(0, 0, 80, transparency/2),0, true)
					draw.NixieText( npc:GetNWString("bothp","???") .. " / " .. npc:GetNWString("botmhp","???") .. " HP", "size65l",npc.InfoPos.x,npc.InfoPos.y-95,  Color(255, 133, 133, transparency),TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,2,Color(80, 50, 50, transparency/2),0, true)
					draw.NixieText( npc:GetNWString("botdamage","???") .. " Damage", "size65l",npc.InfoPos.x,npc.InfoPos.y-65,  Color(255, 0, 0, transparency),TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,2,Color(80, 0, 0, transparency/2),0, true)
					draw.NixieText( "$" .. npc:GetNWString("botgold","???"), "size65l",npc.InfoPos.x,npc.InfoPos.y-35,  Color(255, 255, 0, transparency),TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,2,Color(80, 80, 0, transparency/2),0, true)
				end
			else
				if isaboss then
					draw.NixieText( selectedbossname .. " " .. npc:GetNWString("powerlevel", "?"), "size135",npc.InfoPos.x + (math.sin((CurTime()*2)+3)*15),npc.InfoPos.y,  Color(127*(0.5 + (math.sin(CurTime()*3)/2)), 0, 255*(0.5 + (math.sin(CurTime()*3)/2)), transparency),TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,2,Color(20, 0, 80, transparency),0, true)
					draw.NixieText( npc:GetNWString("bothp","???") .. " / " .. npc:GetNWString("botmhp","???") .. " HP x " .. npc:GetNWInt("npclives",0) + 1 .. " Li" .. (npc:GetNWInt("npclives",0) > 0 and "ves" or "fe"), "size95",npc.InfoPos.x + (math.sin((CurTime()*2)+2)*15),npc.InfoPos.y-155,  Color(255, 133, 133, transparency),TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,2,Color(80, 50, 50, transparency),0, true)
					draw.NixieText( npc:GetNWString("botdamage","???") .. " Damage", "size95",npc.InfoPos.x + (math.sin((CurTime()*2)+1)*15),npc.InfoPos.y-105,  Color(255, 0, 0, transparency),TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,2,Color(80, 0, 0, transparency),0, true)
					draw.NixieText( "$" .. npc:GetNWString("botgold","???"), "size95",npc.InfoPos.x + (math.sin(CurTime()*2)*15),npc.InfoPos.y-55,  Color(255, 255, 0, transparency),TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,2,Color(80, 80, 0, transparency),0, true)
				else
					draw.NixieText( npc:GetNWString("botprefix", "") .. (npc.Name or (language.GetPhrase(npc:GetClass()))) .. " " .. npc:GetNWString("powerlevel", "?"), "size95",npc.InfoPos.x,npc.InfoPos.y,  Color(255, 255, 255, transparency),TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,2,Color(0, 0, 80, transparency/2),0, true)
					draw.NixieText( npc:GetNWString("bothp","???") .. " / " .. npc:GetNWString("botmhp","???") .. " HP", "size65l",npc.InfoPos.x,npc.InfoPos.y-95,  Color(255, 133, 133, transparency),TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,2,Color(80, 50, 50, transparency/2),0, true)
					draw.NixieText( npc:GetNWString("botdamage","???") .. " Damage", "size65l",npc.InfoPos.x,npc.InfoPos.y-65,  Color(255, 0, 0, transparency),TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,2,Color(80, 0, 0, transparency/2),0, true)
					draw.NixieText( "$" .. npc:GetNWString("botgold","???"), "size65l",npc.InfoPos.x,npc.InfoPos.y-35,  Color(255, 255, 0, transparency),TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,2,Color(80, 80, 0, transparency/2),0, true)
				end
			end
		elseif !isaboss then
			draw.NixieText( npc:GetNWString("botprefix", "") .. (npc.Name or (language.GetPhrase(npc:GetClass()))), "size95",npc.InfoPos.x,npc.InfoPos.y,  Color(188, 188, 188, transparency/3),TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,2,Color(0, 0, 0, 0),0, true)
		end

	end
	
	for k, v in pairs(ents.GetAll()) do
		if v:GetClass() == "cw3_powerup" then
			if !v.AuraSound then
				v.AuraSound = CreateSound(v, "rf/powerup_aura.wav")
			end
			if v.AuraSound && IsValid(v) then
				if v:GetMaterial() != "null" then
					v.AuraSound:Play()
				else
					v.AuraSound:Stop()
				end
			end
		end
	end
	
	for k, v in pairs(player.GetAll()) do
		if v:GetModel() == "models/vuthakral/halo/custom/usp/sangheili_h2a.mdl" then
			v.headbone = "head"
		else
			v.headbone = "ValveBiped.Bip01_Head1"
		end
		
		local boneoffset = -6
	
		local boneloc = v:GetBonePosition(v:LookupBone(v.headbone)) + Vector(0,0,boneoffset)
		if IsValid(v:GetRagdollEntity()) then
			boneloc = v:GetRagdollEntity():GetBonePosition(v:GetRagdollEntity():LookupBone(v.headbone))
		elseif v == LocalPlayer() && not LocalPlayer():GetNW2Bool("ThirtOTS", false) then
			boneloc = LocalPlayer():GetPos() + Vector(0,0, 5 + LocalPlayer():OBBMaxs().z)
		end

		if !v.BoneManipulatedArm then v.BoneManipulatedArm = "pure" end
		
		if !v.ShortModel then v.ShortModel = "pure" end
		
		if v:GetModel() == "models/marshadow_reference.mdl" then
			v.ShortModel = "unpure"
		else
			v.ShortModel = "pure"
		end
		
		local lookuphand = "ValveBiped.Bip01_L_Hand"
		local lookuphand2 = "ValveBiped.Bip01_R_Hand"
		if v.headbone == "head" then
			lookuphand = "l_hand"
			lookuphand2 = "r_hand"
		end

		local handloc, handang = v:GetBonePosition(v:LookupBone(lookuphand))
		if IsValid(v:GetRagdollEntity()) then
			handloc, handang = v:GetRagdollEntity():GetBonePosition(v:GetRagdollEntity():LookupBone(lookuphand))
		end
		local handloc2, handang2 = v:GetBonePosition(v:LookupBone(lookuphand2))
		if IsValid(v:GetRagdollEntity()) then
			handloc2, handang2 = v:GetRagdollEntity():GetBonePosition(v:GetRagdollEntity():LookupBone(lookuphand2))
		end
		
		local lookupleg = "ValveBiped.Bip01_L_Foot"
		local lookupleg2 = "ValveBiped.Bip01_R_Foot"
		if v.headbone == "head" then
			lookupleg = "l_foot"
			lookupleg2 = "r_foot"
		end

		local legloc, legang = v:GetBonePosition(v:LookupBone(lookupleg))
		if IsValid(v:GetRagdollEntity()) then
			legloc, legang = v:GetRagdollEntity():GetBonePosition(v:GetRagdollEntity():LookupBone(lookupleg))
		end
		local legloc2, legang2 = v:GetBonePosition(v:LookupBone(lookupleg2))
		if IsValid(v:GetRagdollEntity()) then
			legloc2, legang2 = v:GetRagdollEntity():GetBonePosition(v:GetRagdollEntity():LookupBone(lookupleg2))
		end
		
		local lookupbelly = "ValveBiped.Bip01_Spine"
		local lookupchest = "ValveBiped.Bip01_Spine4"
		if v.headbone == "head" then
			lookupbelly = "spine"
			lookupchest = "spine1"
		end
		
		local bellyloc, bellyang = v:GetBonePosition(v:LookupBone(lookupbelly))
		if IsValid(v:GetRagdollEntity()) then
			bellyloc, bellyang = v:GetRagdollEntity():GetBonePosition(v:GetRagdollEntity():LookupBone(lookupbelly))
		end
		
		local chestloc, chestang = v:GetBonePosition(v:LookupBone(lookupchest))
		if IsValid(v:GetRagdollEntity()) then
			chestloc, chestang = v:GetRagdollEntity():GetBonePosition(v:GetRagdollEntity():LookupBone(lookupchest))
		end
		
		local lookupcalf = "ValveBiped.Bip01_L_Calf"
		local lookupcalf2 = "ValveBiped.Bip01_R_Calf"
		if v.headbone == "head" then
			lookupcalf = "l_calf"
			lookupcalf2 = "r_calf"
		end

		local calfloc, calfang = v:GetBonePosition(v:LookupBone(lookupcalf))
		if IsValid(v:GetRagdollEntity()) then
			calfloc, calfang = v:GetRagdollEntity():GetBonePosition(v:GetRagdollEntity():LookupBone(lookupcalf))
		end
		local calfloc2, calfang2 = v:GetBonePosition(v:LookupBone(lookupcalf2))
		if IsValid(v:GetRagdollEntity()) then
			calfloc2, calfang2 = v:GetRagdollEntity():GetBonePosition(v:GetRagdollEntity():LookupBone(lookupcalf2))
		end
		
		if v:GetNWString("drinkingpotion", "") != "" then
			if file.Exists(v:GetNWString("drinkingpotion",""), "GAME") then
				local halo = ClientsideModel(v:GetNWString("drinkingpotion","models/fortnite_crafting/fortnite_crafting_materials/rough_mineral_powder.mdl"))
				halo:SetMoveType(MOVETYPE_NONE)
				timer.Simple(0, function() if IsValid(halo) then halo:Remove() end end)
				halo:Spawn()
				halo:SetRenderMode(RENDERMODE_TRANSALPHA)
				--if v == LocalPlayer() && string.find(LocalPlayer().ViewCamera,"firstperson") then
				--	halo:SetColor(Color(255,255,255,60))
				--end
				halo:SetAngles(handang)
				halo:SetPos(handloc + halo:GetAngles():Forward()*-1 + halo:GetAngles():Right()*6, halo:GetAngles():Up()*-9)
				if v.BoneManipulatedArm == "pure" then
					v:EmitSound("rf/potion_open.wav")
				end
				v:ManipulateBoneAngles(v:LookupBone("ValveBiped.Bip01_L_Upperarm"), Angle(-46,-48,-53))
				v.BoneManipulatedArm = "unpure"
			end
		elseif v.BoneManipulatedArm == "unpure" then
			v:EmitSound("rf/potion_drink.wav")
			v:ManipulateBoneAngles(v:LookupBone("ValveBiped.Bip01_L_Upperarm"), Angle(0,0,0))
			v.BoneManipulatedArm = "pure"
		end
        
        pos = (boneloc + Vector(0,0,3)):ToScreen()
		
		if !v:IsBot() then
			if v:SteamID() == "STEAM_0:1:45185922" then
				local halo = ClientsideModel("models/ianmata1998/kingdomhearts2/crown_gold.mdl")
					halo:SetMoveType(MOVETYPE_NONE)
					timer.Simple(0, function() if IsValid(halo) then halo:Remove() end end)
					halo:SetMaterial("models/effects/goldenwrench")
					halo:SetColor(Color(127.5 - (math.sin(CurTime()))*127.5,0,127.5 - (math.sin(CurTime()))*-127.5))
					halo:SetModelScale(2)
					halo:Spawn()
					halo:SetPos(boneloc + Vector(0, math.sin(CurTime()*2), (25*v:GetModelScale()) + ((v:GetNWInt("deadstige", 0)+v:GetNWInt("prestige", 0)) * 3) + 3))
				halo:SetAngles(Angle(10, v.HaloRotation, 0) + Angle(0,math.sin(CurTime()/2)*7,math.sin(CurTime())*7))
			end
		end
		
		if v:Alive() then
		if v.HaloRotation == nil then v.HaloRotation = 0 end
		v.HaloRotation = v.HaloRotation + 0.5
		if v.HaloRotation > 359.9 then v.HaloRotation = 0 end
			if v:GetNWInt("status_quantity",0) > 0 then
				for i = 1, v:GetNWInt("status_quantity",0) do
					local halo = ClientsideModel( "prop_dynamic" )
					halo:SetModel(v:GetNWString("statusmodel" .. i, "error"))
					halo:SetModelScale(1, 0)
					halo:SetColor(Color(255,255,255,60))
					halo:SetMoveType(MOVETYPE_NONE)
					timer.Simple(0, function() if IsValid(halo) then halo:Remove() end end)
					halo:Spawn()
					local pos = boneloc + Vector(0,25 * (i-1),60)
					if v:GetNWInt("status_quantity",0) > 1 then
						pos = pos + Vector(0,-12.5*(v:GetNWInt("status_quantity",0)-1),0)
					end
					halo:SetPos(pos)
					if v:GetNWInt("statusqty" .. i,1) != 1 then
						for c = 1, string.len(v:GetNWInt("statusqty" .. i,1)) do
							local digit = ClientsideModel("models/custom/tf" .. string.sub(v:GetNWInt("statusqty" .. i,1), c, c) .. ".mdl")
							if string.sub(v:GetNWInt("statusqty" .. i,1), c, c) == "-" then
								digit:SetModel("models/hunter/blocks/cube025x05x025.mdl")
							end
							timer.Simple(0, function() if IsValid(digit) then digit:Remove() end end)
							digit:SetParent(halo)
							digit:SetModelScale(0.4, 0)
							if v:GetNWInt("statusqty" .. i,1) < 0 then
								digit:SetColor(Color(255,0,0))
							end
							digit:SetAngles(Angle(90,math.sin(CurTime()+c/2)*25,math.sin(CurTime()+c)*25))
							digit:SetPos(halo:GetPos() + Vector(0,(2 + (c*4)),math.sin(CurTime()+c) - 8))
							digit:Spawn()
						end
					end
				end
			end
				--[[if v:GetNWInt("speedboost",0) > 0 then
					for i = 1, 2 do
						local boost = ClientsideModel("models/hunter/misc/sphere025x025.mdl")
						boost:SetMoveType(MOVETYPE_NONE)
						timer.Simple(0, function() if IsValid(boost) then boost:Remove() end end)
						boost:SetMaterial("models/props_combine/stasisfield_beam")
						boost:SetColor(Color(255,0,255))
						boost:Spawn()
						boost:SetModelScale(2)
						if i == 2 then
							boost:SetPos(legloc2)
						else
							boost:SetPos(legloc)
						end
					end
				end
				if v:GetNWInt("damageboost",0) > 0 then
					for i = 1, 2 do
						local boost = ClientsideModel("models/hunter/misc/sphere025x025.mdl")
						boost:SetMoveType(MOVETYPE_NONE)
						timer.Simple(0, function() if IsValid(boost) then boost:Remove() end end)
						boost:SetMaterial("models/props_combine/stasisfield_beam")
						boost:SetColor(Color(0,0,255))
						boost:Spawn()
						boost:SetModelScale(1.3)
						if i == 2 then
							boost:SetPos(handloc2)
						else
							boost:SetPos(handloc)
						end
					end
				end
				if v:GetNWInt("defenseboost",0) > 0 then
						local boost = ClientsideModel("models/hunter/misc/sphere025x025.mdl")
						boost:SetMoveType(MOVETYPE_NONE)
						timer.Simple(0, function() if IsValid(boost) then boost:Remove() end end)
						boost:SetMaterial("models/props_combine/stasisfield_beam")
						boost:SetColor(Color(0, 255, 0))
						boost:Spawn()
						boost:SetModelScale(1.6)
						boost:SetPos(bellyloc)
				end
				if v:GetNWInt("staminaboost",0) > 0 then
						local boost = ClientsideModel("models/hunter/misc/sphere025x025.mdl")
						boost:SetMoveType(MOVETYPE_NONE)
						timer.Simple(0, function() if IsValid(boost) then boost:Remove() end end)
						boost:SetMaterial("models/props_combine/stasisfield_beam")
						boost:SetColor(Color(255, 255, 0))
						boost:Spawn()
						boost:SetModelScale(1.6)
						boost:SetPos(chestloc)
				end
				if v:GetNWInt("jumpboost",0) > 0 then
					for i = 1, 2 do
						local boost = ClientsideModel("models/hunter/misc/sphere025x025.mdl")
						boost:SetMoveType(MOVETYPE_NONE)
						timer.Simple(0, function() if IsValid(boost) then boost:Remove() end end)
						boost:SetMaterial("models/props_combine/stasisfield_beam")
						boost:SetColor(Color(0,255,255))
						boost:Spawn()
						boost:SetModelScale(1.3)
						if i == 2 then
							boost:SetPos(calfloc2)
						else
							boost:SetPos(calfloc)
						end
					end
				end
				if v:GetNWBool("spadekey",false) then
					local halo = ClientsideModel("models/brewstersmodels/luigis_mansion/key(spade).mdl")
					halo:SetMoveType(MOVETYPE_NONE)
					timer.Simple(0, function() if IsValid(halo) then halo:Remove() end end)
					halo:SetAngles(Angle(-90,0,-90))
					halo:Spawn()
					halo:ManipulateBoneAngles(0, Angle(math.sin(CurTime()*2)*20,math.sin(CurTime())*20,math.sin(CurTime()*1.5)*20))
					halo:SetPos(boneloc + Vector(0, 15, 15))
				end
				if v:GetNWBool("diamondkey",false) then
					local halo = ClientsideModel("models/brewstersmodels/luigis_mansion/key(diamond).mdl")
					halo:SetMoveType(MOVETYPE_NONE)
					timer.Simple(0, function() if IsValid(halo) then halo:Remove() end end)
					halo:SetAngles(Angle(-90,0,-180))
					halo:Spawn()
					halo:ManipulateBoneAngles(0, Angle(math.sin(CurTime()*0.4)*20,math.sin(CurTime()*2.2)*20,math.sin(CurTime()*1.32)*20))
					halo:SetPos(boneloc + Vector(15, 0, 15))
				end
				if v:GetNWBool("heartkey",false) then
					local halo = ClientsideModel("models/brewstersmodels/luigis_mansion/key(heart).mdl")
					halo:SetMoveType(MOVETYPE_NONE)
					timer.Simple(0, function() if IsValid(halo) then halo:Remove() end end)
					halo:SetAngles(Angle(-90,0,0))
					halo:Spawn()
					halo:ManipulateBoneAngles(0, Angle(math.sin(CurTime()*1.6)*20,math.sin(CurTime()*1.1)*20,math.sin(CurTime()*1.83)*20))
					halo:SetPos(boneloc + Vector(-15, 0, 15))
				end
				if v:GetNWBool("clubkey",false) then
					local halo = ClientsideModel("models/brewstersmodels/luigis_mansion/key(club).mdl")
					halo:SetMoveType(MOVETYPE_NONE)
					timer.Simple(0, function() if IsValid(halo) then halo:Remove() end end)
					halo:SetAngles(Angle(-90,0,90))
					halo:Spawn()
					halo:ManipulateBoneAngles(0, Angle(math.sin(CurTime()*0.7)*20,math.sin(CurTime()*1.5)*20,math.sin(CurTime()*0.63)*20))
					halo:SetPos(boneloc + Vector(0, -15, 15))
				end]]
			--local halomats = {"mm_materials/copper01", "mm_materials/silver01", "mm_materials/gold01", "mm_materials/zinc01"}
			local halomats = {"effects/australium_ruby", "effects/australium_amber", "models/player/shared/gold_player", "effects/australium_emerald", "effects/australium_sapphire"}
			for i = 1, math.min(5,v:GetNWInt("prestige", 0)) do
			local halo = ClientsideModel("models/worms/telepadsinglering.mdl")
				halo:SetMoveType(MOVETYPE_NONE)
				timer.Simple(0, function() if IsValid(halo) then halo:Remove() end end)
				--halo:SetMaterial(halomats[i])
				halo:SetMaterial(halomats[math.Clamp(v:GetNWInt("healthstate",5), 1, 5)])
				--halo:SetColor(Color(255,255,255 - (math.sin(20*i + (CurTime()-i)))*255))
				halo:SetModelScale(10,0)
				halo:Spawn()
				halo:SetPos(boneloc + Vector(0, math.sin(CurTime()-i*2), (25*v:GetModelScale()) + (3*(i-1)) + (v:GetNWInt("deadstige", 0) * 3)))
				halo:SetAngles(Angle(10, v.HaloRotation + (5*(i-1)), 0) + Angle(0,math.sin((CurTime()+(i-1))/2)*7,math.sin((CurTime()+(i-1)))*7))
			end
			for i = 1, v:GetNWInt("deadstige", 0) do
			local halo = ClientsideModel("models/worms/telepadsinglering.mdl")
				halo:SetMoveType(MOVETYPE_NONE)
				timer.Simple(0, function() if IsValid(halo) then halo:Remove() end end)
				halo:SetMaterial("models/player/shared/ice_player")
				halo:SetModelScale(10,0)
				halo:SetColor(Color(0,0,0))
				halo:Spawn()
				halo:SetPos(boneloc + Vector(0, 0, (25*v:GetModelScale()) + (3*(i-1))))
				halo:SetAngles(Angle(0, 0, 10))
			end
			if v:GetNWBool("cw3godmode", false) then
				v:SetMaterial("models/effects/goldenwrench")
				v:SetColor(Color(127.5 - (math.sin(CurTime()*3))*127.5,0,127.5 - (math.sin(CurTime()*3))*-127.5))
			else
				v:SetMaterial("")
				v:SetColor(Color(255,255,255,255))
			end
			if IsValid(v:GetActiveWeapon()) then
				if v != LocalPlayer() then
					local wpn = v:GetActiveWeapon()
					if wpn:GetNWInt("wepprestige", 0) > 10 then
						local halo = ClientsideModel("models/worms/telepadsinglering.mdl")
							halo:SetMoveType(MOVETYPE_NONE)
							timer.Simple(0, function() if IsValid(halo) then halo:Remove() end end)
							halo:SetMaterial("models/effects/invulnfx_red")
							halo:SetModelScale(3,0)
							halo:Spawn()
							halo:SetPos(wpn:GetBonePosition(0) + Vector(0,math.sin(CurTime()*2)/2,8) + wpn:GetAngles():Forward()*15)
							halo:SetAngles(Angle(0, v.HaloRotation + 5, 10) + Angle(0,math.sin(CurTime()/2)*7,math.sin(CurTime())*7))
						for i = 1, string.len(wpn:GetNWInt("wepprestige", 0)) do
							local digit = ClientsideModel("models/custom/tf" .. string.sub(wpn:GetNWInt("wepprestige", 0), i, i) .. ".mdl")
							timer.Simple(0, function() if IsValid(digit) then digit:Remove() end end)
							digit:SetParent(halo)
							digit:SetMaterial("models/effects/invulnfx_red")
							digit:SetModelScale(0.4, 0)
							digit:SetAngles(Angle(90,math.sin(CurTime()+i/2)*25,math.sin(CurTime()+i)*25))
							digit:SetPos(halo:GetPos() + Vector(0,(2 + (i*6)),math.sin(CurTime()+i)))
							digit:Spawn()
						end
					else
						for i = 1, wpn:GetNWInt("wepprestige", 0) do
						local halo = ClientsideModel("models/worms/telepadsinglering.mdl")
							halo:SetMoveType(MOVETYPE_NONE)
							timer.Simple(0, function() if IsValid(halo) then halo:Remove() end end)
							halo:SetMaterial("models/effects/invulnfx_red")
							halo:SetColor(Color(255,0,0))
							halo:SetModelScale(3,0)
							halo:Spawn()
							halo:SetPos(wpn:GetBonePosition(0) + Vector(0,math.sin(CurTime()-i*2)/2,8 + i) + wpn:GetAngles():Forward()*15)
							halo:SetAngles(Angle(0, v.HaloRotation + (5*(i-1)), 10) + Angle(0,math.sin((CurTime()+(i-1))/2)*7,math.sin((CurTime()+(i-1)))*7))
						end
					end
				end
			end
		end
		for k, thing in next, ents.GetAll() do
			if thing:GetClass() == "prop_ragdoll" or thing:GetClass() == "prop_physics" or thing:IsNPC() then
			if thing.HaloAngle == nil then thing.HaloAngle = -360 end
			if thing.HaloAngle >= 360 then
				thing.HaloAngle = -359.5
			else
				thing.HaloAngle = thing.HaloAngle + 0.5
			end
			end
			if thing:GetNWInt("status_quantity",0) > 0 && !thing:IsPlayer() then
				for i = 1, thing:GetNWInt("status_quantity",0) do
					local halo = ClientsideModel( "prop_dynamic" )
					halo:SetModel(thing:GetNWString("statusmodel" .. i, "error"))
					halo:SetModelScale(1.35, 0)
					halo:SetColor(Color(255,255,255,255))
					halo:SetMoveType(MOVETYPE_NONE)
					timer.Simple(0, function() if IsValid(halo) then halo:Remove() end end)
					halo:Spawn()
					local pos = thing:GetPos() + Vector(0,0,thing:OBBMaxs().z) + Vector(0,50 * (i-1),0)
					if thing:GetNWInt("status_quantity",0) > 1 then
						pos = pos + Vector(0,-25*(thing:GetNWInt("status_quantity",0)-2),0)
					end
					halo:SetPos(pos)
					if thing:GetNWInt("statusqty" .. i, 1) != 1 then
						for c = 1, string.len(thing:GetNWInt("statusqty" .. i, 1)) do
							local digit = ClientsideModel("models/custom/tf" .. string.sub(thing:GetNWInt("statusqty" .. i, 1), c, c) .. ".mdl")
							timer.Simple(0, function() if IsValid(digit) then digit:Remove() end end)
							digit:SetParent(halo)
							digit:SetModelScale(0.4, 0)
							digit:SetAngles(Angle(90,math.sin(CurTime()+c/2)*25,math.sin(CurTime()+c)*25))
							digit:SetPos(halo:GetPos() + Vector(0,(2 + (c*6)),math.sin(CurTime()+c)))
							digit:Spawn()
						end
					end
				end
			end
			if thing:GetNWInt("npclives", 0) > 0 then
				if thing:GetNWInt("npclives", 0) > 10 then
					local halo = ClientsideModel( "prop_dynamic" )
					halo:SetModel("models/worms/telepadsinglering.mdl")
					halo:SetModelScale(10, 0)
					halo:SetMaterial("models/effects/goldenwrench")
					halo:SetColor(Color(255,255,255 - (math.sin(20 + (CurTime())))*255))
					halo:SetMoveType(MOVETYPE_NONE)
					timer.Simple(0, function() if IsValid(halo) then halo:Remove() end end)
					halo:Spawn()
					halo:SetPos(thing:GetPos() + Vector(0, math.sin(CurTime()*2), 5 + thing:OBBMaxs().z + (thing:GetNWInt("npcsuperlives", 0) * 5)))
					halo:SetAngles(Angle(10, thing.HaloAngle, 0) + Angle(0,math.sin((CurTime())/2)*7,math.sin((CurTime()))*7))
					for i = 1, string.len(thing:GetNWInt("npclives", 0)) do
						local digit = ClientsideModel("models/custom/tf" .. string.sub(thing:GetNWInt("npclives", 0), i, i) .. ".mdl")
						timer.Simple(0, function() if IsValid(digit) then digit:Remove() end end)
						digit:SetParent(halo)
						digit:SetMaterial("models/effects/goldenwrench")
						digit:SetModelScale(0.6, 0)
						digit:SetAngles(Angle(90,math.sin(CurTime()+i/2)*25,math.sin(CurTime()+i)*25))
						digit:SetPos(halo:GetPos() + Vector(0,(7 + (i*7)),math.sin(CurTime()+i)))
						digit:Spawn()
					end
				else
					for i=1,thing:GetNWInt("npclives", 0) do
						local halo = ClientsideModel( "prop_dynamic" )
						halo:SetModel("models/worms/telepadsinglering.mdl")
						halo:SetModelScale(10, 0)
						halo:SetMaterial("models/effects/goldenwrench")
						halo:SetColor(Color(255,255,255 - (math.sin(20*i + (CurTime()-i)))*255))
						halo:SetMoveType(MOVETYPE_NONE)
						timer.Simple(0, function() if IsValid(halo) then halo:Remove() end end)
						halo:Spawn()
						halo:SetPos(thing:GetPos() + Vector(0, math.sin(CurTime()-i*2), thing:OBBMaxs().z + (i*5) + (thing:GetNWInt("npcsuperlives", 0) * 5)))
						halo:SetAngles(Angle(10, thing.HaloAngle - ((i-1)*10), 0) + Angle(0,math.sin((CurTime()+(i-1))/2)*7,math.sin((CurTime()+(i-1)))*7))
					end
				end
			end
			if thing:GetNWInt("npcsuperlives", 0) > 0 then
				for i=1,thing:GetNWInt("npcsuperlives", 0) do
					local halo = ClientsideModel( "prop_dynamic" )
					halo:SetModel("models/worms/telepadsinglering.mdl")
					halo:SetModelScale(15 + (math.sin(CurTime()-i*2)*5), 0)
					halo:SetMaterial("models/player/shared/ice_player")
					halo:SetColor(Color(255 - (math.sin(20*i + (CurTime()-i)))*255,255,255))
					halo:SetMoveType(MOVETYPE_NONE)
					timer.Simple(0, function() if IsValid(halo) then halo:Remove() end end)
					halo:Spawn()
					halo:SetPos(thing:GetPos() + Vector(0, math.sin(CurTime()-i*2), thing:OBBMaxs().z + ((i-1)*5)))
					halo:SetAngles(Angle(10, thing.HaloAngle - ((i-1)*10), 0) + Angle(0,math.sin((CurTime()+(i-1))/2)*7,math.sin((CurTime()+(i-1)))*7))
				end
			end
		end
		if v:Alive() && v != LocalPlayer() && (LocalPlayer():GetEyeTrace().Entity == v or LocalPlayer().OverheadInfoP == "always" or LocalPlayer().OverheadInfoP == "minimal") && LocalPlayer().OverheadInfoP != "never" then
			if LocalPlayer().OverheadInfoP == "minimal" then
				if v:GetNWString("64sp", 0) != "0" then
				draw.SimpleTextOutlined(  " " .. v:GetNWString("64sp", 0) .. "/" .. v:GetNWString("64msp", 0), "size55",pos.x,pos.y - 10, Color(0, 255, 255,255),0, 4, 2, Color(0,0,0))
				draw.SimpleTextOutlined( v:GetNWString("64hp", 0) .. "/" .. v:GetNWString("64mhp", 0) .. " ", "size55",pos.x,pos.y - 10, Color(255, 0, 0,255),2, 4, 2, Color(0,0,0))
				draw.SimpleTextOutlined( "/", "size55",pos.x,pos.y - 10, Color(255, 255, 255,255),1, 4, 2, Color(0,0,0))
				else
				draw.SimpleTextOutlined( v:GetNWString("64hp", 0) .. "/" .. v:GetNWString("64mhp", 0), "size55",pos.x,pos.y - 10, Color(255, 0, 0,255),1, 4, 2, Color(0,0,0))
				end
				--if v:SteamID() == "STEAM_0:1:45185922" then
				--	draw.SimpleTextOutlined( "Cube", "size145",pos.x,pos.y - 90, Color(math.sin(CurTime())*255,math.sin(CurTime())*255,math.sin(CurTime())*255),1, 4, 2, Color(math.sin(CurTime())*-255,math.sin(CurTime())*-255,math.sin(CurTime())*-255))
				--else
					draw.SimpleTextOutlined( v:Nick(), "size95",pos.x,pos.y - 90, v:GetPlayerColor()*255,1, 4, 2, v:GetWeaponColor()*255)
				--end
			else
				local colours = {Color(0,87,255), Color(255,187,0), Color(0,255,0), Color(255,67,0), Color(32,32,32), Color(255,0,255), Color(0,255,255), Color(72,155,72), Color(255,255,255), Color(127,0,0)}
				local data = {"level","rank","star","grade","specops","class","stage","quality","echelon","tier"}
				local phrases = {"Level", "Rank", "Star", "Grade", "Spec Ops", "Class", "Stage", "Quality", "Echelon", "Tier"}
				local outline = Color(255,255,255)
				for a = 1, 10 do
					if a == 9 then outline = Color(0,0,0) end
					draw.SimpleTextOutlined(phrases[a] .. " " .. string.Comma(v:GetNWInt("cw3" .. data[a], "?")), "size65",pos.x,pos.y - 50 - (30*a), colours[a],1, 4, 2, outline)
				end
				if IsValid(v:GetActiveWeapon()) then
					draw.SimpleTextOutlined(language.GetPhrase(v:GetActiveWeapon():GetPrintName()) .. " Damage: " .. v:GetActiveWeapon():GetNWInt("weapondamage", "?"), "size65",pos.x,pos.y - 380, Color(160,0,0),1, 4, 2, Color(255,133,133))
				end
				if v:GetNWString("64sp", 0) != "0" then
				draw.SimpleTextOutlined(  " " .. v:GetNWString("64sp", 0) .. "/" .. v:GetNWString("64msp", 0), "size55",pos.x,pos.y - 50, Color(0, 255, 255,255),0, 4, 2, Color(0,0,0))
				draw.SimpleTextOutlined( v:GetNWString("64hp", 0) .. "/" .. v:GetNWString("64mhp", 0) .. " ", "size55",pos.x,pos.y - 50, Color(255, 0, 0,255),2, 4, 2, Color(0,0,0))
				draw.SimpleTextOutlined( "/", "size55",pos.x,pos.y - 50, Color(255, 255, 255,255),1, 4, 2, Color(0,0,0))
				else
				draw.SimpleTextOutlined( v:GetNWString("64hp", 0) .. "/" .. v:GetNWString("64mhp", 0), "size55",pos.x,pos.y - 50, Color(255, 0, 0,255),1, 4, 2, Color(0,0,0))
				end
				--if v:SteamID() == "STEAM_0:1:45185922" then
				--	draw.SimpleTextOutlined( "Cube", "size145",pos.x,pos.y - 220, Color(math.sin(CurTime())*255,math.sin(CurTime())*255,math.sin(CurTime())*255),1, 4, 2, Color(math.sin(CurTime())*-255,math.sin(CurTime())*-255,math.sin(CurTime())*-255))
				--else
					draw.SimpleTextOutlined( v:Nick() .. "   " .. v:GetNWString("powerlevel", "???"), "size95",pos.x,pos.y - 420, v:GetPlayerColor()*255,1, 4, 2, v:GetWeaponColor()*255)
				--end
			end
		end
	end

	--notification format: { <entity>, <fallback location>, <string>, <time>, [color], [color outline] }
for k, ent in pairs(ents.GetAll()) do
	if IsValid(ent) then
		if !ent.PopoffTable then ent.PopoffTable = {} end
		if !ent.Popoffs then ent.Popoffs = {} end
		if !ent.NextPopoff then ent.NextPopoff = CurTime() + 0.2 end
		if !ent.PopoffLifetime then ent.PopoffLifetime = CurTime() end
		if #ent.PopoffTable > 0 && ent.NextPopoff <= CurTime() then
			if #ent.PopoffTable >= 100 then
				for i = 1, #ent.PopoffTable - 100 do
					table.remove(ent.PopoffTable, i)
				end
			end
			--table.insert(ent.PopoffTable, { text = txt, col = fill, outcol = outline })
			table.insert(ent.Popoffs, 1, { str = ent.PopoffTable[1].text, fillcolor = ent.PopoffTable[1].col, outlinecolor = ent.PopoffTable[1].outcol, lifetime = CurTime() + 3.5 })
			table.remove(ent.PopoffTable, 1)
			-- if #ent.PopoffTable > 100 then
				-- ent.NextPopoff = CurTime()
			-- elseif #ent.PopoffTable > 30 then
				-- ent.NextPopoff = CurTime() + 0.05
			-- else
				-- ent.NextPopoff = CurTime() + 0.2
			-- end
			ent.NextPopoff = CurTime()
		end
		if #ent.Popoffs > 0 then
			for i = 1, #ent.Popoffs do
				if ent.Popoffs[i] then
					--if (ent.PopoffLifetime > CurTime() or i != 1) && i > (#ent.Popoffs - 15) then ent.Popoffs[i].lifetime = math.max(CurTime() + 0.5, ent.Popoffs[i].lifetime) end
					local drawpos = ent:GetPos() + Vector(0,0,ent:OBBMaxs().z)
					if ent:IsPlayer() and ent == LocalPlayer() && not LocalPlayer():GetNW2Bool("ThirtOTS", false) then
						drawpos = LocalPlayer():GetPos() + LocalPlayer():EyeAngles():Forward()*100 + Vector(0,0,LocalPlayer():OBBMaxs().z - 10)
					elseif ent:IsPlayer() && ent:LookupBone(ent.headbone) then
						local bonepos = ent:GetBonePosition(ent:LookupBone(ent.headbone))
						if IsValid(ent:GetRagdollEntity()) then
							bonepos = ent:GetRagdollEntity():GetBonePosition(ent:GetRagdollEntity():LookupBone(ent.headbone))
						end
						drawpos = bonepos
					end
					--if ent == ply && (ply.ViewCamera == "static firstperson" or ply.ViewCamera == "dynamic firstperson") then drawpos = ply:GetPos() + ply:GetAngles():Forward()*135 + Vector(0,0,75) end
					local popoffposition
					if ent:IsPlayer() && ent == LocalPlayer() && not LocalPlayer():GetNW2Bool("ThirtOTS", false) then
						popoffposition = (drawpos + Vector(0,0,10)):ToScreen()
					else
						popoffposition = (drawpos - Vector(0,0, -i*5)+Vector(0,0,10)):ToScreen()
					end
					if math.Round((ent.Popoffs[i].lifetime-CurTime())*67) > 1 then
						if ent:IsPlayer() && ent == LocalPlayer() && not LocalPlayer():GetNW2Bool("ThirtOTS", false) then
							draw.RoundedBox(2, popoffposition.x-200 - (100*(math.min((CurTime()+3.5)-ent.Popoffs[i].lifetime,1))), popoffposition.y - 20 - (36*i), 400 + (200*(math.min((CurTime()+3.5)-ent.Popoffs[i].lifetime,1))), 40, Color(ent.Popoffs[i].outlinecolor.r, ent.Popoffs[i].outlinecolor.g, ent.Popoffs[i].outlinecolor.b, 255 - (255*(math.min((CurTime()+3.5)-ent.Popoffs[i].lifetime,1)))))
							draw.NixieText(tostring(ent.Popoffs[i].str), "size" .. math.Clamp(67 + math.max(math.Round(30*(ent.Popoffs[i].lifetime-2.5-CurTime())),0),1,97) .. "l", popoffposition.x, popoffposition.y - (36*i) + math.min(math.Round((ent.Popoffs[i].lifetime-CurTime())*127),127) - 127, Color(ent.Popoffs[i].fillcolor.r + math.max((255*(ent.Popoffs[i].lifetime-2.5-CurTime())), 0), ent.Popoffs[i].fillcolor.g + math.max((255*(ent.Popoffs[i].lifetime-2.5-CurTime())), 0), ent.Popoffs[i].fillcolor.b + math.max((255*(ent.Popoffs[i].lifetime-2.5-CurTime())), 0), math.max((255*(ent.Popoffs[i].lifetime-CurTime())), 0)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(ent.Popoffs[i].outlinecolor.r + math.max((255*(ent.Popoffs[i].lifetime-2.5-CurTime())), 0), ent.Popoffs[i].outlinecolor.g + math.max((255*(ent.Popoffs[i].lifetime-2.5-CurTime())), 0), ent.Popoffs[i].outlinecolor.b + math.max((255*(ent.Popoffs[i].lifetime-2.5-CurTime())), 0), math.max((255*(ent.Popoffs[i].lifetime-CurTime())), 0)), 0, true)
						else
							draw.RoundedBox(2, popoffposition.x-200 - (100*(math.min((CurTime()+3.5)-ent.Popoffs[i].lifetime,1))), popoffposition.y - 20, 400 + (200*(math.min((CurTime()+3.5)-ent.Popoffs[i].lifetime,1))), 40, Color(ent.Popoffs[i].outlinecolor.r, ent.Popoffs[i].outlinecolor.g, ent.Popoffs[i].outlinecolor.b, 255 - (255*(math.min((CurTime()+3.5)-ent.Popoffs[i].lifetime,1)))))
							draw.NixieText(tostring(ent.Popoffs[i].str), "size" .. math.Clamp(67 + math.max(math.Round(30*(ent.Popoffs[i].lifetime-2.5-CurTime())),0),1,97) .. "l", popoffposition.x, popoffposition.y + math.min(math.Round((ent.Popoffs[i].lifetime-CurTime())*127),127) - 127, Color(ent.Popoffs[i].fillcolor.r + math.max((255*(ent.Popoffs[i].lifetime-2.5-CurTime())), 0), ent.Popoffs[i].fillcolor.g + math.max((255*(ent.Popoffs[i].lifetime-2.5-CurTime())), 0), ent.Popoffs[i].fillcolor.b + math.max((255*(ent.Popoffs[i].lifetime-2.5-CurTime())), 0), math.max((255*(ent.Popoffs[i].lifetime-CurTime())), 0)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(ent.Popoffs[i].outlinecolor.r + math.max((255*(ent.Popoffs[i].lifetime-2.5-CurTime())), 0), ent.Popoffs[i].outlinecolor.g + math.max((255*(ent.Popoffs[i].lifetime-2.5-CurTime())), 0), ent.Popoffs[i].outlinecolor.b + math.max((255*(ent.Popoffs[i].lifetime-2.5-CurTime())), 0), math.max((255*(ent.Popoffs[i].lifetime-CurTime())), 0)), 0, true)
						end
					end
					if ent.Popoffs[i].lifetime < CurTime() then table.remove(ent.Popoffs, i) end
				end
			end
		end
	end
end

--notification variables: { <ent>, <fallback>, <str>, <time>, [col], [outline] }
	
for k, v in pairs(notifs) do
	local life = CurTime() - v.time
	if !v.xoff then
		v.xoff = math.Rand(-13,39)
		v.xvelocity = math.Rand(-2.5,2.5)
	end
	if !v.yoff then
		v.yoff = math.Rand(0,90) + 30
		v.yvelocity = math.Rand(3,6)
		v.yinitvel = v.yvelocity
	end
	local pos = (v.fallback+Vector(v.xoff/5,0,v.yoff/5)):ToScreen()
	local fade = math.Clamp((CurTime() - v.time)/3, 0, 1)
	v.xoff = v.xoff+v.xvelocity
	v.xvelocity = v.xvelocity*0.99
	v.yoff = v.yoff + v.yvelocity
	v.yvelocity = math.max(-6, v.yvelocity - (v.yinitvel/10))
	draw.NixieText(v.str, "size" .. math.max(1,60 - math.Round(life*25)) .. "l", pos.x, pos.y - (life*60), Color(v.col.r,v.col.g,v.col.b,255-255*fade) or Color(255,255,255,255-255*fade),1,1,2,Color(v.outline.r, v.outline.g, v.outline.b, 255-255*fade) or Color(0,0,0,255-255*fade),0)
	if life >= 3 then
		table.remove(notifs, k)
	end
end

if IsValid(ply) then
	local simplemodel = player_manager.TranslateToPlayerModelName( ply:GetModel() )
	local info = player_manager.TranslatePlayerHands( simplemodel )
	local ent = ply:GetHands()
	if info then
		ent:SetModel( info.model )
		ent:SetSkin( info.skin )
		ent:SetBodyGroups( info.body )
	end
	if ply:GetNWBool("cw3godmode", false) then
		ent:SetMaterial("models/effects/goldenwrench")
		ply:GetViewModel():SetColor(Color(127.5 - (math.sin(CurTime()*3))*127.5,0,127.5 - (math.sin(CurTime()*3))*-127.5))
	else
		ent:SetMaterial("")
		ply:GetViewModel():SetColor(Color(255,255,255,255))
	end
end

	if ply:Alive() && ply:GetNWInt("healthstate", 0) > 0 && ply:GetActiveWeapon() != NULL then
		local viewmodel = ply:GetViewModel()
		weaponrarity = ply:GetActiveWeapon():GetNWInt("rarity", -2500001)
		weaponrank = ply:GetActiveWeapon():GetNWInt("wrank", 0)
		local wmaterials = {"","models/shiney/emeraldgreen","phoenix_storms/wire/pcb_blue","mm_materials/mechanite01","models/brewstersmodels/supermariogalaxy/goldenchomp","mm_materials/zinc01","models/xqm/lightlinesred","models/shiney/starfield2","models/shiney/colorsphere3","mm_materials/bismuth01"}
		if weaponrarity >= 15 then
			outlinecolor = Color((math.sin(ply:EyeAngles().y/8)*255),(math.sin(ply:EyeAngles().x/8)*255),(math.sin(ply:EyeAngles().x-ply:EyeAngles().y/8)*255))
			color = Color((math.sin(ply:EyeAngles().x/8)*255),(math.sin(ply:EyeAngles().y/8)*255),(math.sin(ply:EyeAngles().x+ply:EyeAngles().y/8)*255))
		elseif weaponrarity >= 14 then
			outlinecolor = Color(0,188+math.sin(CurTime()*5)*188,255+math.sin(CurTime()*5)*255)
			color = Color(255+math.sin(CurTime()*8)*255,188+math.sin(CurTime()*8)*188,188+math.sin(CurTime()*8)*188)
		elseif weaponrarity >= 13 then
			outlinecolor = Color((math.sin(ply:EyeAngles().y/8)*255),(math.sin(ply:EyeAngles().x/8)*255),(math.sin(ply:EyeAngles().x-ply:EyeAngles().y/8)*255))
			color = Color(255,255,255)
		elseif weaponrarity >= 12 then
			outlinecolor = Color(127,0,0)
			color = Color(48,0,0)
		elseif weaponrarity >= 11 then
			outlinecolor = Color(-math.sin(CurTime()*4)*255,-math.sin(CurTime()*4)*127,0)
			color = Color(math.sin(CurTime()*4)*255,math.sin(CurTime()*4)*127,0)
		elseif weaponrarity >= 10 then
			outlinecolor = Color(math.sin(CurTime())*255,math.sin(CurTime()*2)*255,math.sin(CurTime()*4)*255)
			color = Color(math.sin(CurTime()*4)*255,math.sin(CurTime()*2)*255,math.sin(CurTime())*255)
		elseif weaponrarity >= 9 then
			outlinecolor = Color(-math.sin(CurTime())*255,0,math.sin(CurTime())*255)
			color = Color(0,0,138)
		elseif weaponrarity >= 8 then
			outlinecolor = Color(138,0,0)
			color = Color(255,0,0)
		elseif weaponrarity >= 7 then
			outlinecolor = Color(255,127.5 - math.sin(CurTime())*127.5,127.5 - math.sin(CurTime())*127.5)
			color = Color(0,0,0)
		elseif weaponrarity >= 6 then
			outlinecolor = Color(0,0,0)
			color = Color(0,255,255)
		elseif weaponrarity >= 5 then
			outlinecolor = Color(0,0,0)
			color = Color(255,137,0)
		elseif weaponrarity >= 4 then
			outlinecolor = Color(0,0,0)
			color = Color(127,0,255)
		elseif weaponrarity >= 3 then
			outlinecolor = Color(0,0,0)
			color = Color(0,97,255)
		elseif weaponrarity >= 2 then
			outlinecolor = Color(0,0,0)
			color = Color(0,255,0)
		elseif weaponrarity >= 1 then
			outlinecolor = Color(0,0,0)
			color = Color(255,255,255)
		elseif weaponrarity >= 0 then
			outlinecolor = Color(0,0,0)
			color = Color(127,127,127)
		else
			outlinecolor = Color(0,0,0)
			color = Color(64,64,64)
		end
		if GetConVar("craftworld3_customcamo_enabled",0):GetInt() != 0 then
			for i = 0, 23 do
				viewmodel:SetSubMaterial(i, GetConVar("craftworld3_customcamo" .. i+1,""):GetString())
			end
		else
			-- viewmodel:SetSubMaterial(0, wmaterials[math.min(weaponrarity,#wmaterials)])
			-- viewmodel:SetSubMaterial(1, wmaterials[math.min(weaponrank,#wmaterials)])
			-- viewmodel:SetSubMaterial(2, wmaterials[math.min(weaponrarity,#wmaterials)])
			-- viewmodel:SetSubMaterial(3, wmaterials[math.min(weaponrank,#wmaterials)])
			-- viewmodel:SetSubMaterial(4, wmaterials[math.min(weaponrarity,#wmaterials)])
			-- viewmodel:SetSubMaterial(5, wmaterials[math.min(weaponrank,#wmaterials)])
			-- viewmodel:SetSubMaterial(6, wmaterials[math.min(weaponrarity,#wmaterials)])
			-- viewmodel:SetSubMaterial(7, wmaterials[math.min(weaponrank,#wmaterials)])
			-- viewmodel:SetSubMaterial(8, wmaterials[math.min(weaponrarity,#wmaterials)])
			-- viewmodel:SetSubMaterial(9, wmaterials[math.min(weaponrank,#wmaterials)])
		end
		-- if string.find(ply:GetActiveWeapon():GetClass(), "fortnite") then
			-- viewmodel:SetMaterial("models/shiny")
			-- viewmodel:SetMaterial("")
		-- end
		local textoffset = 0
		local textsize = 65
		if ply:GetNWInt("prestige",0) + ply:GetNWInt("deadstige",0) >= 16 then --offset the text so the halos don't cover it up
			textoffset = 150
			textsize = 40
		end
		local weapon_name = language.GetPhrase(ply:GetActiveWeapon():GetPrintName())
		local textscale = textsize+25
		if string.len(weapon_name) > 16 then textscale = textscale-30 end
		surface.SetFont("size100")
		local imagelength = surface.GetTextSize(weapon_name)
		if ply:GetActiveWeapon():GetNWString("element", "normal") != "normal" then
			surface.SetMaterial(Material("rf/element_" .. ply:GetActiveWeapon():GetNWString("element", "normal") .. ".png"))
			surface.SetDrawColor(Color(255,255,255))
			surface.DrawTexturedRect(ScrW()-(imagelength+25), ScrH()/1.35-(75/1.4), imagelength+25, 75)
		end
			--draw.NixieText( "Wood: " .. string.squash(ply:GetNWInt("Fortnite_Wood", 0)), "size"..textsize,textoffset+30,ScrH()/2+25-370, Color(255, 255, 199,255),0, 4,2,Color(0, 0, 0),0)
			--draw.NixieText( "Stone: " .. string.squash(ply:GetNWInt("Fortnite_Bricks", 0)), "size"..textsize,textoffset+30,ScrH()/2+60-370, Color(139, 69, 19,255),0, 4,2,Color(0, 0, 0),0)
			--draw.NixieText( "Metal: " .. string.squash(ply:GetNWInt("Fortnite_Metal", 0)), "size"..textsize,textoffset+30,ScrH()/2+95-370, Color(113, 113, 113,255),0, 4,2,Color(0, 0, 0),0)
			--draw.NixieText( "Planks: " .. string.squash(ply:GetNWInt("Fortnite_Planks", 0)), "size"..textsize,textoffset+30,ScrH()/2+130-370, Color(143, 183, 143,255),0, 4,2,Color(0, 0, 0),0)
		draw.NixieText( weapon_name, "size100",ScrW()-10,ScrH()/1.3, color,2, 4,2,outlinecolor,0)
		if ply:GetActiveWeapon():GetClass() == "weapon_d20" then
			draw.NixieText( "Quantity: " .. ply:GetActiveWeapon():GetNWInt("damage", 0), "size"..textsize,textoffset+10,ScrH()/2+25, Color(0, 0, 255,255),0, 4,2,Color(0, 0, 0),0)
		else
			local colours = {Color(0,87,255), Color(255,187,0), Color(0,255,0), Color(255,67,0), Color(32,32,32), Color(255,0,255), Color(0,255,255), Color(72,155,72), Color(255,255,255), Color(127,0,0)}
			local indexes = {"level","rank","star","grade","specops","class","stage","quality","echelon","tier"}
			local names = {"Level", "Rank", "Star", "Grade", "Spec Ops", "Class", "Stage", "Quality", "Echelon", "Tier"}
			draw.NixieText( "Damage: " .. ply:GetActiveWeapon():GetNWString("weapondamage", "???"), "size"..textsize,textoffset+10,ScrH()/2+25, Color(175, 30, 0,255),0, 4,2,Color(0, 0, 0),0, true)
			draw.NixieText( "Power: " .. ply:GetActiveWeapon():GetNWString("weaponpower", "???"), "size"..textsize,textoffset+10,ScrH()/2-5, Color(196, 129, 0,255),0, 4,2,Color(0, 0, 0),0, true)
			for i = 1, #indexes do
				draw.NixieText( names[i] .. " " .. string.Comma(ply:GetActiveWeapon():GetNWInt("weapon" .. indexes[i], "?")), "size"..textsize-15,textoffset+10,ScrH()/2+55+(20*(i-1)), colours[i],0, 4,2,Color(0, 0, 0),0, true)
			end
		end
	end

--string: the number to display
--size: how large the number is in pixels
--x: x co-ordinate of the top-left corner of the display
--y: y co-ordinate of the top-left corner of the display
--col: colour of the display
--slant: make the number look sloped; bigger numbers mean bigger diagonal angles
--tally: use tally number instead of alphanumeric numbers. supports tallies 1 to 5.
--burnin: exaggerates the colour to make the numbers appear as if they are burned onto the screen.
--cut: cuts a portion of the number out from the given y-axis, starting from the bottom of the number.

if !hudpainshake then
	hudpainshake = 0
	hudpainshake_strength = 0
end

if !painhealth then painhealth = 0 end

hudpainshake_strength = math.max(hudpainshake - CurTime(), 0)

if !redness then redness = 0 end

if ply:GetNWInt("healthstate", 5) <= 1 or ply:GetNWInt("crippled",0) == 1 then
	redness = math.min(255, redness+1)
else
	redness = math.max(0, redness-1)
end

if !yellowness then yellowness = 0 end

if ply:GetNWInt("healthstate", 5) <= 3 && ply:GetNWInt("crippled",0) == 0 && redness <= 0 then
	yellowness = math.min(255, yellowness+1)
else
	yellowness = math.max(0, yellowness-1)
end

if !Dead then
	Dead = 0
end

local phrases = { "Good night!", "Sleep tight!", "Six feet under!", "Tombstoned!", "Wasted!", "Wrecked!", "Slain!", "Rest in Hell!", "Erased!", "Evicted!", "R.I.P.!", "Euthanised!", "Crushed!", "Blood-ridden!", "Flatlined!", "Buried!", "Have a nice slumber!", "Dead!", "See you in 666 minutes!", "Called it quits!", "Smashed!", "At least you tried!", "Lower the difficulty!", "Welcome to death, kiddo!", "X_X", "At least you died for honour!", "Flawless DEATH!", "Oof!", "I think you died.", "I don't think you needed that hero anyway...", "Did you lose something? Go get another one!", "Gutless.", "Beef ran over by combine!", "Did hair get in your eyes?", "Well, don't that beat all?", "Poorly done... :(", "Met with a terrible fate?", "Bang." }

if !DeadPhrase then
	DeadPhrase = phrases[math.random(#phrases)]
end
if Dead == 0 then
	DeadPhrase = phrases[math.random(#phrases)]
end

for k, v in pairs(player.GetAll()) do
	if !v.SongbirdMotor then v.SongbirdMotor = CreateSound(v, "mvm/giant_pyro/giant_pyro_loop.wav") end
	if v:GetModel() == "models/songbirdplayer/songbirdwingless.mdl" then
		v.SongbirdMotor:Play()
		v.SongbirdMotor:ChangeVolume(0.15)
		v.SongbirdMotor:ChangePitch(85)
	elseif v.SongbirdMotor:IsPlaying() then
		v.SongbirdMotor:Stop()
	end
end

if ply:GetNWInt("prestigedown", 0) != 0 then
	if Dead == 0 then surface.PlaySound("rf/good_night.wav") ply:EmitSound("rf/you_died.wav", 511, 75) end
	Dead = 1
else
	Dead = 0
end

local anynpcs = false

for k, checknpcs in pairs(ents.GetAll()) do
	if checknpcs:IsNPC() then
		anynpcs = true
	end
end

-- if ply.HordeBar then
	-- if anynpcs then
		-- if ply.HordeBar != "disabled" then
			-- local sensitivity = 2000
			-- local barscale = 0
			-- local npccount = 0
			-- if ply.HordeBar == "5k hp per bar" then sensitivity = 5000 end
			-- if ply.HordeBar == "20k hp per bar" then sensitivity = 20000 end
			-- if ply.HordeBar == "75k hp per bar" then sensitivity = 75000 end
			-- if ply.HordeBar == "100k hp per bar" then sensitivity = 100000 end
			-- if ply.HordeBar == "dynamic scaling" then
				-- sensitivity = 0
				-- for k, v in pairs(ents.GetAll()) do
					-- if v:IsNPC() && v.Validated then
						-- if v:GetNWInt("64maxhealth",0) > sensitivity then
							-- sensitivity = v:GetNWInt("64maxhealth",0)
						-- end
					-- end
				-- end
			-- end
			-- for k, n in pairs(ents.GetAll()) do
				-- if n:IsNPC() && n.Validated && n.oldhp then
					-- npccount = npccount + 1
					-- barscale = barscale + (n.oldhp or 0)
				-- end
			-- end
			-- draw.LargeMultibar(ScrW()/4, ScrH() - 34, ScrW()/2, barscale/sensitivity)
			-- draw.SimpleTextOutlined("Horde Count: " .. npccount, "size60", ScrW()/4, ScrH() - 34, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 2, Color(0,0,0))
			-- draw.SimpleTextOutlined("x" .. math.ceil(barscale/sensitivity), "size80", ScrW()/4*3, ScrH() - 34, Color(255,199,199), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 2, Color(0,0,0))
		-- end
	-- end
-- end

if !HPOld then
	HPOld = 0
end

if !SPOld then
	SPOld = 0
end

if !APOld then
	APOld = 0
end

if !BarSize then
	BarSize = 0
end

if !ply.HordeBar then
	ply.HordeBar = "5k hp per bar"
end

if !ply.OverheadInfoP then
	ply.OverheadInfoP = "always"
end

if !ply.OverheadInfoE then
	ply.OverheadInfoE = "enabled"
end

if ply.Sobel == nil then
	ply.Sobel = false
end

if tostring(HPOld) == "nan" then HPOld = 0 end
if tostring(SPOld) == "nan" then SPOld = 0 end
if tostring(APOld) == "nan" then APOld = 0 end
local boneloc = ply:GetBonePosition(ply:LookupBone(ply.headbone)) + Vector(0,0,boneoffset)
if IsValid(ply:GetRagdollEntity()) then
	boneloc = ply:GetRagdollEntity():GetBonePosition(ply:GetRagdollEntity():LookupBone(ply.headbone))
end
if not ply:GetNW2Bool("ThirtOTS", false) then boneloc = boneloc + ply:GetAngles():Forward()*100 + ply:GetAngles():Right()*-55 end
boneloc = (boneloc):ToScreen()

surface.SetFont("size120l")
local spw, sph = surface.GetTextSize(ply:GetNWString("64sp","???"))
local hpw, hph = surface.GetTextSize(ply:GetNWString("64hp","???"))
local bpw, bph = surface.GetTextSize(ply:GetNWString("64bp","???"))
local cornersize = 9
--draw.RoundedBox(cornersize,192,ScrH()-210,BarSize,50,Color(0, 0, 0, 143))
--draw.RoundedBox(cornersize,192,ScrH()-210,math.min(BarSize*(HPOld/mHPOld),BarSize),50,Color(47+redness+yellowness,yellowness, 0))
--draw.RoundedBox(cornersize,192,ScrH()-200,math.min(BarSize*(APOld/mHPOld),BarSize),40,Color(150,150, 150))
-- if math.Round(ply:GetNWFloat("playerslayers",1),1) > 1 then
	-- for i = 1, math.Round(ply:GetNWFloat("playerslayers",1)) do
		-- if math.max(BarSize*(SPOld/math.max(mSPOld,1))-(BarSize*(i-1)),0) <= BarSize*2 then
			-- draw.RoundedBox(cornersize,192,ScrH()-190,math.min(math.max(BarSize*((SPOld+i)/math.max(mSPOld,1))-(BarSize*(i-1)),0),BarSize),30,Color((math.sin(i/10*4)*255),(math.sin(i/10*8)*255),(math.sin(i/10*12)*255)))
		-- end
	-- end
-- else
--draw.RoundedBox(cornersize,192,ScrH()-190,math.min(BarSize*(SPOld/math.max(mSPOld,1)),BarSize),30,Color(0, 188, 188))
-- end
--draw.RoundedBox(cornersize,192,ScrH()-240,math.Round(ply:GetNWFloat("playerregentime",0),1)*2,30,Color(188, 64, 64, 255))
if !ply.regenbarsize then ply.regenbarsize = 0 end
if ply:GetNWFloat("playerregentime",0) > 0 then
	if ply.regenbarsize > 265*math.ceil(ply:GetNWFloat("playerregentime",0)/60) then
		ply.regenbarsize = math.max(ply.regenbarsize - (RealFrameTime()*160), -13)
	else
		ply.regenbarsize = math.min(ply.regenbarsize + (RealFrameTime()*160), 265*math.ceil(ply:GetNWFloat("playerregentime",0)/60))
	end
else
	ply.regenbarsize = math.max(ply.regenbarsize - (RealFrameTime()*160), -13)
end
local fillquota = (ply:GetNWFloat("playerregentime",0)/60) - (math.min(math.ceil(ply:GetNWFloat("playerregentime",0)/60),6) - 1)
if ply:GetNWFloat("playerregentime",0) <= 0 then fillquota = 0 end
--[[ draw.Champbar("SHIELD", 282, ScrH()-260, math.Clamp(math.ceil(ply:GetNWInt("rarity",1)/1.5),1,7), (600 - (50*(10-ply:GetNWInt("rarity",1))))/2, ply:GetNWInt("64shield",0)/ply:GetNWInt("64maxshield",0))
if ply:GetNWInt("64armour",0) > 0 then
	draw.Champbar("ARMOUR", 282, ScrH()-200, 3, 300, ply:GetNWInt("64armour",0)/ply:GetNWInt("64maxhealth",0))
else
	draw.Champbar("HEALTH", 282, ScrH()-200, ply:GetNWInt("star",1), (600 - (50*(7-ply:GetNWInt("star",1))) - (25*(10-ply:GetNWInt("rarity",1))))/2, ply:GetNWInt("64health",0)/ply:GetNWInt("64maxhealth",0))
end ]]
--draw.Champbar("STAMINA", 282, ScrH()-140, 3, 300, ply:GetNWFloat("stamina",150)/150)
--draw.Champbar("REGEN", 282, ScrH()-80, math.min(math.ceil(ply:GetNWFloat("playerregentime",0)/60),6)/5, ply.regenbarsize, fillquota)
local herorarity = {Color(159,159,159),Color(0,255,0),Color(0,133,255),Color(127,0,255),Color(255,133,0),Color(0,255,255),Color(255,0,0),Color(0,0,255),Color(255,133,133),Color(0,0,0)}
--draw.NixieText( math.floor(CurTime()/3600) .. ":" .. string.FormattedTime( CurTime(), "%02i:%02i;%02i" ), "size112",ScrW()/2,ScrH()-70, Color(255,255,255), TEXT_ALIGN_CENTER,TEXT_ALIGN_BOTTOM,2,Color(0,0,0),0, true)
--surface.SetMaterial(diff[math.Clamp(math.ceil(CurTime()/450),1,#diff-1)])
--surface.SetDrawColor(Color(255,255,255,255))
--surface.DrawTexturedRectRotated(ScrW()/2, ScrH() - 50, 484, 85, 0)
--draw.NixieText( phrase_Power .. ": " .. string.squash(math.Round(powerlevel,2)), "size75",24+(math.Rand(-3,3)*hudpainshake_strength),122+(math.Rand(-3,3)*hudpainshake_strength), Color(208,0,255*hudpainshake_strength), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP,2,Color(67+(255*hudpainshake_strength),0,0),0)
if ply:GetNWFloat("stamina",0) < 150 then
	draw.NixieText("Stamina: " .. string.Comma(math.Round(ply:GetNWInt("stamina",0), 1)*10) .. " / 1,500", "size80l", ScrW()/2, ScrH()/3*2 + 80, Color(255,255,55,133), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,2,Color(0,0,0,52),0,true)
end
if ply:GetNWFloat("playerregentime") > 0 then
	draw.NixieText("Regen: " .. math.Round(ply:GetNWInt("playerregentime",0), 1)*10, "size80l", ScrW()/2, ScrH()/3*2 + 130, Color(255,55,55,133), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,2,Color(0,0,0,52),0,true)
end
local zonetextscale = 200
if ply:GetNWInt("curzone",0) >= 80 then
	zonetextscale = zonetextscale + math.Round(math.sin(CurTime()*2)*20)
end
draw.NixieText("Zone " .. string.Comma(ply:GetNWInt("curzone","?")), "size" .. zonetextscale .. "l", ScrW()/2, 45, Color(511-ply:GetNWInt("curzone",0),256-ply:GetNWInt("curzone",0),256-ply:GetNWInt("curzone",0),255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,2,Color(0,0,0,255),0,true)
if ply:GetNWFloat("spawningallowed", math.huge) > CurTime() then
	draw.NixieText("Loading...", "size90l", ScrW()/2, 115 + (math.sin(CurTime())*8), Color(255,255,133,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,2,Color(0,0,0,255),0,true)
elseif ply:GetNWInt("curzone",1) % 5 == 0 then
	if ply:GetNWInt("zone_remaining",0) >= ply:GetNWInt("zone_enemycount",0) then
		draw.NixieText("Find the Zone Bomb! ", "size70l", ScrW()/2, 145, Color(133,255,133,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,2,Color(0,0,0,255),0,true)
	end
	draw.NixieText("Boss Health: " .. ply:GetNWString("totalnpchp", "?") .. " HP", "size80l", ScrW()/2, 115, Color(127,33,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,2,Color(0,0,0,255),0,true)
else
	if ply:GetNWInt("zone_remaining",0) >= ply:GetNWInt("zone_enemycount",0) then
		draw.NixieText("Find the Zone Bomb! ", "size90l", ScrW()/2, 115 + (math.sin(CurTime())*8), Color(133,255,133,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,2,Color(0,0,0,255),0,true)
	else
		draw.NixieText(string.Comma(ply:GetNWInt("zone_remaining","?")) .. " / " .. string.Comma(ply:GetNWInt("zone_enemycount","?")) .. " ", "size80l", ScrW()/2, 115, Color(133,133,255,255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER,2,Color(0,0,0,255),0,true)
		draw.NixieText(" " .. ply:GetNWString("totalnpchp", "?") .. " HP", "size80l", ScrW()/2, 115, Color(255,133,133,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER,2,Color(0,0,0,255),0,true)
	end
end
if ply:GetNWInt("crippled",0) == 1 then
	draw.NixieText("Fight For Your Life!", "size110", ScrW()/2, (ScrH()/4)*3, Color(255,0,0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,2,Color(0,0,0),0)
	draw.NixieText("Vanquish a foe to revive yourself!", "size60", ScrW()/2, (ScrH()/4)*3 + 50, Color(255,0,0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,2,Color(0,0,0),0)
else
	local fontscale = 120
	local bobbingscale = 0
	if ply:GetNWInt("healthstate",0) <= 1 then
		bobbingscale = 18
	elseif ply:GetNWInt("healthstate",0) <= 3 then
		bobbingscale = 9
	end
	draw.NixieText(ply:GetNWString("64hp","???"), "size" .. fontscale .. "l", 192+(math.Rand(-6,6)*hudpainshake_strength), ScrH()-50+(math.Rand(-6,6)*hudpainshake_strength), Color(100+redness+yellowness+(255*hudpainshake_strength),yellowness,0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER,2,Color(67+(255*hudpainshake_strength),0,0),0, true)
	draw.NixieText(ply:GetNWString("64mhp","???"), "size80l", 192 + hpw+(math.Rand(-6,6)*hudpainshake_strength), ScrH()-50+(math.Rand(-6,6)*hudpainshake_strength), Color(70+(255*hudpainshake_strength),0,0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER,2,Color(47+redness+yellowness+(255*hudpainshake_strength),yellowness,0),0, true)
	draw.NixieText(ply:GetNWString("64sp","???"), "size120l", 192+(math.Rand(-6,6)*hudpainshake_strength), ScrH()-120+(math.Rand(-6,6)*hudpainshake_strength), Color(255*hudpainshake_strength,199,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER,2,Color(255*hudpainshake_strength,79,143),0, true)
	draw.NixieText(ply:GetNWString("64msp","???"), "size80l", 192 + spw+(math.Rand(-6,6)*hudpainshake_strength), ScrH()-120+(math.Rand(-6,6)*hudpainshake_strength), Color(255*hudpainshake_strength,76,122), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER,2,Color(255*hudpainshake_strength,32,63),0, true)
	if ply:GetNWInt("healthstate", 0) >= 3 then
		draw.NixieText(ply:GetNWString("64bp","???"), "size120l", 192+(math.Rand(-6,6)*hudpainshake_strength), ScrH()-190+(math.Rand(-6,6)*hudpainshake_strength), Color(255,0,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER,2,Color(188,0,188),0, true)
		draw.NixieText(ply:GetNWString("64mbp","???"), "size80l", 192 + bpw+(math.Rand(-6,6)*hudpainshake_strength), ScrH()-190+(math.Rand(-6,6)*hudpainshake_strength), Color(127,0,127), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER,2,Color(60,0,60),0, true)
	end
	local ex = 20
	local whi = 95
	--if ply:GetModel() == "models/songbirdplayer/songbirdwingless.mdl" then quota = 2295 end
	draw.SimpleText("Lv " .. string.Comma(ply:GetNWInt("cw3level",0)) .. " " .. string.Comma(ply:GetNWInt("cw3rank",0)) .. " " .. string.Comma(ply:GetNWInt("cw3star",0)) .. " " .. string.Comma(ply:GetNWInt("cw3grade",0)) .. " " .. string.Comma(ply:GetNWInt("cw3specops",0)) .. " " .. string.Comma(ply:GetNWInt("cw3class", 0)) .. " " .. string.Comma(ply:GetNWInt("cw3stage", 0)) .. " " .. string.Comma(ply:GetNWInt("cw3quality",0)) .. " " .. string.Comma(ply:GetNWInt("cw3echelon",0)) .. " " .. string.Comma(ply:GetNWInt("cw3tier",0)), "size95", ex, whi, Color(127,0,0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	draw.SimpleText("Lv " .. string.Comma(ply:GetNWInt("cw3level",0)) .. " " .. string.Comma(ply:GetNWInt("cw3rank",0)) .. " " .. string.Comma(ply:GetNWInt("cw3star",0)) .. " " .. string.Comma(ply:GetNWInt("cw3grade",0)) .. " " .. string.Comma(ply:GetNWInt("cw3specops",0)) .. " " .. string.Comma(ply:GetNWInt("cw3class", 0)) .. " " .. string.Comma(ply:GetNWInt("cw3stage", 0)) .. " " .. string.Comma(ply:GetNWInt("cw3quality",0)) .. " " .. string.Comma(ply:GetNWInt("cw3echelon",0)), "size95", ex, whi, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	draw.SimpleText("Lv " .. string.Comma(ply:GetNWInt("cw3level",0)) .. " " .. string.Comma(ply:GetNWInt("cw3rank",0)) .. " " .. string.Comma(ply:GetNWInt("cw3star",0)) .. " " .. string.Comma(ply:GetNWInt("cw3grade",0)) .. " " .. string.Comma(ply:GetNWInt("cw3specops",0)) .. " " .. string.Comma(ply:GetNWInt("cw3class", 0)) .. " " .. string.Comma(ply:GetNWInt("cw3stage", 0)) .. " " .. string.Comma(ply:GetNWInt("cw3quality",0)), "size95", ex, whi, Color(72,155,72), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	draw.SimpleText("Lv " .. string.Comma(ply:GetNWInt("cw3level",0)) .. " " .. string.Comma(ply:GetNWInt("cw3rank",0)) .. " " .. string.Comma(ply:GetNWInt("cw3star",0)) .. " " .. string.Comma(ply:GetNWInt("cw3grade",0)) .. " " .. string.Comma(ply:GetNWInt("cw3specops",0)) .. " " .. string.Comma(ply:GetNWInt("cw3class", 0)) .. " " .. string.Comma(ply:GetNWInt("cw3stage", 0)), "size95", ex, whi, Color(0,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	draw.SimpleText("Lv " .. string.Comma(ply:GetNWInt("cw3level",0)) .. " " .. string.Comma(ply:GetNWInt("cw3rank",0)) .. " " .. string.Comma(ply:GetNWInt("cw3star",0)) .. " " .. string.Comma(ply:GetNWInt("cw3grade",0)) .. " " .. string.Comma(ply:GetNWInt("cw3specops",0)) .. " " .. string.Comma(ply:GetNWInt("cw3class", 0)), "size95", ex, whi, Color(255,0,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	draw.SimpleText("Lv " .. string.Comma(ply:GetNWInt("cw3level",0)) .. " " .. string.Comma(ply:GetNWInt("cw3rank",0)) .. " " .. string.Comma(ply:GetNWInt("cw3star",0)) .. " " .. string.Comma(ply:GetNWInt("cw3grade",0)) .. " " .. string.Comma(ply:GetNWInt("cw3specops",0)), "size95", ex, whi, Color(32,32,32), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	draw.SimpleText("Lv " .. string.Comma(ply:GetNWInt("cw3level",0)) .. " " .. string.Comma(ply:GetNWInt("cw3rank",0)) .. " " .. string.Comma(ply:GetNWInt("cw3star",0)) .. " " .. string.Comma(ply:GetNWInt("cw3grade",0)), "size95", ex, whi, Color(255,87,0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	draw.SimpleText("Lv " .. string.Comma(ply:GetNWInt("cw3level",0)) .. " " .. string.Comma(ply:GetNWInt("cw3rank",0)) .. " " .. string.Comma(ply:GetNWInt("cw3star",0)), "size95", ex, whi, Color(0,255,0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	draw.SimpleText("Lv " .. string.Comma(ply:GetNWInt("cw3level",0)) .. " " .. string.Comma(ply:GetNWInt("cw3rank",0)), "size95", ex, whi, Color(255,187,0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	draw.SimpleText("Lv " .. string.Comma(ply:GetNWInt("cw3level",0)), "size95", ex, whi, Color(0,87,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	draw.SimpleText("Lv", "size95", ex, whi, Color(199,199,199), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	draw.SimpleText(ply:GetNWString("powerlevel", "?"), "size135", ex, whi - 50, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

if ply:GetActiveWeapon():IsValid() then
local primaryC =  ply:GetActiveWeapon():Clip1() 
local primaryM =  ply:GetActiveWeapon():GetMaxClip1() --ply:GetActiveWeapon():GetNWInt("magsize",ply:GetActiveWeapon():GetMaxClip1())
if primaryM > 200 then
	primaryC = ply:GetActiveWeapon():GetNWInt("actualammo",-1)
end
local primaryAT = ply:GetActiveWeapon():GetPrimaryAmmoType()
local primaryA = ply:GetAmmoCount(primaryAT)
local secondaryA = ply:GetAmmoCount(ply:GetActiveWeapon():GetSecondaryAmmoType())
local secondaryC = ply:GetActiveWeapon():Clip2()
if ply:GetActiveWeapon():GetClass() != "weapon_physcannon" && ply:GetActiveWeapon():GetClass() != "weapon_physgun" && ply:GetActiveWeapon():GetClass() != "gmod_tool" && ply:GetActiveWeapon():GetClass() != "gmod_camera" then
//Show Ammotypes Icons
local TYpos,TXpos = 0,0
-- if primaryAT == 3 then TXpos = 128 elseif primaryAT == 4  then TYpos = 256 elseif primaryAT == 5 then TYpos = 64 TXpos = 64 elseif primaryAT == 1 then TYpos = 64 TXpos = 128 elseif primaryAT == 7 then TYpos = 320 elseif primaryAT == 14 then TYpos = 192 elseif primaryAT == 8 then TYpos = 448 elseif primaryAT == 10 then TXpos = 63 TYpos = 448 else TXpos = 192 end
-- surface.SetTexture( surface.GetTextureID( "bl_hud/hud_icons" ) ) 
-- surface.SetDrawColor(Color(225,255,255,255)) 
-- surface.DrawPartialTexturedRectRotated ( (ScrW()/1.034),(ScrH()/1.317),(ScrW()/41.12), (ScrH()/25.7), TYpos, TXpos, 64, 64, 512, 256, -4 )
if !game.GetAmmoName(primaryAT) or ply:GetActiveWeapon():GetClass() == "robotnik_bo1_dm" or ply:GetActiveWeapon():GetHoldType() == "melee" || ply:GetActiveWeapon():GetHoldType() == "fists" || ply:GetActiveWeapon():GetHoldType() == "knife" || ply:GetActiveWeapon():GetHoldType() == "fist" then
draw.NixieText( "∞", "size60",(ScrW()/1.042),(ScrH()/1.05),  Color(190, 195, 190,255),2, 4,2,Color(0, 0, 0),0)
elseif ply:GetActiveWeapon():GetMaxClip1() < 0 then
draw.NixieText( primaryA  , "size60",(ScrW()/1.042),(ScrH()/1.05),  Color(190, 195, 190,255),2, 4,2,Color(0, 0, 0),0)
elseif ply:GetActiveWeapon():GetPrimaryAmmoType() == 27 or ply:GetActiveWeapon():GetPrimaryAmmoType() == 19 then
draw.NixieText( "[" .. game.GetAmmoName(primaryAT) .. "]  |  " .. string.Comma(primaryC) .. "/" .. string.Comma(primaryM) .. " | " .. string.Comma(primaryA)  , "size85",(ScrW()/1.042),(ScrH()/1.05)+3,  Color(180, 180, 0,255),2, 4,2,Color(0, 0, 0),0)
else
draw.NixieText( "[" .. game.GetAmmoName(primaryAT) .. "]  |  " .. string.Comma(primaryC) .. "/" .. string.Comma(primaryM) .. " | " .. string.Comma(primaryA)  , "size60",(ScrW()/1.042),(ScrH()/1.05),  Color(190, 195, 190,255),2, 4,2,Color(0, 0, 0),0)
end
if secondaryC > 0 && secondaryA > 0 then
draw.NixieText( secondaryC .. "/" .. secondaryA , "size60",(ScrW()/1.25),(ScrH()/1.05),  Color(127, 0, 255,255),2, 4,2,Color(0, 0, 0),0)
elseif secondaryC > 0 then
draw.NixieText( secondaryC , "size60",(ScrW()/1.25),(ScrH()/1.05),  Color(127, 0, 255,255),2, 4,2,Color(0, 0, 0),0)
elseif secondaryA > 0 then
draw.NixieText( secondaryA , "size60",(ScrW()/1.25),(ScrH()/1.05),  Color(127, 0, 255,255),2, 4,2,Color(0, 0, 0),0)
end
end 
end

if !ply.dialoguesetup then
ply.dialogue = ""
ply.dialoguetime = 0
ply.dialoguecharacter = "cube"
ply.dialoguereaction = 1
ply.dialoguetype = 0
ply.nexttype = 0
ply.dialoguesetup = true
end

if ply.dialoguetype < string.len(ply.dialogue) && ply.nexttype < CurTime() then
	if string.sub(ply.dialogue, ply.dialoguetype, ply.dialoguetype) != " " then
		surface.PlaySound("rf/dialogue/" .. ply.dialoguecharacter .. "/normal.wav")
	end
	ply.dialoguetype = math.min(string.len(ply.dialogue), ply.dialoguetype + 1)
	ply.dialoguetime = CurTime() + 3
	ply.nexttype = CurTime() + 0.05
end

if ply.dialoguetime > CurTime() - 2.55 && ply.dialoguetype > 0 then
	draw.SimpleTextOutlined(string.sub(ply.dialogue, 1, ply.dialoguetype), "size70l", 300, ScrH()/4 * 3 - 134, Color(255,255,255, 255 - math.min(0, ply.dialoguetime - CurTime())*100), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 2, Color(0,0,0, 255 - math.min(0, ply.dialoguetime - CurTime())*100))
	surface.SetDrawColor(Color(255,255,255, 255 - math.min(0, ply.dialoguetime - CurTime())*100))
	surface.SetMaterial(cube_faces[math.Clamp(ply.dialoguereaction, 1, #cube_faces)])
	surface.DrawTexturedRectRotated(131, ScrH()/4 * 3 - 134, 262, 268, 0)
end
local accounttypes = {"gold", "timecubes", "weaponcubes"}
for i = 1, 3 do
	local phrases = {"$", "g", "c"}
	local colours = {Color(255,255,0), Color(0,89,255), Color(0,189,0)}
	draw.SimpleTextOutlined(phrases[i] .. ply:GetNWString("account_" .. accounttypes[math.Clamp(i,1,#accounttypes)], 0), "size110l", ScrW() - 10, 60*i, colours[i], TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 2, Color(0,0,0))
end
if IsValid(ply) then
	if !ply.msglifetime or !ply.msgtext or !ply.msgcola or !ply.msgcolb or !ply.msgpends or !ply.msgpos then
		ply.msglifetime = 0
		ply.msgtext = ""
		ply.msgcola = Color(0,0,0)
		ply.msgcolb = Color(0,0,0)
		ply.msgpos = 0
		ply.msgpends = {}
	end
end
if ply.msglifetime > CurTime() then
	ply.msgpos = ply.msgpos + ((ScrH()/2.25 - ply.msgpos)/12)
else
	ply.msgpos = ply.msgpos/1.13
	if #ply.msgpends > 0 then
		if ply.msgpos < (ScrH()/2.25)/5 then
			ply.msglifetime = CurTime() + ply.msgpends[1]["time"]
			ply.msgtext = ply.msgpends[1]["msg"]
			ply.msgcola = ply.msgpends[1]["cola"]
			ply.msgcolb = ply.msgpends[1]["colb"]
			ply.msgpos = 0
			table.remove(ply.msgpends, 1)
		end
	end
end

if ply.msgpos > 1 then
	draw.NixieText(ply.msgtext, "size95", ScrW()/2, ScrH()/3, Color((ply.msgcola.r/2 + ((ply.msgcola.r/2)*math.sin(CurTime()*2))) + (ply.msgcolb.r/2 - ((ply.msgcolb.r/2)*math.sin(CurTime()*2))),(ply.msgcola.g/2 + ((ply.msgcola.g/2)*math.sin(CurTime()*2))) + (ply.msgcolb.g/2 - ((ply.msgcolb.g/2)*math.sin(CurTime()*2))),(ply.msgcola.b/2 + ((ply.msgcola.b/2)*math.sin(CurTime()*2))) + (ply.msgcolb.b/2 - ((ply.msgcolb.b/2)*math.sin(CurTime()*2))), math.min(ply.msgpos,255)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color((ply.msgcolb.r/2 - ((ply.msgcolb.r/2)*math.sin(CurTime()*-2)))+(ply.msgcola.r/2 + ((ply.msgcola.r/2)*math.sin(CurTime()*-2))),(ply.msgcolb.g/2 - ((ply.msgcolb.g/2)*math.sin(CurTime()*-2)))+(ply.msgcola.g/2 + ((ply.msgcola.g/2)*math.sin(CurTime()*-2))),(ply.msgcolb.b/2 - ((ply.msgcolb.b/2)*math.sin(CurTime()*-2)))+(ply.msgcola.b/2 + ((ply.msgcola.b/2)*math.sin(CurTime()*-2))), math.min(ply.msgpos,255)), 0, true)
end

if IsValid(ply) then
	if ply.MusicEnable == nil then ply.MusicEnable = false end
end

if file.Exists("sound/rf/music/craftworld/ambient1.wav", "GAME") then
	if !ply.Ambience then ply.Ambience = CreateSound(ply, "rf/ambience_lv0.wav") end
	if ply.MusicEnable == nil then ply.MusicEnable = false end
	if ply.MusicEnable then
		ply.Ambience:Play()
	else
		ply.Ambience:Stop()
	end
end
--local yaxis = 212 + (ply:GetNWInt("deadstige",0)*20) + (ply:GetNWInt("prestige",0)*20)

--surface.SetMaterial(prestige)

--for c = 1, ply:GetNWInt("prestige",0) do
--surface.SetDrawColor(255,220-(math.max(0,redness-35)),0 + (math.sin(20*c + (CurTime()-c)))*360)
--surface.DrawTexturedRect(20 + math.sin((CurTime()+c)*2)*5, ScrH()-yaxis+(20*c)-(ply:GetNWInt("deadstige",0)*20), 143.5, 51.5)
--end
--surface.SetDrawColor(62,62,62)
--for i = 1, ply:GetNWInt("deadstige",0) do
--surface.DrawTexturedRect(20 + math.sin((CurTime()+i)*2)*5, ScrH()-yaxis+(20*i) + ((ply:GetNWInt("prestige",0)-1)*20), 143.5, 51.5)
--end

if !ply.AuthSnd then ply.AuthSnd = CreateSound(ply, "rf/filecheck.wav") end

if AUTH_Status != "passed" then
	ply.AuthSnd:Play()
elseif ply.AuthSnd:IsPlaying() then
	ply.AuthSnd:Stop()
end

-- surface.SetDrawColor(Color(255,255,255))

-- if ply:GetNWInt("64shield",0) <= 0 then
-- surface.SetMaterial(shield3)
-- elseif ply:GetNWInt("64shield",0) <= ply:GetNWInt("64maxshield",0)/2 then
-- surface.SetMaterial(shield2)
-- else
-- surface.SetMaterial(shield1)
-- end
-- if ply:GetNWInt("64maxshield",0) > 0 then
-- surface.DrawTexturedRect(0, ScrH()-384, 192, 192)
-- end

if ply.DismissTF2Error == nil then ply.DismissTF2Error = false end

if !ply.LowHealth then ply.LowHealth = CreateSound(ply, "rf/lowhp_v2.wav") end

if !ply.NoShield then ply.NoShield = CreateSound(ply, "rf/eva/depleted.wav") end

if !ply.LowStamina then ply.LowStamina = CreateSound(ply,"rf/low_health.wav") end

if ply:GetNWInt("64shield", 0) <= 0 && ply:GetNWString("64sp","0") == "0" then
	ply.NoShield:Play()
else
	ply.NoShield:Stop()
end

if ply:GetNWFloat("stamina", 0) < 80.1 then
	ply.LowStamina:Play()
	ply.LowStamina:ChangeVolume(1 - (ply:GetNWFloat("stamina",0)/150))
else
	ply.LowStamina:Stop()
end

if ply:IsOnGround() then
	if ply:GetNWInt("healthstate",0) <= 2 then
		if !ply:IsProne() then
			RunConsoleCommand("prone")
			ply.ProneFromInjury = true
		end
	elseif ply.ProneFromInjury then
		if ply:IsProne() then
			RunConsoleCommand("prone")
		end
		ply.ProneFromInjury = false
	end
end

surface.SetDrawColor(Color(255,255,255, 255))
if ply:GetNWInt("healthstate") <= 0 or Dead == 1 then
surface.SetMaterial(heart6)
ply.LowHealth:Stop()
elseif ply:GetNWInt("healthstate") <= 1 or ply:GetNWInt("crippled",0) == 1 then
surface.SetMaterial(heart5)
ply.LowHealth:Play()
ply.LowHealth:ChangePitch(100)
ply.LowHealth:ChangeVolume(1)
elseif ply:GetNWInt("healthstate") <= 2 then
surface.SetMaterial(heart4)
ply.LowHealth:Play()
ply.LowHealth:ChangePitch(90)
ply.LowHealth:ChangeVolume(0.7)
elseif ply:GetNWInt("healthstate") <= 3 then
surface.SetMaterial(heart3)
ply.LowHealth:Play()
ply.LowHealth:ChangePitch(75)
ply.LowHealth:ChangeVolume(0.5)
elseif ply:GetNWInt("healthstate") <= 4 then
surface.SetMaterial(heart2)
ply.LowHealth:Stop()
else
surface.SetMaterial(heart1)
ply.LowHealth:Stop()
end
if Dead == 1 then
	surface.DrawTexturedRect(ScrW()/2-192, ScrH()/2-192, 384, 384)
	draw.NixieText( DeadPhrase, "size135",ScrW()/2 + math.Rand(-5,5),ScrH()/2 + math.Rand(-5,5) - 150, Color(58 + (math.sin(CurTime()*9)*58),0,0),1, 1,2,Color(89 + (math.sin(CurTime()*9)*89),0,0),0)
elseif ply:GetNWInt("healthstate") <= 1 then
	for i = 1, 7 do
		surface.SetDrawColor(Color(255,0,0,60 + (10*i)))
		surface.DrawTexturedRectRotated(96, ScrH()-96, 192 + (math.sin((CurTime()-(i*2))*8-(12*(ply:GetNWInt("healthstate",0)/(1))))*90), 192 + (math.sin((CurTime()-(i*2))*10-(16*(ply:GetNWInt("healthstate",0)/(1))))*90), math.sin(CurTime()*4)*5)
	end
	surface.SetDrawColor(Color(255,0,0))
	surface.DrawTexturedRectRotated(96 + math.Rand(-20,20), ScrH()-96 + math.Rand(-20,20), 192 + (math.sin(CurTime()*15-(12*(ply:GetNWInt("healthstate",0)/(1))))*30), 192 + (math.sin(CurTime()*20-(16*(ply:GetNWInt("healthstate",0)/(1))))*30), math.sin(CurTime()*4)*5)
	surface.SetDrawColor(Color(0,255,255))
	surface.DrawTexturedRectRotated(96 + math.Rand(-20,20), ScrH()-96 + math.Rand(-20,20), 192 + (math.sin(CurTime()*15-(12*(ply:GetNWInt("healthstate",0)/(1))))*30), 192 + (math.sin(CurTime()*20-(16*(ply:GetNWInt("healthstate",0)/(1))))*30), math.sin(CurTime()*4)*5)
	surface.SetDrawColor(Color(255,127.5 - math.sin((CurTime()*2))*(redness/2) + math.min(127.5, 127.5-(redness/2)),127.5 - math.sin((CurTime()*2))*(redness/2) + math.min(127.5, 127.5-(redness/2))))
	surface.DrawTexturedRectRotated(96, ScrH()-96, 192 + (math.sin(CurTime()*15-(12*(ply:GetNWInt("healthstate",0)/(1))))*30), 192 + (math.sin(CurTime()*20-(16*(ply:GetNWInt("healthstate",0)/(1))))*30), math.sin(CurTime()*4)*5)
elseif ply:GetNWInt("healthstate") <= 3 then
	for i = 1, 3 do
		surface.SetDrawColor(Color(255,0,0,60 + (20*i)))
		surface.DrawTexturedRectRotated(96, ScrH()-96, 192 + (math.sin((CurTime()+(4-i))*4-(12*(ply:GetNWInt("healthstate",0)/(1 * 3))))*(5+(10*((1 * 3)/ply:GetNWInt("healthstate",0))))), 192 + (math.sin((CurTime()+(4-i))*5-(16*(ply:GetNWInt("healthstate",0)/(1 * 3))))*(5+(10*((1 * 3)/ply:GetNWInt("healthstate",0))))), math.sin((CurTime()+(4-i))*4)*3)
	end
	surface.SetDrawColor(Color(255,127.5 - math.sin((CurTime()*2))*(redness/2) + math.min(127.5, 127.5-(redness/2)),127.5 - math.sin((CurTime()*2))*(redness/2) + math.min(127.5, 127.5-(redness/2))))
	surface.DrawTexturedRectRotated(96, ScrH()-96, 192 + (math.sin(CurTime()*4-(12*(ply:GetNWInt("healthstate",0)/3)))*(5+(10*((3)/ply:GetNWInt("healthstate",0))))), 192 + (math.sin(CurTime()*5-(16*(ply:GetNWInt("healthstate",0)/(1 * 3))))*(5+(10*((1 * 3)/ply:GetNWInt("healthstate",0))))), math.sin(CurTime()*4)*3)
else
	surface.DrawTexturedRectRotated(96, ScrH()-96, 192, 192, 0)
end

local yaxis = 137

surface.SetMaterial(deadstige)

surface.SetDrawColor(255,255,255)
for i = 1, ply:GetNWInt("deadstige",0) do
	surface.DrawTexturedRectRotated(94 + math.sin((CurTime()+i)*2)*5, ScrH()-yaxis-(20*i)-45, 143.5 + math.sin((CurTime()-i)*2)*(redness/50), 51.5 - math.sin((CurTime()-i)*2)*(redness/50), math.sin(CurTime()-i*2)*(redness/50))
end
for c = 1, math.min(ply:GetNWInt("prestige",0),5) do
--surface.SetMaterial(prestige[c])
surface.SetMaterial(prestige)
surface.SetDrawColor(255,255-(math.max(0,redness-35)),(255-redness) - (math.sin(20*c + (CurTime()-c)))*360)
surface.DrawTexturedRectRotated(94 + math.sin((CurTime()+c+ply:GetNWInt("deadstige",0))*2)*5, ScrH()-yaxis-(20*c)-(ply:GetNWInt("deadstige",0)*20)-45, 143.5 + math.sin((CurTime()-c)*2)*(redness/50), 51.5 - math.sin((CurTime()-c)*2)*(redness/50), math.sin(CurTime()-c*2)*(redness/50))
end

draw.NixieText( "CRAFTWORLD3 v3.1 (c) Jen Walter 2020", "size55", ScrW(), 0, Color(199,199,255,122),2,0,0,Color(0,0,0,0), 0, true)
draw.NixieText( "After 3 years in development - hopefully, it will have been worth the wait.", "size35", ScrW(), 20, Color(199,199,199,122),2,0,0,Color(0,0,0,0), 0, true)

if game.SinglePlayer == true then
	draw.NixieText( "Warning! You are playing CRAFTWORLD3 in SINGLEPLAYER", "size35", ScrW()/2, 0, Color(255,199,199,122),1,0,0,Color(0,0,0,0), 0)
	draw.NixieText( "There may be some unforseen bugs and/or oddities", "size35", ScrW()/2, 30, Color(255,199,199,122),1,0,0,Color(0,0,0,0), 0)
end

local ErrorOccurred = 0

function dismissMessage()
	ErrorOccurred = 0
end

concommand.Add("errormsg_dismiss", dismissMessage())
hook.Add("OnLuaError", "JenErrorWarn", function()
	ErrorOccurred = 1
end)
 
if ErrorOccurred == 1 then
	surface.SetDrawColor( 0, 0, 0, 175 )
	surface.DrawRect( 0, 0, ScrW(), ScrH() )
	draw.NixieText( phrase_Error, "size75", ScrW()/2, (ScrH()/2), Color(163,0,0,255),1,4,2,Color(36,36,36,255), 0)
	draw.NixieText( phrase_ErrorInstruction, "size38", ScrW()/2, (ScrH()/2) + 80, Color(163,0,0,255),1,4,2,Color(36,36,36,255), 0)
	draw.NixieText( phrase_ErrorDismiss, "size38", ScrW()/2, (ScrH()/2) + 130, Color(163,0,0,255),1,4,2,Color(36,36,36,255), 0)
end
end

hook.Add("HUDPaint", "BL_HUD_COND", bl_hud_cond)
//hook.Remove("HUDPaint", "BL_HUD_COND")

hook.Remove("HUDPaint", "BL_HUD_AMMO")
//hook.Remove("HUDPaint", "BL_HUD_AMMO")

hook.Add("HUDPaint", "BL_TF2CONTENTERROR", TF2Error)
--hook.Add("HUDPaint", "BL_AUTHMSG", AuthMessage)

timer.Simple(10, function() RunConsoleCommand("cw3_refresh_text") end)

concommand.Add( "cw3_refresh_text", function()
for i = 1, 255 do
	createRoboto(i)
end
end )
end