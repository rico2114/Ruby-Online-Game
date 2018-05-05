require "socket"
require_relative "../player/Player"
require_relative "../network/Packet"
require_relative "../world/region/RegionManager"

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
					if session.gets.chomp == "ACKNOWLEDGE"
						player = Player.new(session.gets.chomp, 30, 30, session)
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
			direction = Integer(session.gets.chomp)
			packet.addData(direction)
		end
		
		player.addIncomingPacket(packet)
	end

	def handleWorld()
		RegionManager.new
		# Temporarily, change the cycle rate if needed
		cycleRate = 200

		loop {
			start = Time.now.to_f

			# Update every configuration before sending the packets
			@@PlayingSession.each do |session, player|
				player.preProcess()
			end

			# Send the update packet
			@@PlayingSession.each do |session, player|
				player.postProcess()
			end

			finish = Time.now.to_f
			
			sleepTime = (cycleRate - (finish - start)) / 1000.0
			#puts("Sleeping for " + (sleepTime * 1000).to_s + " milliseconds.")
			sleep(sleepTime)
		}
	end

end

singleton = ServerSingleton.new("localhost", 43594)
singleton.run()