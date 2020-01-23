if engine.ActiveGamemode() == "sandbox" then

AddCSLuaFile()
CreateClientConVar("ShieldHalo",0,true,true)
CreateClientConVar("ShieldHalo_vm",0,true,true)

hook.Add( "PreDrawHalos", "AddHalos", function()
	if GetConVarNumber("ShieldHalo_vm") > 0 then LocalPlayer():GetActiveWeapon().ViewModelFOV = math.Clamp(LocalPlayer():GetFOV(),70,90) end
	if LocalPlayer():Alive() and GetConVarNumber("ShieldHalo_vm") > 0 and LocalPlayer():Armor() > 0.2 and LocalPlayer():GetNWFloat("ses.TookHit",0) > 0 and LocalPlayer():GetActiveWeapon():IsScripted() then halo.Add( {LocalPlayer():GetHands()}, Color( 255-(LocalPlayer():Armor()*2.5), LocalPlayer():Armor()+50, (LocalPlayer():Armor()*2.5) ), math.random(0.2*LocalPlayer():GetNWFloat("ses.TookHit",1),1*LocalPlayer():GetNWFloat("ses.TookHit",1)), math.random(0.2*LocalPlayer():GetNWFloat("ses.TookHit",1),1*LocalPlayer():GetNWFloat("ses.TookHit",1)), 40) end
	if LocalPlayer():Alive() and GetConVarNumber("ShieldHalo_vm") > 0 and LocalPlayer():Armor() > 0.2 and LocalPlayer():GetNWFloat("ses.TookHit",0) > 0 and LocalPlayer():GetActiveWeapon():IsScripted() then halo.Add( {LocalPlayer():GetViewModel(0)}, Color( 255-(LocalPlayer():Armor()*2.5), LocalPlayer():Armor()+50, (LocalPlayer():Armor()*2.5) ), math.random(0.2*LocalPlayer():GetNWFloat("ses.TookHit",1),1*LocalPlayer():GetNWFloat("ses.TookHit",1)), math.random(0.2*LocalPlayer():GetNWFloat("ses.TookHit",1),1*LocalPlayer():GetNWFloat("ses.TookHit",1)), 40) end
end)


net.Receive("SES.roller",function() surface.PlaySound('npc/roller/code2.ogg') end)
end
