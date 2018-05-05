class Player

	def initialize(x_, y_)
		@x = x_
		@y = y_
	end

	def move(dx, dy)
		@x += dx
		@y += dy
	end

	def x()
		@x
	end

	def y()
		@y
	end

end