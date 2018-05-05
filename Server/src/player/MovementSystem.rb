require_relative "Player"

class MovementSystem

	def initialize(player)
		@player = player
		@queue = Queue.new
		@requiredMovement = false
		@lastDx = -1
		@lastDy = -1
	end

	def addMovement(dx, dy)
		@queue.push([dx, dy])
	end

	def processMovement()
		# No debe estar vacia
		@requiredMovement = false
		@lastDx = -1
		@lastDy = -1
		if @queue.size() > 0
			movement = @queue.pop(true);
			@lastDx = movement[0]
			@lastDy = movement[1]
			@requiredMovement = true
			@player.position().move(@lastDx, @lastDy)
		end
	end

	def lastDx()
		@lastDx
	end

	def lastDy()
		@lastDy
	end

	def requiredMovement()
		@requiredMovement
	end

end