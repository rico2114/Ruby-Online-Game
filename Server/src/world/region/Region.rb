require_relative "../../player/Player"

class Region

	def initialize(regionId)
		@id = regionId
		@players = []
	end

	def addPlayer(player)
		@players.push(player)
	end

	def removePlayer(player)
		@players.delete(player)
	end

	def players()
		@players
	end

end