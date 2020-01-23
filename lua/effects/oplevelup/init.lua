

function EFFECT:Init( data )
	
	self.Position = data:GetOrigin()
	local Pos = self.Position
	
	local emitter = ParticleEmitter( Pos )
	
		for i=1, 60 do
		
			local particle = emitter:Add( "particles/flamelet"..math.random( 1, 5 ), Pos)
				particle:SetVelocity( Vector(math.random(-70,70),math.random(-70,70),math.random(-10,10)) )
				particle:SetDieTime( math.Rand( 5, 8 ) )
				particle:SetStartAlpha( math.Rand( 255, 255 ) )
				particle:SetStartSize( math.Rand(40,30) )
				particle:SetEndSize( math.Rand( 5, 0 ) )
				particle:SetRoll( math.Rand( 360,480 ) )
				particle:SetRollDelta( math.Rand( -10, 10 ) )
				particle:SetColor( 255, 0, 0 )
				particle:SetCollide( true ) 
				
				--particle:VelocityDecay( true )	
				
			end
				
			

	emitter:Finish()
	
	local emitter2 = ParticleEmitter( Pos )
	
		for i=10, 30 do
	
	local particle = emitter2:Add( "sprites/animglow02", Pos)
				particle:SetVelocity( Vector(math.random(-140,140),math.random(-140,140),math.random(900,140)) )
				particle:SetDieTime( math.Rand( 1, 3 ) )
				particle:SetStartAlpha( math.Rand( 255, 255 ) )
				particle:SetStartSize( math.Rand(40,20) )
				particle:SetEndSize( math.Rand( 5, 0 ) )
				particle:SetRoll( math.Rand( 360,480 ) )
				particle:SetRollDelta( math.Rand( -10, 10 ) )
				particle:SetColor( math.Rand( 10, 100 ), math.Rand( 10, 150 ), math.Rand( 10, 255 ) )
				particle:SetGravity(Vector(0,0,-1850))
				particle:SetCollide( true ) 
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



