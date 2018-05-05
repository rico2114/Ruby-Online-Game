class Position

	def initialize(xCoord, yCoord)
		@x = xCoord
		@y = yCoord
	end

	def translate(newX, newY)
		@x = newX
		@y = newY
	end

	def move(deltaX, deltaY)
		@x = @x + deltaX
		@y = @y + deltaY
	end

	def getRegionX()
		return (@x / 64).floor
	end

	def getRegionY()
		return (@y / 64).floor
	end

	def getRegionId()
		return getRegionX() << 16 | getRegionY()
	end

	def x()
		@x
	end

	def y()
		@y
	end

end

# Objects are mutable by default
#position = Position.new(5, 4)
#position.move(1, 0)
#puts(position.getX())
#puts(position.getY())
#position.translate(0, 0)
#puts(position.getX())
#puts(position.getY())
