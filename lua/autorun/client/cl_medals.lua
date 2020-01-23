local iconSpacing = 5

local iconWidth = 100
local iconHeight = 100

local iconLifespan = 0.6

local honour = 0
local pendinghonour = 0
local pendinghonourtime = 0
local stopsoundplayed = false

//Speeds
local iconIntroSpeed = 2
local iconExpandSpeed = 7
local iconContractSpeed = 7
local iconFadeSpeed = 1000
local iconVirtualWidthSpeed = 2

//Scales
local iconStartScale = 0.5
local iconSteadyScale = 1
local iconMaxScale = 1.5

//Alpha
local iconStartAlpha = 0.5 * 255

//Rotations
local iconStartRotation = 180

//Timings
local iconSkipTime = 0.1

local medals = {}

local activeMedals = {}
local pendingMedals = {}
local earnedMedals = {}
local soundStack  = {}
local playingSound = false

//Medal x position as a percentage of the width of the screen
CreateConVar( "medals_x", "16", FCVAR_ARCHIVE )

//Medal y position as a percentage of the width of the screen
CreateConVar( "medals_y", "75", FCVAR_ARCHIVE )

//Medal volume out of 255
CreateConVar( "medals_volume", "75", FCVAR_ARCHIVE )

//Medal enabled
CreateConVar( "medals_enabled", "1", FCVAR_ARCHIVE )

//Would like to do this not in think
hook.Add( "Think", "HaloMedalSounds", function()

	if not GetConVar( "medals_enabled" ):GetBool() then return end

	//Check for sounds to be played
	if #soundStack > 0 and not playingSound then

		local medal = soundStack[1]

		//Play next sound
		sound.PlayFile( "sound/rf/medals/" .. medal .. ".wav", "", function( channel ) 

			if not channel then 
				playingSound = false
				return 
			end

			channel:SetVolume( math.Clamp( GetConVar( "medals_volume" ):GetFloat(), 0, 255 ) )

			timer.Simple( channel:GetLength(), function()
				playingSound = false
			end )
		end )

		table.remove( soundStack, 1 )

		playingSound = true

	end
	
	if #activeMedals < 1+math.floor(#pendingMedals/10) && #pendingMedals > 0 then
		local sndf = "rf/pointtally.wav"
		if pendingMedals[1]["score"] >= 50 then sndf = "rf/pointtally_large.wav" end
		if pendinghonourtime <= CurTime() then pendinghonour = 0 end
		local scorearchive = pendingMedals[1]["score"]/10
				if scorearchive*10 >= 500 then
					surface.PlaySound("rf/dice/count_wondrous.wav")
				elseif scorearchive*10 >= 250 then
					surface.PlaySound("rf/dice/count_massive.wav")
				elseif scorearchive*10 >= 50 then
					surface.PlaySound("rf/dice/count_large.wav")
				elseif scorearchive*10 >= 25 then
					surface.PlaySound("rf/dice/count.wav")
				end
		for i = 1, 10 do
			timer.Simple(i/10, function()
				pendinghonour = pendinghonour + scorearchive
				pendinghonourtime = CurTime() + 3
				stopsoundplayed = false
			end)
		end
		surface.PlaySound( sndf )
		if file.Exists("sound/rf/medals/" .. pendingMedals[1]["medal"] .. ".wav", "GAME") then surface.PlaySound("rf/medals/" .. pendingMedals[1]["medal"] .. ".wav") end
		pendingMedals[1]["state"] = 0
		pendingMedals[1]["virtualWidth"] = 0
		pendingMedals[1]["scale"] = iconStartScale
		pendingMedals[1]["skipTime"] = 0
		pendingMedals[1]["alpha"] = 0
		pendingMedals[1]["rotation"] = 0
		table.insert( activeMedals, 1, pendingMedals[1] )
		table.remove( pendingMedals, 1 )
	end

end )

