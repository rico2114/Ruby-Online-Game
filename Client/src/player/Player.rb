class Player

	def initialize(x_, y_)
		@x = x_
		@y = y_
		@active = false
	end

	def move(dx, dy)
		@x += dx
		@y += dy
	end

	def active()
		@active
	end

	def deactivate()
		@active = false
	end

	def activate()
		@active = true
	end

	def x()
		@x
	end

	def y()
		@y
	end

end