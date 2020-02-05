function surface.DrawPartialTexturedRect( x, y, w, h, partx, party, partw, parth, texw, texh )
/* Source: http://facepunch.com/showthread.php?t=1026117 */
	--[[ 
		Arguments:
		x: Where is it drawn on the x-axis of your screen
		y: Where is it drawn on the y-axis of your screen
		w: How wide must the image be?
		h: How high must the image be?
		partx: Where on the given texture's x-axis can we find the image you want?
		party: Where on the given texture's y-axis can we find the image you want?
		partw: How wide is the partial image in the given texture?
		parth: How high is the partial image in the given texture?
		texw: How wide is the texture?
		texh: How high is the texture?
	]]--
	
	-- Verify that we recieved all arguments
	if not( x && y && w && h && partx && party && partw && parth && texw && texh ) then
		ErrorNoHalt("surface.DrawPartialTexturedRect: Missing argument!");
		
		return;
	end;
	
	-- Get the positions and sizes as percentages / 100
	local percX, percY = partx / texw, party / texh;
	local percW, percH = partw / texw, parth / texh;
	
	-- Process the data
	local vertexData = {
		{
			x = x,
			y = y,
			u = percX,
			v = percY
		},
		{
			x = x + w,
			y = y,
			u = percX + percW,
			v = percY
		},
		{
			x = x + w,
			y = y + h,
			u = percX + percW,
			v = percY + percH
		},
		{
			x = x,
			y = y + h,
			u = percX,
			v = percY + percH
		}
	};
		
	surface.DrawPoly( vertexData );
end;  

// Rotate Parted Texture
function surface.DrawPartialTexturedRectRotated( x, y, w, h, partx, party, partw, parth, texw, texh, rot )
local matrix = Matrix()
      matrix:Rotate( Angle( 0,-rot,0 ) )  
cam.PushModelMatrix( matrix )
surface.DrawPartialTexturedRect( x, y, w, h, partx, party, partw, parth, texw, texh )
cam.PopModelMatrix()
end
// Rotate SimpleTextOutlined
function draw.NixieText(text,font,x,y,color,xAlign,yAlign,outlinewidth,outlinecolor,rot,notamper)
local matrix = Matrix()
      matrix:Rotate( Angle( 0,rot,0 ) )  
cam.PushModelMatrix( matrix )
surface.SetFont(font)
local UNUSED,offy = surface.GetTextSize(font)
local aberration = offy/35
local aberration2 = aberration*2
local randomcharacters = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","0","1","2","3","4","5","6","7","8","9","!","@","#","$","%","^","&","(",")","[","]","|","б","г","д","ё","ж","п","ф","и","й","л","ц","ш","щ","э","ю","я","ч","ы","к"}
local textchars = {}
local chance0 = 200
local chance1 = 30
local chance2 = 80
local chance3 = 35
if LocalPlayer():GetNWInt("healthstate",0) <= 1 then
	chance0 = 50
	chance1 = 2
	chance2 = 4
	chance3 = 3
end
if !notamper then
for i = 1, string.len(text) do
	table.insert(textchars, string.sub(text,i,i))
