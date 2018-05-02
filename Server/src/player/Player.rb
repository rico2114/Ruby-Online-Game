require_relative "Position"
require_relative "../network/Packet"
require 'thread'

class Player

	def initialize(name, x, y, sess)
		@username = name
		@position = Position.new(x, y)
		@session = sess;
		@incomingPackets = Queue.new
		@mutex = Mutex.new
		@incomingPacketId = -1
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
					# Devuelvo lo mismo solo para que se mueva
					@session.puts(packet.packetId().to_s)
					@session.puts(direction.to_s)
				end
			end
		}
	end

	def process()
		processQueuedPackets()
	end

	def username()
		@username
	end

	def incomingPacketId=(id)
		@incomingPacketId = id
	end

	def incomingPacketId()
		@incomingPacketId
	end

end
