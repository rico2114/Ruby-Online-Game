require 'gosu'
require_relative "../network/Socket"

class Window < Gosu::Window

	def initialize()
		super 640, 480
		self.caption = "Tutorial Game"
	end

	def update()
		puts("UPDATE!")
	end

	def draw()
		# Draw scene
	end
end

