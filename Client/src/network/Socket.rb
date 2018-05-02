require 'socket'
require 'thread'

class Socket

	def initialize(_socket)
		@socket = _socket
		# Sincronizacion local
		@mutex = Mutex.new


		@writeOffset = 0
		@flushOffset = 0
		@outputBuffer = []

		@readOffset = 0
		@incomingDataOffset = 0
		@inputData = []
	end

	def write(data)
		@outputBuffer[@writeOffset] = data
		@writeOffset += 1
	end

	def availableData()
		return @incomingDataOffset - @readOffset
	end

	# Async reading
	def read()
		if @readOffset >= @incomingDataOffset
			puts("[Error] Attempting to read unavailable data.")
		end
		# Sincronizacion para evitar que el hilo nuevo dañe datos
		@mutex.synchronize {
			@readOffset += 1
			return @inputData[@readOffset - 1]
		}
	end

	def addData(data)
		# Sincronizacion para evitar que el hilo nuevo dañe datos
		@mutex.synchronize {
			@inputData[@incomingDataOffset] = data
			@incomingDataOffset += 1
		}
	end

	def blockingRead()
		return @socket.gets.chomp
	end

	def flush()
		while @flushOffset < @writeOffset do
			@socket.puts(@outputBuffer[@flushOffset])
			@flushOffset += 1
		end
	end
end