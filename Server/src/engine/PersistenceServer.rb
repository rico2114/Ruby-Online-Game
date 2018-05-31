require "socket"

class PersistenceServer

	def initialize(ip, port, path_)
		@server = TCPServer.open(ip, port)
		@@path = path_
	end

	def start()
		Thread.new{run()}
	end

	def run()
		loop {
			Thread.start(@server.accept) do | session |
				action = session.gets.chomp
				if action == "REGISTER"
					connectedFromPort = session.gets.chomp
					puts("El servidor con el puerto: " + connectedFromPort + " se conecto exitosamente a la red de persistencia!")
					Thread.new{handleOutgoingPing(session)}
					handleNetwork(session, connectedFromPort)
				end
			end
		}
	end

	def handleOutgoingPing(session)
		loop {
			begin
				session.puts("PING")
				# Todo: Estar seguro si este ping si sincroniza bien? Deberia pero toma mas timepo al pers server darse cuenta que se cae algo
				# Subire como max a 4? tal vez?
				# BEWARE HOTCHANGED THIS
				sleep(5)
			rescue
				Thread.exit
				return
			end
		}
	end

	def handleNetwork(session, port)
		loop {
			begin
				username = session.gets.chomp
				modelId = session.gets.chomp
				File.write(@@path + username + ".txt", "model_id:" + modelId + "\n")
				puts("Llego del puerto " + port + " persistencia del jugador: " + username + ".")
			rescue
				puts("El servidor con el puerto: " + port + " se desconecto de la red de persistencia.")
				Thread.exit
				return
			end
		}
	end
end