end
for r = 1, #textchars do
	if math.random(1,chance0) == 1 then
		if math.random(1,2) == 1 then
			textchars[r] = string.upper(randomcharacters[math.random(#randomcharacters)])
		else
			textchars[r] = randomcharacters[math.random(#randomcharacters)]
		end
	end
end
text = ""
for c = 1, #textchars do
	text = text .. textchars[c]
end
end
if !notamper then
if math.random(1,chance1) == 1 then color.a = color.a - 20 outlinecolor.a = outlinecolor.a - 50 end
if math.random(1,chance1) == 1 then color.r = color.r - 30 end
if math.random(1,chance1) == 1 then color.g = color.g - 30 end
if math.random(1,chance1) == 1 then color.b = color.b - 30 end
end
local x2 = x
local x3 = x
local x4 = x
local x5 = x
local y2 = y
local y3 = y
local y4 = y
local y5 = y
if LocalPlayer():GetNWInt("healthstate",0) <= 3 then
	x = x + math.Rand(-3,3)
	y = y + math.Rand(-3,3)
	x2 = x2 + math.Rand(-3,3)
	y2 = y2 + math.Rand(-3,3)
	x3 = x3 + math.Rand(-3,3)
	y3 = y3 + math.Rand(-3,3)
	x4 = x4 + math.Rand(-3,3)
	y4 = y4 + math.Rand(-3,3)
	x5 = x5 + math.Rand(-3,3)
	y5 = y5 + math.Rand(-3,3)
end
if LocalPlayer():GetNWInt("healthstate",0) <= 2 then
	x = x + math.Rand(-5,5)
	y = y + math.Rand(-5,5)
	x2 = x2 + math.Rand(-5,5)
	y2 = y2 + math.Rand(-5,5)
	x3 = x3 + math.Rand(-5,5)
	y3 = y3 + math.Rand(-5,5)
	x4 = x4 + math.Rand(-5,5)
	y4 = y4 + math.Rand(-5,5)
	x5 = x5 + math.Rand(-5,5)
	y5 = y5 + math.Rand(-5,5)
end
if LocalPlayer():GetNWInt("healthstate",0) <= 1 then
	x = x + math.Rand(-8,8)
	y = y + math.Rand(-8,8)
	x2 = x2 + math.Rand(-8,8)
	y2 = y2 + math.Rand(-8,8)
	x3 = x3 + math.Rand(-8,8)
	y3 = y3 + math.Rand(-8,8)
	x4 = x4 + math.Rand(-8,8)
	y4 = y4 + math.Rand(-8,8)
	x5 = x5 + math.Rand(-8,8)
	y5 = y5 + math.Rand(-8,8)
end
if math.random(1,chance2) == 1 then aberration = aberration*1.5 end
if math.random(1,chance2) == 1 then aberration2 = aberration2*1.5 end
if math.random(1,chance3) == 1 then x = x + math.Rand(-2,2) end
draw.SimpleText(text , font,x5+aberration2,y5+aberration2,outlinecolor,xAlign, yAlign)
draw.SimpleText(text , font,x4-aberration2,y4-aberration2,outlinecolor,xAlign, yAlign)
draw.SimpleText(text , font,x3-aberration,y3-aberration,Color(0,255,255,color.a),xAlign, yAlign)
draw.SimpleText(text , font,x2+aberration,y2+aberration,Color(255,0,0,color.a),xAlign, yAlign)
if LocalPlayer():GetNWBool("cw3godmode", false) then
	for a = 1, 5 do
		draw.SimpleText(text , font,x + ((math.sin(CurTime()*2.15)*8)*(6-a)),y,Color(255,0,0,25*a),xAlign, yAlign)
	end
	for b = 1, 5 do
		draw.SimpleText(text , font,x - ((math.sin(CurTime()*2.15)*8)*(6-b)),y,Color(0,0,255,25*b),xAlign, yAlign)
	end
end
draw.SimpleText(text , font,x,y,color,xAlign, yAlign)
cam.PopModelMatrix()
end

local edgesmall = Material("rf/smallbar_edge.png")
local fillsmall = Material("rf/smallbar_fill.png")
local edgelarge = Material("rf/bar_edge.png")
local filllarge = Material("rf/bar_fill.png")
local barcolors = {Color(228, 92, 77), Color(203, 209, 236), Color(252,239,27), Color(186, 244, 249), Color(10, 255, 96), Color(10, 210, 255), Color(255, 232, 102), Color(255, 206, 107), Color(230, 214, 255), Color(221, 221, 188), Color(237,244,170), Color(248, 182, 213), Color(248,201,255), Color(255,255,255), Color(233,207,137), Color(217, 203, 176), Color(218, 218, 214), Color(232, 198, 199), Color(243, 254, 254), Color(112, 186, 161), Color(255,0,0), Color(133,0,0), Color(0,0,133), Color(255,0,255), Color(255, 133, 133), Color(64,0,64), Color(99,99,99), Color(127, 0, 255), Color(144, 144, 255), Color(64, 0, 64)}
local bars = {Material("rf/bar1.png"),Material("rf/bar2.png"),Material("rf/bar3.png"),Material("rf/bar4.png"),Material("rf/bar5.png"),Material("rf/bar6.png"),Material("rf/bar7.png")}
local baredges = {Material("rf/baredge1.png"),Material("rf/baredge2.png"),Material("rf/baredge3.png"),Material("rf/baredge4.png"),Material("rf/baredge5.png"),Material("rf/baredge6.png"),Material("rf/baredge7.png")}
local frames = {Material("rf/frame1.png"),Material("rf/frame2.png"),Material("rf/frame3.png"),Material("rf/frame4.png"),Material("rf/frame5.png"),Material("rf/frame6.png"),Material("rf/frame7.png")}

function draw.Champbar(text,x,y,tier,length,fill)
	tier = math.min(math.max(1,tier),7)
	fill = math.min(fill, 1)
	draw.RoundedBox(5, x-4, y+21, math.max(0,(length+4)), 30, Color(46,46,46,255))
	if tier >= 7 then
		draw.RoundedBox(5, x-4, y+21, math.max(0,(length+4)*fill), 30, Color(0,255*fill,255,255))
	else
		draw.RoundedBox(5, x-4, y+21, math.max(0,(length+4)*fill), 30, Color(255,255*fill,0,255))
	end
	surface.SetDrawColor(Color(255,255,255,255))
	surface.SetMaterial(baredges[tier])
	surface.DrawTexturedRect(x-4,y+5,math.max(0,length-3),65)
	surface.SetMaterial(bars[tier])
	surface.DrawTexturedRect(x-45+length,y+5,65,65)
	draw.RoundedBox(5, x-70, y+10, 60, 50, Color(46,46,46,255))
	draw.SimpleText(text, "DermaDefault", x-38, y+35, Color(199,199,199), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	surface.SetDrawColor(Color(255,255,255,255))
	surface.SetMaterial(frames[tier])
	surface.DrawTexturedRect(x-82,y,86,68)
end
-- function draw.Multibar(x,y,length,fill,usechip,chip)
	-- draw.RoundedBox(0, x, y, length, 14, Color(0,0,0,138))
		-- for i = 0, math.ceil(fill) do
			-- if i > math.ceil(fill)-3 then
				-- surface.SetMaterial(edgesmall)
				-- surface.SetDrawColor(barcolors[math.min(i+1,#barcolors)])
				-- local sum = fill
				-- if usechip then
					-- if !chip then chip = 0 end
					-- sum = fill-chip
				-- end
				-- surface.DrawTexturedRect(x, y, 2, 14)
				-- surface.DrawTexturedRect(x + math.min(math.max((length*(sum-i)),0),length), y, 2, 14)
				-- surface.SetMaterial(fillsmall)
				-- surface.DrawTexturedRect(x+2, y, math.min(math.max(0,(length*(fill-i))-2),length-2), 14)
				-- if usechip then
					-- render.SetScissorRect(x, y, x + length, y + 14, true)
					-- surface.SetDrawColor(Color(58,58,58))
					-- surface.DrawTexturedRect(x+(length*(fill-i)), y, math.min(math.max(0,(length*-chip)),length), 14)
					-- render.SetScissorRect(0,0,0,0,false)
				-- end
			-- end
		-- end
-- end
-- function draw.LargeMultibar(x,y,length,fill,usechip,chip)
	-- draw.RoundedBox(0, x, y, length, 34, Color(0,0,0,138))
		-- for i = 0, math.ceil(fill) do
			-- if i > math.ceil(fill)-3 then
				-- surface.SetMaterial(edgelarge)
				-- surface.SetDrawColor(barcolors[math.min(i+1,#barcolors)])
				-- local sum = fill
				-- if usechip then
					-- if !chip then chip = 0 end
					-- sum = fill-chip
				-- end
				-- surface.DrawTexturedRect(x, y, 2, 34)
				-- surface.DrawTexturedRect(x + math.min(math.max((length*(sum-i)),0),length), y, 2, 34)
				-- surface.SetMaterial(filllarge)
				-- surface.DrawTexturedRect(x+2, y, math.min(math.max(0,(length*(fill-i))-2),length-2), 34)
				-- if usechip then
					-- render.SetScissorRect(x, y, x + length, y + 34, true)
					-- surface.SetDrawColor(Color(58,58,58))
					-- surface.DrawTexturedRect(x+(length*(fill-i)), y, math.min(math.max(0,(length*-chip)),length), 34)
					-- render.SetScissorRect(0,0,0,0,false)
				-- end
			-- end
		-- end
-- end

--BarText : Draws text on the screen, but also gives it the functionality of a bar, like health or progress bars.
function draw.BarText(text,font,x,y,color,emptycolor,outline,emptyoutline,fill,usechip,chip,chipcolor,chipoutline)
	surface.SetFont(font)
	local textwidth,textheight = surface.GetTextSize(text)
	draw.SimpleTextOutlined(text, font, x, y, emptycolor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, emptyoutline)
	local filla = fill
	local fillb = chip
	if usechip and fillb < filla then
		filla = chip
		fillb = fill
	end
	if usechip then
		render.SetScissorRect(x-6, y, x + ((textwidth + 6)*fillb), y + textheight, true)
			draw.SimpleTextOutlined(text, font, x, y, chipcolor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, chipoutline)
		render.SetScissorRect(0,0,0,0,false)
	end
	render.SetScissorRect(x-6, y, x + ((textwidth + 6)*filla), y + textheight, true)
		draw.SimpleTextOutlined(text, font, x, y, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, outline)
	render.SetScissorRect(0,0,0,0,false)
end

chalk_number0 = Material("rf/number_0.png")
chalk_number1 = Material("rf/number_1.png")
chalk_number2 = Material("rf/number_2.png")
chalk_number3 = Material("rf/number_3.png")
chalk_number4 = Material("rf/number_4.png")
chalk_number5 = Material("rf/number_5.png")
chalk_number6 = Material("rf/number_6.png")
chalk_number7 = Material("rf/number_7.png")
chalk_number8 = Material("rf/number_8.png")
chalk_number9 = Material("rf/number_9.png")
chalk_tally1 = Material("rf/tally_1.png")
chalk_tally2 = Material("rf/tally_2.png")
chalk_tally3 = Material("rf/tally_3.png")
chalk_tally4 = Material("rf/tally_4.png")
chalk_tally5 = Material("rf/tally_5.png")

function ChalkPNG(value, tally) -- can't ".." userdata
	if tally == nil then tally = false end
	if tally then
		if value == 1 then
			return chalk_tally1
		elseif value == 2 then
			return chalk_tally2
		elseif value == 3 then
			return chalk_tally3
		elseif value == 4 then
			return chalk_tally4
		elseif value == 5 then
			return chalk_tally5
		end
	else
		if value == 0 then
			return chalk_number0
		elseif value == 1 then
			return chalk_number1
		elseif value == 2 then
			return chalk_number2
		elseif value == 3 then
			return chalk_number3
		elseif value == 4 then
			return chalk_number4
		elseif value == 5 then
			return chalk_number5
		elseif value == 6 then
			return chalk_number6
		elseif value == 7 then
			return chalk_number7
		elseif value == 8 then
			return chalk_number8
		elseif value == 9 then
			return chalk_number9
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

function DrawChalk(str, size, x, y, col, slant, tally, burnin, cut)
	if slant == nil then slant = 0 end
	if cut == nil then cut = 0 end
	if burnin == nil then burnin = 1 end
	if tally == nil then tally = false end
	if tally then
		width = size
	else
		width = size/2
	end
	cutscale = size/128
	str = string.Replace(tostring(str), ",", "")
	if tally then str = string.sub(str, 1, 1) end
	col = Color(col.r+(2.55*burnin),col.g+(2.55*burnin),col.b+(2.55*burnin),col.a)
	for i = 1, string.len(str) do
		local acceptedstrings = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" }
		local invalid = true
		for c = 1, #acceptedstrings do
			if tostring(string.sub(str,i,i)) == acceptedstrings[c] then
				invalid = false
			end
		end
		if !invalid then
			surface.SetMaterial(ChalkPNG(tonumber(string.sub(str,i,i)), tally))
			surface.SetDrawColor(col)
			surface.DrawPartialTexturedRect(x + (width*(i-1)/2), y + (slant*(i-1)), width, size-(cut*cutscale),0,0,width,size-(cut*cutscale),width,size)
		end
	end
end

function string.squash(number, nodecimals, maxterm)
	if !maxterm then maxterm = 102 end
	maxterm = math.min(102, maxterm)
	if !isnumber(number) then return 0 end
	number = math.Round(number)
	local value = number
	local term = {"Kilo", "Million", "Billion", "Trillion", "Quadrillion", "Quintillion", "Sextillion", "Septillion", "Octillion", "Nonillion", "Decillion", "Undecillion","Duodecillion","Tresdecillion","Quattuordecillion","Quinquadecillion","Sedecillion","Septendecillion","Octodecillion","Novendecillion","Vigintillion","Unvigintillion","Duovigintillion","Tresvigintillion","Quattuorvigintillion","Quinquadvigintillion","Sesvigintillion","Septemvigintillion","Octovigintillion","Novemvigintillion","Trigintillion","Untrigintillion","Duotrigintillion", "Trestrigintillion","Quattuortrigintillion","Quinquadtrigintillion","Sestrigintillion","Septentrigintillion","Octotrigintillion","Noventrigintillion","Quadragintillion","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","za","zb","zc","zd","ze","zf","zg","zh","zi","zj","zk","zl","zm","zn","zo","zp","zq","zr","zs","zt","zu","zv","zw","zx","zy","zz","zza","zzb","zzc","zzd","zze","zzf","zzg","zzh","zzi","zzj","zzk","zzl","zzm","zzn","zzo","zzp","zzq","zzr","zzs","zzt","zzu","zzv","zzw","zzx","zzy","zzz", "λ", "δ", "α", "β", "Σ", "θ", "η", "ω", "Ω", "ε"}
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
	elseif number >= 10^5 then
		return math.Round(value, 2) .. selected_term
	else
		return string.Comma(number)
	end
end

function math.Point2Ang(Point1, Point2,radians) 
/* Defines angle between 2 points. 
math.AngleDifference() possible alternative, but I need possitions, not angles. 
Source: Math
*/
local xDifference = Point2:GetPos().x - Point1:GetPos().x 
local yDifference = Point2:GetPos().y - Point1:GetPos().y 
 if radians == true then 
    return math.atan2(yDifference, xDifference) --radians
 else   
    return math.atan2(yDifference, xDifference) * (180 / math.pi) -- degrees
 end
end

/* math.Distance() alternative 
 Defines distance between 2 points.  
Source: Math
function math.Point2Pos(Point1, Point2) 
local xDifference = Point1:GetPos().x - Point2:GetPos().x 
local yDifference = Point1:GetPos().y - Point2:GetPos().y 
 return math.sqrt(math.exp(xDifference)+math.exp(yDifference))
end  */

function math.MinMaxClamp(Min, Max, Arg) 
/* Similar to math.Clamp. 
math.Clamp() alternative but it's not working right 
Source: Math
*/
if Min > Arg then 
return Min
elseif Max < Arg then 
return Max 
else
return Arg
end
end

local numbers = { 1, 5, 10, 50, 100, 500, 1000 }
local chars = { "I", "V", "X", "L", "C", "D", "M" }

local RomanNumerals = { }

function GetArtifactQuantity(ply, artifact)
	if !IsValid(ply) then return 0 end
	if !ply:IsPlayer() then return 0 end
	if !artifact or !isstring(artifact) then return 0 end
	return ply:GetNWInt(artifact .. "_quantity", 0)
end

function HasArtifact(ply, artifact)
	if !IsValid(ply) then return false end
	if !ply:IsPlayer() then return false end
	if !artifact or !isstring(artifact) then return false end
	return ply:GetNWBool(artifact, false)
end

function ShortenNumber(number)
	number = tonumber(number)
	if number == math.huge then return "∞" end
	if not number or number != number then return "???" end
	number = math.ceil(number)
	if number > 999999999999999999999999 then
		number = string.sub(string.Comma(number), 1, 3) .. " Septillion"
	elseif number > 999999999999999999999 then
		number = string.sub(string.Comma(number), 1, 3) .. " Sextillion"
	elseif number > 999999999999999999 then
		number = string.sub(string.Comma(number), 1, 3) .. " Quintillion"
	elseif number > 999999999999999 then
		number = string.sub(string.Comma(number), 1, 3) .. " Quadrillion"
	elseif number > 999999999999 then
		number = string.sub(string.Comma(number), 1, 3) .. " Trillion"
	elseif number > 999999999 then
		number = string.sub(number, 1, 3) / 100 .. " Billion"
	elseif number > 99999999 then
		number = string.sub(number, 1, 5) / 100 .. " Million"
	elseif number > 9999999 then
		number = string.sub(number, 1, 4) / 100 .. " Million"
	elseif number > 999999 then
		number = string.sub(number, 1, 3) / 100 .. " Million"
	elseif number > 99999 then
		number = string.sub(number, 1, 4) / 10 .. " Kilo"
	else
		number = number
	end
	return number
end

function draw.ToRomanNumerals(s)
    s = tonumber(s)
    if not s or s ~= s then error"Unable to convert to number" end
    if s == math.huge then error"Unable to convert infinity" end
    s = math.floor(s)
    if s <= 0 then return s end
	local ret = ""
        for i = #numbers, 1, -1 do
        local num = numbers[i]
        while s - num >= 0 and s > 0 do
            ret = ret .. chars[i]
            s = s - num
        end
        --for j = i - 1, 1, -1 do
        for j = 1, i - 1 do
            local n2 = numbers[j]
            if s - (num - n2) >= 0 and s < num and s > 0 and num - n2 ~= n2 then
                ret = ret .. chars[j] .. chars[i]
                s = s - (num - n2)
                break
            end
        end
    end
    return ret
end

function draw.ToNumber(s)
    s = s:upper()
    local ret = 0
    local i = 1
    while i <= s:len() do
    --for i = 1, s:len() do
        local c = s:sub(i, i)
        if c ~= " " then -- allow spaces
            local m = map[c] or error("Unknown Roman Numeral '" .. c .. "'")
            
            local next = s:sub(i + 1, i + 1)
            local nextm = map[next]
            
            if next and nextm then
                if nextm > m then 
                -- if string[i] < string[i + 1] then result += string[i + 1] - string[i]
                -- This is used instead of programming in IV = 4, IX = 9, etc, because it is
                -- more flexible and possibly more efficient
                    ret = ret + (nextm - m)
                    i = i + 1
                else
                    ret = ret + m
                end
            else
                ret = ret + m
            end
        end
        i = i + 1
    end
    return ret
end