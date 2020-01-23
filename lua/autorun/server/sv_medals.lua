util.AddNetworkString( "AddHaloMedal" )

function medal( ply, medal, score )
	net.Start( "AddHaloMedal" )
		net.WriteString( medal )
		net.WriteInt( score or 0, 32 )
	net.Send( ply )
end