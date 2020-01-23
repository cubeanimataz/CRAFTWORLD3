

function EFFECT:Init( data )
	
	self.Position = data:GetOrigin()
	self.Armor = data:GetEntity():Armor()
	local Pos = self.Position
	

	
		
			
				
			


	
	local emitter2 = ParticleEmitter( Pos )
	
		for i=1, 2 do
	
				local particle = emitter2:Add( "sprites/shieldhex", Pos+Vector(math.Rand(-20,20),math.Rand(-20,20),math.Rand(-5,40)) )
				particle:SetVelocity( Vector(math.random(-40,40),math.random(-40,40),math.random(0,40)) )
				particle:SetDieTime( math.Rand( 0.3, 0.5 ) )
				particle:SetStartAlpha( math.Rand( 255, 255 ) )
				particle:SetStartSize( math.Rand(0.2,0.6) )
				particle:SetEndSize( 0 )
				particle:SetRoll( math.Rand( 360,480 ) )
				particle:SetRollDelta( math.Rand( -10, 10 ) )
				particle:SetColor( 255-(self.Armor*2.5),self.Armor*2.5 ,self.Armor*2.5,255 )

				particle:SetGravity(Vector(0,0,0))
				particle:SetCollide( false ) 
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



