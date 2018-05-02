require "socket"
require_relative "../player/Player"
require_relative "../network/Packet"

class ServerSingleton
	# List of all the players registered
	@@PlayingSession = Hash.new
	@@PlayingSessionMutex = Mutex.new

	def initialize(ip, port)
		@server = TCPServer.open(ip, port)
		gameThread = Thread.new{handleWorld()}
		puts("Running game in world " + port.to_s + ".")
	end

	def run
		loop {

			Thread.start(@server.accept) do | session |
					if session.gets.chomp  == "ACKNOWLEDGE"
						player = Player.new(session.gets.chomp, 0, 0, session)
						session.puts("OK")
						@@PlayingSession.store(session, player)
						puts("Bienvenido jugador " + player.username() + ".")
						handleNetwork(session, player)
					end
			end

		}
	end

	def handleNetwork(session, player)
		loop {
				# Packet parsing process
				incomingPacket = (Integer(session.gets.chomp))
				parsePacket(session, player, incomingPacket)
		}
	end

	def parsePacket(session, player, packetId)
		packet = Packet.new(packetId)
		# Movement packet
		if packet.packetId() == 0
			direction = session.gets.chomp
			packet.addData(direction)
		end
		
		player.addIncomingPacket(packet)
	end

	def handleWorld()
		loop {
			start = Time.now.to_f

			@@PlayingSession.each do |session, player|
				player.process()
			end

			finish = Time.now.to_f
			
			sleepTime = (600 - (finish - start)) / 1000.0
			#puts("Sleeping for " + (sleepTime * 1000).to_s + " milliseconds.")
			sleep(sleepTime)
		}
	end

end

singleton = ServerSingleton.new("localhost", 43594)
singleton.run()