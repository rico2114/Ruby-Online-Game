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
		@@path = "../../chars_" + port.to_s + "/"
		gameThread = Thread.new{handleWorld()}

		puts("Running game in world " + port.to_s + ".")
	end

	def run
		loop {

			Thread.start(@server.accept) do | session |
					action = session.gets.chomp
					# Active connection
					if action == "LOGIN"
						if session.gets.chomp == "ACKNOWLEDGE"
							player = Player.new(session.gets.chomp, 30, 30, session)
							session.puts("OK")
							@@PlayingSessionMutex.synchronize {
								@@PlayingSession.store(session, player)
							}

							# Check if the persistence file related to the player exists
							path = @@path + player.username() + ".txt"
							if File.file?(path)
								player.setModelId(Integer(File.read(path).chomp.split(":")[1]))
							end

							puts("Bienvenido jugador " + player.username() + ".")
							handleNetwork(session, player)
						end

					# Passive connection
					elsif action == "PERSISTENCE"
						username = session.gets.chomp
						modelId = Integer(session.gets.chomp)

						# Try to find if the user is online and replace its value
						@@PlayingSession.each do |session, player|
							if player.username() == username
								player.setModelId(modelId)
							end
						end

						File.write(@@path + username + ".txt", "model_id:" + modelId.to_s + "\n")
						Thread.exit
					end
			end

		}
	end

	def handleNetwork(session, player)
		loop {
			begin
				# Packet parsing process
				incomingPacket = (Integer(session.gets.chomp))
				parsePacket(session, player, incomingPacket)
			rescue
				puts("El jugador " + player.username() + " se ha desconectado.")
				@@PlayingSessionMutex.synchronize {
					player.region().removePlayer(player)
					@@PlayingSession.delete(session)
				}
				Thread.exit
			end
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

			# Synchronize over the players
			@@PlayingSessionMutex.synchronize {
				# Update every configuration before sending the packets
				@@PlayingSession.each do |session, player|
					player.preProcess()
				end

				# Send the update packet
				@@PlayingSession.each do |session, player|
					player.postProcess()
				end
			}

			finish = Time.now.to_f
			
			sleepTime = (cycleRate - (finish - start)) / 1000.0
			#puts("Sleeping for " + (sleepTime * 1000).to_s + " milliseconds.")
			sleep(sleepTime)
		}
	end

end

singleton = ServerSingleton.new("localhost", 43595)
singleton.run()