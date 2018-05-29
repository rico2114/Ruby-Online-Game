class Player

	def initialize(username_, x_, y_)
		@username = username_
		@x = x_
		@y = y_
		@active = false
		@modelId = 1
	end

	def move(dx, dy)
		@x += dx
		@y += dy
	end

	def username()
		@username
	end

	def setModelId(id)
		@modelId = id
	end

	def modelId()
		@modelId
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