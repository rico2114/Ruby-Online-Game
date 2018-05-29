require 'gosu'
require_relative "../network/Socket"
require_relative "../player/Player"

class Client < Gosu::Window

	@@availableAddress = ["localhost", "localhost", "localhost"]
	@@availablePorts = [43594, 43595, 43596]
	#@@loginUsername = "Juan2114"
	@@loginUsername = "Test"

	def initialize()
		super 640, 480
		self.caption = "Juego de Redes"
	end

	def load()
		@loginIconX = self.height / 2
		@loginIconY = self.width / 2
		@loginIconScale = 0.3
		@loginIcon = Gosu::Image.new("../../media/loginIcon.png", :tileable => true)
		# 0 login screen, 1 playing screen
		@gameState = 0 
		# Players near me
		@myPlayer = Player.new(@@loginUsername, 30, 30)
		@lastPlayerUpdate = 0
		@gameStateMutex = Mutex.new
		# Display the screen
		self.show
	end

	# TODO: Beware of this function, check for the @gameState == 0 condition
	# This function provides our incoming packets to be async to avoid blocking the rendering thread
	def handleAsyncInput()
		Thread.new do
			loop {
				# If we quitted the playing scene then we close this thread
				@gameStateMutex.synchronize {
					if @gameState == 0 or @socket == nil
						Thread.exit
						return
					end

					# Otherwise if we still are playing we need to handle async input
					# Add it to the socket
					@socket.addData(@socket.blockingRead())	
				}							
			}
		end
	end

	def processIncomingPackets()
		# Only for the playing state
		if @gameState == 1
			# We need to parse the packet id
			if @upcomingPacket == -1 and @socket.availableData() >= 1
				@upcomingPacket = Integer(@socket.read())
			end
			# Player updating packet ... fetch the size
			if @upcomingPacket == 0 and @upcomingPacketSize == -1 and @socket.availableData() >= 1
				@upcomingPacketSize = Integer(@socket.read())
			elsif @upcomingPacket == 1
				@upcomingPacketSize = 1
			end
			# We have enought data to parse that packet
			if @upcomingPacketSize != -1 and @upcomingPacket != -1 and @socket.availableData >= @upcomingPacketSize
				# Player updating packet 
				if @upcomingPacket == 0
					# Note that player updating procedure serves as a ping instruction too because this part is fundamental in the cycle of the game
					# If this fails the whole game fails
					@lastPlayerUpdate = Time.now.to_f
					# Process local player
					localMovement = Integer(@socket.read())
					if localMovement == 1
						dx = Integer(@socket.read())
						dy = Integer(@socket.read())
						@myPlayer.move(dx, dy)
					end

					modelId = Integer(@socket.read())
					if @myPlayer.modelId() != modelId
						@myPlayer.setModelId(modelId)
						dispatchPersistence(modelId)
					end

					# Register & Process surrounding players

					# Mark all players disabled by default and then set them back to active after each process players packet
					for player in @players do
						if player != nil
							player.deactivate()
						end
					end

					# BEWARE: This approach is not the correct way to do it, eventually too many instances of the player class will be hold
					# But they should be nulled on disconection.

					surroundingPlayers = Integer(@socket.read())
					while surroundingPlayers > 0
						idx = Integer(@socket.read())
						username = @socket.read()
						modelId = Integer(@socket.read())
						otherX = Integer(@socket.read())
						otherY = Integer(@socket.read())

						if @players[idx] == nil # OR IF PLAYER IS NOT ACTIVATED IN THE LIST
							@players[idx] = Player.new(username, otherX, otherY)
						else
							# Activate only surrounding players (this sorts deregistrations of players easily)
							@players[idx].activate()
						end

						@players[idx].setModelId(modelId)

						moved = Integer(@socket.read())
						if moved == 1
							dx = Integer(@socket.read())
							dy = Integer(@socket.read())
							@players[idx].move(dx, dy)
						end

						surroundingPlayers -= 1
					end
				elsif @upcomingPacket == 1
					puts(@socket.read())
				end

				@upcomingPacket = -1
				@upcomingPacketSize = -1
			end
		end
	end

	def processKeyboard()
		if @gameState == 1
			# Por ahora el movimiento solo sera un dx enviado al server y el server respondera con la nueva posicion
			# Packet 0 equals movement packet
			# Movimiento a la derecha
			if Gosu.button_down? Gosu::KB_RIGHT
				@socket.write("0")
				@socket.write("0")
			end
			# Movimiento a la izquierda
			if Gosu.button_down? Gosu::KB_LEFT
				@socket.write("0")
				@socket.write("1")
			end
			# Movimiento arriba
			if Gosu.button_down? Gosu::KB_UP
				@socket.write("0")
				@socket.write("2")
			end
			# Movimiento abajo
			if Gosu.button_down? Gosu::KB_DOWN
				@socket.write("0")
				@socket.write("3")
			end

			@socket.flush()

			# Cambio de modelo
			if Gosu.button_down? Gosu::KB_1
				dispatchPersistence(1)
			elsif Gosu.button_down? Gosu::KB_2
				dispatchPersistence(2)
			elsif Gosu.button_down? Gosu::KB_3
				dispatchPersistence(3)
			end
			
		end
	end

	def dispatchPersistence(modelId)
		# New thread to avoid delays on the main thread
		Thread.new do
			i = @@availableAddress.length() - 1
			while i >= 0
				# Passive connection
				socket = establishConnection(@@availableAddress[i], @@availablePorts[i].to_i)

				if socket != nil
					socket.puts("PERSISTENCE")
					socket.puts(@myPlayer.username())
					socket.puts(modelId)
					socket.close()
				end

				i -= 1
			end
		end
	end

	def processMouse()
		@mouseX = self.mouse_x
		@mouseY = self.mouse_y
		#puts("X: " + @mouseX.to_s + " Y: " + @mouseY.to_s)
		if @gameState == 0
			if @mouseX >= @loginIconX and @mouseX <= @loginIconX + (@loginIcon.width * @loginIconScale)\
				and @mouseY >= @loginIconY and @mouseY <= @loginIconY + (@loginIcon.height * @loginIconScale)\
				and button_down?(Gosu::MsLeft)

				login()
			end
		end
	end

	def login()
		_socket = findSuitableServer()
		if _socket != nil
			# TODO: Prevenir el spam click del login button!!!
			@socket = Socket.new(_socket)
			@socket.write("LOGIN")
			@socket.write("ACKNOWLEDGE")
			@socket.write(@@loginUsername)
			@socket.flush()
			if @socket.blockingRead() == "OK"
				# Habilito el input asincrono para no retrazar el juego
				handleAsyncInput()
				@players = []
				@gameState = 1
				@lastPlayerUpdate = -1
				@upcomingPacket = -1
				@upcomingPacketSize = -1

				@playerImage = []
				@playerImage[0] = Gosu::Image.new("../../media/caracter_1.png", :tileable => true)
				@playerImage[1] = Gosu::Image.new("../../media/caracter_2.png", :tileable => true)
				@playerImage[2] = Gosu::Image.new("../../media/caracter_3.png", :tileable => true)

				@loginIconScale = 0.1
				puts("Inicio de sesion exitoso.")
			else
				puts("Fallo al iniciar sesion.")
			end
		else
			puts("Servers are offline.")
		end
	end

	def findSuitableServer()
		i = @@availableAddress.length() - 1
		socket = nil
		while i >= 0 and socket == nil
			socket = establishConnection(@@availableAddress[i], @@availablePorts[i].to_i)
			i -= 1
		end
		return socket
	end

	def establishConnection(address, port)
		socket = TCPSocket.open(address, port)
		rescue Errno::ECONNREFUSED => e
			socket = nil
		return socket
	end

	def update()
		processKeyboard()
		processMouse()
		processIncomingPackets()

		if @gameState == 1 and @lastPlayerUpdate != -1
			# Check for server disconnection
			elapsed = (Time.now.to_f - @lastPlayerUpdate)
			# 3 = 2 server cycles + 1 extra of offset to ensure packets are not actually arriving
			if elapsed > 3
				@gameStateMutex.synchronize {
					@gameState = 0
					@socket.close()
					@socket = nil
				}
				login()
			end
		end
	end

	def draw()
		# Login screen
		if @gameState == 0
			# X, Y, IDK, ScaleX, ScaleY
			@loginIcon.draw(@loginIconX, @loginIconY, 0, @loginIconScale, @loginIconScale)
		else
			# Playing screen
			@playerImage[@myPlayer.modelId() - 1].draw(@myPlayer.x(), @myPlayer.y(), 0, @loginIconScale, @loginIconScale)
			for otherPlayer in @players
				if otherPlayer != nil and otherPlayer.active()
					@playerImage[otherPlayer.modelId() - 1].draw(otherPlayer.x(), otherPlayer.y(), 0, @loginIconScale, @loginIconScale)
				end
			end
		end
	end

	# We will need the cursor pointer for simplicity reasons
	def needs_cursor?
		true
	end
end


cliente = Client.new
cliente.load()