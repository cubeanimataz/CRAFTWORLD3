

function EFFECT:Init( data )
	
	self.Position = data:GetOrigin()
	self.Armor = data:GetEntity():Armor()
	local Pos = self.Position
	

	
		
			
				
			


	
	local emitter2 = ParticleEmitter( Pos )
	
		for i=3, 8 do
	
				local particle = emitter2:Add( "sprites/shieldhex", Pos)
				particle:SetVelocity( Vector(math.random(-140,140),math.random(-140,140),math.random(500,140)) )
				particle:SetDieTime( math.Rand( 1, 3 ) )
				particle:SetStartAlpha( math.Rand( 255, 255 ) )
				particle:SetStartSize( math.Rand(4,8) )
				particle:SetEndSize( math.Rand( 0, 0 ) )
				particle:SetRoll( math.Rand( 360,480 ) )
				particle:SetRollDelta( math.Rand( -10, 10 ) )
				particle:SetColor( 255-(self.Armor*2.5),self.Armor*2.5 ,self.Armor*2.5,255 )
				particle:SetGravity(Vector(0,0,-1000))
				particle:SetCollide( true ) 
				particle:SetBounce(0.5)
				--particle:VelocityDecay( false )	
				
			end
		
	emitter2:Finish()
end


function EFFECT:Think( )

return false
		
end


function EFFECT:Render()
	-- Do nothing - this effect is only used to spawn the particles in Init
end



