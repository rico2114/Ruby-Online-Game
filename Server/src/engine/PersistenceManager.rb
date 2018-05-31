require 'timeout'
require "socket"

require_relative "../player/Player"

class PersistenceManager

	def initialize(address, ports, localPort_)
		@gameAddress = address
		@persistenceServerPorts = ports
		@localPort = localPort_
		generateQueues()
		@sockets = []
		@indexMutex = Mutex.new

		generateConnectionEstability()
		Thread.new{processQueues()}
	end

	def generateConnectionEstability()
		#i = @gameAddress.length() - 1
		#while i >= 0
			#puts("PRE I: " + i.to_s)
			#Thread.new{detectConnectionShutdown(i)}
			#i -= 1
		#end
		# BEWARE THAT CODE PRODUCES AND I OUT OF SYNC NOT SURE HOW TO SYNC IT
		Thread.new{detectConnectionShutdown(0)}
		Thread.new{detectConnectionShutdown(1)}
	end

	def detectConnectionShutdown(i)
		timeOut = 5
		loop {
			# Only if the socket is alive keep parsing pings until is not alive
			if @sockets[i] != nil
				begin
					Timeout::timeout(timeOut + 5) do
						# Ping message
						if @sockets[i] != nil
							@sockets[i].gets.chomp
						end
					end
				rescue
					puts "[CONEXION CAIDA] La conexion con el servidor de persistencia " + @gameAddress[i] + ":" + @persistenceServerPorts[i].to_s + " fallo."
					@sockets[i] = nil
				end
			end

			# If it is not alive then attempt to set it back online
			if @sockets[i] == nil
				@sockets[i] = establishConnection(@gameAddress[i], @persistenceServerPorts[i])
				if @sockets[i] == nil
					puts("[CONEXION FALLIDA] Intentandose conectar con el servidor de persistencia en la direccion " + @gameAddress[i] + ":" + @persistenceServerPorts[i].to_s + ". Resulado: FALLO")
				else
					@sockets[i].puts("REGISTER")
					@sockets[i].puts(@localPort)
					puts("[CONEXION EXITOSA] Intentandose conectar con el servidor de persistencia en la direccion " + @gameAddress[i] + ":" + @persistenceServerPorts[i].to_s + ". Resulado: EXITOSO")
				end
			end
			# Sleep timeOut seconds
			sleep(timeOut)
		}
	end

	def processQueues()
		loop {
			i = @queues.length() - 1
			while i >= 0
				player = nil
				begin
					if @sockets[i] != nil and @queues[i].length() > 0 
						player = @queues[i].pop()

						@sockets[i].puts(player.username())
						@sockets[i].puts(player.modelId())
					end
				rescue
					# Just in case it takes too much time to check whether the other server went down
					if player != nil
						@queues[i].push(player)
					end
				end
				i -= 1
			end
			sleep(5)
		}
	end

	def addToQueues(player)
		puts("Added player " + player.username() +  " to the queues.")
		i = @queues.length() - 1
		while i >= 0
			@queues[i].push(player)
			i -= 1
		end
	end	

	def establishConnection(address, port)
		socket = TCPSocket.open(address, port)
		rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT => e
			socket = nil
		return socket
	end

	# Generates the requested store for every other world server because
	# All persistence servers can have different queues
	def generateQueues()
		@queues = []
		i = @gameAddress.length() - 1
		while i >= 0
			@queues.push(Queue.new)
			i -= 1
		end
	end	
end