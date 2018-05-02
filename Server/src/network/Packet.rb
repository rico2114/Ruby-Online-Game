class Packet

	def initialize(opcode)
		@packetId = opcode
		@readOffset = 0
		@incomingDataOffset = 0
		@inputData = []
	end

	def packetId()
		@packetId
	end

	def availableData()
		return @incomingDataOffset - @readOffset
	end

	def read()
		if @readOffset >= @incomingDataOffset
			puts("[Error] Attempting to read unavailable data.")
		end
		@readOffset += 1
		return @inputData[@readOffset - 1]
	end

	def addData(data)
		@inputData[@incomingDataOffset] = data
		@incomingDataOffset += 1
	end

end