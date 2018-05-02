require 'gosu'
require_relative "../network/Socket"

class Client < Gosu::Window

	def initialize()
		super 640, 480
		self.caption = "Tutorial Game"
	end

	def load()
		@loginIconX = self.height / 2
		@loginIconY = self.width / 2
		@loginIconScale = 0.3
		@loginIcon = Gosu::Image.new("../../media/loginIcon.png", :tileable => true)
		# 0 login screen, 1 playing screen
		@gameState = 0 
		# Display the screen
		self.show
	end

	# TODO: Beware of this function, check for the @gameState == 0 condition
	# This function provides our incoming packets to be async to avoid blocking the rendering thread
	def handleAsyncInput()
		Thread.new do
			loop {
				# If we quitted the playing scene then we close this thread
				if @gameState == 0
					Thread.exit
					return
				end

				# Otherwise if we still are playing we need to handle async input
				# Add it to the socket
				@socket.addData(@socket.blockingRead())
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
			# Find the size of that packet
			size = -1
			if @upcomingPacket == 0
				size = 1
			end
			# We have enought data to parse that packet
			if size != -1 and @socket.availableData >= size
				# Parse walking
				# TODO: Make a prettier system for parsing the packets
				# Move this to another function
				if @upcomingPacket == 0
					dir = Integer(@socket.read())
					if dir == 0
						@playerX += 5
					end
					if dir == 1
						@playerX -= 5
					end
					if dir == 2
						@playerY -= 5
					end
					if dir == 3
						@playerY += 5
					end
				end
				@upcomingPacket = -1
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

				_socket = establishConnection("localhost", 43594)
				if _socket != nil
					# TODO: Prevenir el spam click del login button!!!
					@socket = Socket.new(_socket)
					@socket.write("ACKNOWLEDGE")
					@socket.write("Juan2114")
					@socket.flush()
					if @socket.blockingRead() == "OK"
						# Habilito el input asincrono para no retrazar el juego
						handleAsyncInput()
						@gameState = 1
						@upcomingPacket = -1
						@playerX = 50
						@playerY = 50
						@playerImage = Gosu::Image.new("../../media/caracter.png", :tileable => true)
						@loginIconScale = 0.1
						puts("Inicio de sesion exitoso.")
					else
						puts("Fallo al iniciar sesion.")
					end
				else
					puts("Main server is offline.")
				end
			end
		end
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
	end

	def draw()
		# Login screen
		if @gameState == 0
			# X, Y, IDK, ScaleX, ScaleY
			@loginIcon.draw(@loginIconX, @loginIconY, 0, @loginIconScale, @loginIconScale)
		else
			# Playing screen
			@playerImage.draw(@playerX, @playerY, 0, @loginIconScale, @loginIconScale)
		end
	end

	# We will need the cursor pointer for simplicity reasons
	def needs_cursor?
		true
	end
end


cliente = Client.new
cliente.load()
