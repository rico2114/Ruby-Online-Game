class Packet

	def initialize(opcode)
		@packetId = opcode

		@readOffset = 0
		@incomingDataOffset = 0
		@inputData = []

		@outputData = []
		@lastFlushOffset = 0
		@writeOffset = 0

		# Write the packet opcode
		write(opcode.to_s)
	end

	def flush(session)
		while @lastFlushOffset < @writeOffset
			session.puts(@outputData[@lastFlushOffset])
			@lastFlushOffset += 1
		end
	end

	def write(line)
		@outputData[@writeOffset] = line
		@writeOffset += 1
	end

	def replaceOutputData(index, value)
		@outputData[index] = value
	end

	def outputSize()
		@writeOffset
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

	def packetId()
		@packetId
	end

	def availableData()
		return @incomingDataOffset - @readOffset
	end

end