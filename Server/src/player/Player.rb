require_relative "Position"
require_relative "MovementSystem"

require_relative "../network/Packet"
require_relative "../world/region/RegionManager"
require_relative "../world/region/Region"

require 'thread'

class Player
	# Identifies the player id (static id carrying the count)
	@@id = 0

	def initialize(name, x, y, sess, persManagerRef)
		@id = @@id
		@username = name
		@position = Position.new(x, y)
		@persistenceManagerReference = persManagerRef
		@modelId = 1
		@session = sess;
		@incomingPackets = Queue.new
		@movementSystem = MovementSystem.new(self)

		# TODO: CHANGE THIS MAKE THIS ACTUALLY BE USED WHEN MOVING SO WE CHANGE REGIONS
		@region = RegionManager.regionByPosition(@position)
		@region.addPlayer(self)
		
		@mutex = Mutex.new
		@@id += 1
	end

	def addIncomingPacket(packet)
		@mutex.synchronize {
			@incomingPackets.push(packet)
		}
	end

	def processQueuedPackets()
		@mutex.synchronize {
			while @incomingPackets.length() > 0
				packet = @incomingPackets.pop(true)
				# Movement
				if packet.packetId() == 0
					direction = packet.read()
					multiplier = 20
					# Movement in x
					if direction == 0
						@movementSystem.addMovement(multiplier, 0)
					elsif direction == 1
						@movementSystem.addMovement(-multiplier, 0)
					elsif direction == 2
						@movementSystem.addMovement(0, -multiplier)
					elsif direction == 3
						@movementSystem.addMovement(0, +multiplier)						
					end
				elsif packet.packetId() == 1
					modelId = packet.read()
					setModelId(modelId)
					@persistenceManagerReference.addToQueues(self)
				end
			end
		}
	end


	def processOtherPlayers(updatePacket)
		# Players in region size minus myself
		updatePacket.write(@region.players().size() - 1)
		# For each one of them...
		for player in @region.players()
			if player.id() != id()
				# Solo procesaremos jugadores que esten en nuestra region
				updatePacket.write(player.id().to_s)
				updatePacket.write(player.username())
				updatePacket.write(player.modelId().to_s)

				# Send the position TODO: CACHE PLAYERS IN THE REGION SO WE AVOID RE SENDING POSITIONS
				updatePacket.write(player.position().x().to_s)
				updatePacket.write(player.position().y().to_s)

				# Procesamos el movimiento del otro
				processPlayerMovement(player, updatePacket)
			end
		end
	end

	def processPlayerMovement(player, updatePacket)
		# Paquete de procesamiento del personaje
		if player.movementSystem().requiredMovement()
			# 1 denota que si se movio el personaje
			updatePacket.write("1")
			updatePacket.write(player.movementSystem().lastDx().to_s)
			updatePacket.write(player.movementSystem().lastDy().to_s)
		else
			# 0 denota que no se movio el personaje
			updatePacket.write("0")
		end
	end

	def preProcess()
		# Actions previous to the player updating packet dispatch
		processQueuedPackets()
		@movementSystem.processMovement()
	end

	def postProcess()
		# Process players packet
		updatePacket = Packet.new(0)
		updatePacket.write("-1") # Temporarily for the packet size
		processPlayerMovement(self, updatePacket)

		# Write the model id
		updatePacket.write(modelId().to_s)

		# Process combat?
		# Process actions
		processOtherPlayers(updatePacket)

		# Update the packet size
		updatePacket.replaceOutputData(1, updatePacket.outputSize())
		# Flush
		updatePacket.flush(@session)
	end

	def region()
		@region
	end

	def movementSystem()
		@movementSystem
	end

	def id()
		@id
	end

	def modelId()
		@modelId
	end

	def setModelId(id)
		@modelId = id
	end

	def position()
		@position
	end

	def username()
		@username
	end
	
end