function addHaloMedal( medal, score )

	local name = medal

	//If we haven't loaded this medal before, load it now
	if not medals[ medal ] then
		local mat = Material( "rf/medals/" .. medal .. ".png" )
			
		//If this medal doesn't exist, fail
		if mat:IsError() then 
			print( "Halo Medals: This medal " .. medal .. " does not exist or cannot be found" )
			return
		end

		medals[ medal ] = mat
	end

	//Add the sound to the stack
	-- if file.Exists("sound/rf/medals/" .. medal .. ".wav", "GAME") then
		-- soundStack[ #soundStack + 1 ] = medal
	-- end

	local insertPos = #pendingMedals + 1

	table.insert( pendingMedals, insertPos, {
		["medal"] = medal,
		["name"] = name,
		["state"] = 0,
		["virtualWidth"] = 0,
		["scale"] = iconStartScale,
		["skipTime"] = 0,
		["alpha"] = 0,
		["rotation"] = 0,
		["score"] = score
	} )

end

//States: 0=fadein, 1=expand, 2=contract, 3=steady, 4=fadeout
hook.Add( "HUDPaint", "DrawMedals", function()

	if not GetConVar( "medals_enabled" ):GetBool() then return end

	surface.SetDrawColor( Color( 255, 255, 255 ) )
	
	local curX = 0
	local curX2 = 0
	local curX3 = 0
	for I = 1, #activeMedals do
		curMed = activeMedals[I]

		if not curMed then continue end

		//Allow us to wait
		local skipProcessing
		if CurTime() <= curMed.skipTime then
			skipProcessing = true
		end

		//Load medal material
		surface.SetMaterial( medals[ curMed.medal ] )
		if not skipProcessing then
			if curMed.state == 0 then //If we're fading in
				//Increase our scale to fade in
				curMed.scale = curMed.scale + iconIntroSpeed * FrameTime()

				//Calculate how done we are with fading in
				local fadeInPercent = math.min( ( curMed.scale - iconStartScale ) / ( iconSteadyScale - iconStartScale ), 1 )

				//Calculate our virtual width
				curMed.virtualWidth = fadeInPercent * iconWidth

				//Calculate our alpha
				curMed.alpha = iconStartAlpha + ( fadeInPercent * ( 255 - iconStartAlpha ) )

				//Calculate our rotation
				curMed.rotation = ( iconStartRotation * fadeInPercent ) - iconStartRotation

				//Once we're at the right scale
				if curMed.scale >= iconSteadyScale then
					//Wait a moment before expanding again
					curMed.skipTime = CurTime() + iconSkipTime

					//Set our state to expand
					curMed.state = 1
				end
			elseif curMed.state == 1 then //If we're expanding
				//Increase scale to expand
				curMed.scale = curMed.scale + iconExpandSpeed  * FrameTime()

				//Once we're at max size
				if curMed.scale >= iconMaxScale then

					//Make sure we don't go over max scale
					curMed.scale = math.min( curMed.scale, iconMaxScale )

					//Set our state to contract
					curMed.state = 2
				end
			elseif curMed.state == 2 then //If we're contracting
				//Reduce our scale to contract
				curMed.scale = curMed.scale - iconContractSpeed  * FrameTime()

				//Once we're at steady size
				if curMed.scale <= iconSteadyScale then
					
					//Make sure we don't go under steady scale
					curMed.scale = math.max( curMed.scale, iconSteadyScale )

					//Wait for our lifespan
					curMed.skipTime = CurTime() + iconLifespan

					//Set our state to fadeout after lifespan is up
					curMed.state = 3
				end
			elseif curMed.state == 3 then //If we're fading out
				//Reduce our alpha
				curMed.alpha = curMed.alpha - iconFadeSpeed  * FrameTime()

				//If we've completely faded
				if curMed.alpha <= 0 then

					//Remove ourself from the medal table
					curMed["state"] = 0
					curMed["virtualWidth"] = 0
					curMed["scale"] = iconStartScale
					curMed["skipTime"] = 0
					curMed["alpha"] = 0
					curMed["rotation"] = 0
					table.insert( earnedMedals, 1, curMed )
					table.remove( activeMedals, I )
					continue
				end

			end
		end
		
		local offs = ((255-(math.Clamp(curMed.alpha,0,255)))*(100/255))*(I-1)
		
		if curMed.state != 3 then offs = 0 end

		local w = iconWidth * curMed.scale
		local h = iconHeight * curMed.scale

		local startX = ScrW() / 2 + 52
		local startY = ScrH() / 1.18

		surface.SetDrawColor( 255, 255, 255, curMed.alpha )
		surface.DrawTexturedRectRotated( startX - offs + curX - w / (2 * curMed.scale), startY - h / (2 * curMed.scale), w, h, curMed.rotation )
		if I == 1 then
			draw.SimpleTextOutlined( string.upper(curMed.name), "size" .. math.Clamp(math.Round(140 * curMed.scale), 1, 140), ScrW()/2, ScrH()/1.15, Color(0,167,255, curMed.alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,255,255, curMed.alpha) )
			draw.SimpleTextOutlined( "+" .. string.Comma(curMed.score), "size" .. math.Clamp(math.Round(90 * curMed.scale), 1, 90) .. "l", ScrW()/2, ScrH()/1.15 + 40, Color(255,255,255, curMed.alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0, curMed.alpha) )
		end

		curX = curX + curMed.virtualWidth + iconSpacing
	end
	local medaltbl = table.Reverse(pendingMedals)
	for I = 1, #medaltbl do
		curMed2 = medaltbl[I]

		if not curMed2 then continue end

		//Allow us to wait
		local skipProcessing
		if CurTime() <= curMed2.skipTime then
			skipProcessing = true
		end

		//Load medal material
		surface.SetMaterial( medals[ curMed2.medal ] )
		if not skipProcessing then
			if curMed2.state == 0 then //If we're fading in
				//Increase our scale to fade in
				curMed2.scale = curMed2.scale + iconIntroSpeed * FrameTime()

				//Calculate how done we are with fading in
				local fadeInPercent = math.min( ( curMed2.scale - iconStartScale ) / ( iconSteadyScale - iconStartScale ), 1 )

				//Calculate our virtual width
				curMed2.virtualWidth = fadeInPercent * iconWidth

				//Calculate our alpha
				curMed2.alpha = iconStartAlpha + ( fadeInPercent * ( 255 - iconStartAlpha ) )

				//Calculate our rotation
				curMed2.rotation = ( iconStartRotation * fadeInPercent ) - iconStartRotation

				//Once we're at the right scale
				if curMed2.scale >= iconSteadyScale then
					//Wait a moment before expanding again
					curMed2.skipTime = CurTime() + iconSkipTime

					//Set our state to expand
					curMed2.state = 1
				end
			elseif curMed2.state == 1 then //If we're expanding
				//Increase scale to expand
				curMed2.scale = curMed2.scale + iconExpandSpeed  * FrameTime()

				//Once we're at max size
				if curMed2.scale >= iconMaxScale then

					//Make sure we don't go over max scale
					curMed2.scale = math.min( curMed2.scale, iconMaxScale )

					//Set our state to contract
					curMed2.state = 2
				end
			elseif curMed2.state == 2 then //If we're contracting
				//Reduce our scale to contract
				curMed2.scale = curMed2.scale - iconContractSpeed  * FrameTime()

				//Once we're at steady size
				if curMed2.scale <= iconSteadyScale then
					
					//Make sure we don't go under steady scale
					curMed2.scale = math.max( curMed2.scale, iconSteadyScale )

					//Wait for our lifespan
					curMed2.skipTime = CurTime() + iconLifespan

					//Set our state to fadeout after lifespan is up
					curMed2.state = 3
				end
			end
		end
		
		local offs = ((255-(math.Clamp(curMed2.alpha,0,255)))*(100/255))*(I-1)
		
		if curMed2.state != 3 then offs = 0 end

		local w = iconWidth * curMed2.scale
		local h = iconHeight * curMed2.scale

		local startX = ScrW() / 8
		local startY = ScrH() / 1.35

		surface.SetDrawColor( 255, 255, 255, curMed2.alpha )
		surface.DrawTexturedRectRotated( startX - offs + curX2/6 - w / (2 * curMed2.scale), startY - h / (2 * curMed2.scale), w, h, curMed2.rotation )
		
		curX2 = curX2 + curMed2.virtualWidth + iconSpacing
	end
	for I = 1, math.min(#earnedMedals,9) do
		curMed3 = earnedMedals[I]

		if not curMed3 then continue end

		//Allow us to wait
		local skipProcessing
		if CurTime() <= curMed3.skipTime then
			skipProcessing = true
		end

		//Load medal material
		surface.SetMaterial( medals[ curMed3.medal ] )
		if not skipProcessing then
			if curMed3.state == 0 then //If we're fading in
				//Increase our scale to fade in
				curMed3.scale = curMed3.scale + iconIntroSpeed * FrameTime()

				//Calculate how done we are with fading in
				local fadeInPercent = math.min( ( curMed3.scale - iconStartScale ) / ( iconSteadyScale - iconStartScale ), 1 )

				//Calculate our virtual width
				curMed3.virtualWidth = fadeInPercent * iconWidth

				//Calculate our alpha
				curMed3.alpha = iconStartAlpha + ( fadeInPercent * ( 255 - iconStartAlpha ) )

				//Calculate our rotation
				curMed3.rotation = ( iconStartRotation * fadeInPercent ) - iconStartRotation

				//Once we're at the right scale
				if curMed3.scale >= iconSteadyScale then
					//Wait a moment before expanding again
					curMed3.skipTime = CurTime() + iconSkipTime

					//Set our state to expand
					curMed3.state = 1
				end
			elseif curMed3.state == 1 then //If we're expanding
				//Increase scale to expand
				curMed3.scale = curMed3.scale + iconExpandSpeed  * FrameTime()

				//Once we're at max size
				if curMed3.scale >= iconMaxScale then

					//Make sure we don't go over max scale
					curMed3.scale = math.min( curMed3.scale, iconMaxScale )

					//Set our state to contract
					curMed3.state = 2
				end
			elseif curMed3.state == 2 then //If we're contracting
				//Reduce our scale to contract
				curMed3.scale = curMed3.scale - iconContractSpeed  * FrameTime()

				//Once we're at steady size
				if curMed3.scale <= iconSteadyScale then
					
					//Make sure we don't go under steady scale
					curMed3.scale = math.max( curMed3.scale, iconSteadyScale )

					//Wait for our lifespan
					curMed3.skipTime = CurTime() + iconLifespan

					//Set our state to fadeout after lifespan is up
					curMed3.state = 3
				end
			end
		end
		
		local offs = ((255-(math.Clamp(curMed3.alpha,0,255)))*(100/255))*(I-1)
		
		if curMed3.state != 3 then offs = 0 end

		local w = iconWidth * curMed3.scale
		local h = iconHeight * curMed3.scale

		local startX = ScrW() / 1.275
		local startY = ScrH() / 1.57

		surface.SetDrawColor( 255, 255, 255, curMed3.alpha )
		surface.DrawTexturedRectRotated( startX - offs + curX3/2 - w / (2 * curMed3.scale), startY - h / (2 * curMed3.scale), w, h, curMed3.rotation )
		
		curX3 = curX3 + curMed3.virtualWidth + iconSpacing
	end
	
	if pendinghonourtime > CurTime() then
		draw.SimpleTextOutlined( string.Comma((honour or 0) + math.Round(pendinghonour or 0)) .. " Honour", "size90l", ScrW()/2, ScrH() - 65, Color(255,255,167), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0) )
		draw.SimpleTextOutlined( "+" .. string.Comma(math.Round(pendinghonour) or 0), "size83l", ScrW()/2, ScrH() / 5 * 3, Color(255,325 - (pendinghonour/12.5),325 - (pendinghonour/12.5)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0) )
	elseif pendinghonourtime + 2.55 > CurTime() then
		local fade = (pendinghonourtime + 2.55) - CurTime()
		if !stopsoundplayed then surface.PlaySound("rf/pointstop.wav") stopsoundplayed = true honour = (honour or 0) + pendinghonour end
		draw.SimpleTextOutlined( string.Comma(honour or 0) .. " Honour", "size90l", ScrW()/2, ScrH() - 65, Color(255,255,167), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0) )
		draw.SimpleTextOutlined( "+" .. string.Comma(math.Round(pendinghonour) or 0), "size83l", ScrW()/2, ScrH() / 5 * 3, Color(255,255,255,fade*100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(255,255,255,fade*100) )
	else
		draw.SimpleTextOutlined( string.Comma(honour or 0) .. " Honour", "size90l", ScrW()/2, ScrH() - 65, Color(255,255,167), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0) )
	end
	
	draw.SimpleTextOutlined( string.Comma(#earnedMedals) .. " Medals", "size90l", ScrW()/2, ScrH() - 25, Color(122,167,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0) )

end )

net.Receive( "AddHaloMedal", function()

	if not GetConVar( "medals_enabled" ):GetBool() then return end

	local medal = net.ReadString()
	local score = net.ReadInt(32)
	addHaloMedal( medal, score )
	
end)
