require_relative "../../player/Position"
require_relative "Region"

class RegionManager
	@@regions = Hash.new

	def initialize()
		# Centro
		regionId = Position.new(0, 0).getRegionId()
		@@regions.store(regionId, Region.new(regionId))
		# 64 tiles a la derecha
		regionId = Position.new(64, 0).getRegionId()
		@@regions.store(regionId, Region.new(regionId))
	end
	
	# El self es para que sea estatico
	def self.regionByPosition(position)
		return @@regions[position.getRegionId()]
	end

end