##############################################################################
# TileMapper - Converts noise values to tile types
##############################################################################
#
# PURPOSE:
#   Noise gives us continuous numbers (-1.0 to 1.0), but we need discrete
#   tile types (water, grass, stone, etc.). This class does that conversion!
#
# HOW IT WORKS:
#   Think of it like elevation zones on a mountain:
#   - Below sea level (-1.0 to -0.3) = Water (blue)
#   - Beach level (-0.3 to 0.0) = Sand (yellow)
#   - Low hills (0.0 to 0.4) = Grass (green)
#   - Mountains (0.4 to 0.7) = Stone (gray)
#   - Peaks (0.7 to 1.0) = Snow (white)
#
# USAGE EXAMPLE:
#   var mapper = TileMapper.new()
#   var tile_id = mapper.map_noise_to_tile(0.5)  # Returns STONE (3)
#
##############################################################################

class_name TileMapper

##############################################################################
# TILE TYPE CONSTANTS
##############################################################################
# These numbers match the tile IDs in our TileSet

const WATER: int = 0  # Deep blue - oceans, lakes
const SAND: int = 1   # Yellow - beaches, shores
const GRASS: int = 2  # Green - plains, lowlands
const STONE: int = 3  # Gray - mountains, cliffs
const SNOW: int = 4   # White - mountain peaks

##############################################################################
# THRESHOLD VALUES
##############################################################################
# These determine where one tile type transitions to another
# Must be in ascending order: water_threshold < sand_threshold < grass_threshold < stone_threshold

var water_threshold: float = -0.3  # Below this = water
var sand_threshold: float = 0.0    # Water to sand transition
var grass_threshold: float = 0.4   # Sand to grass transition
var stone_threshold: float = 0.7   # Grass to stone transition
# Above stone_threshold = snow

##############################################################################
# STATISTICS (OPTIONAL)
##############################################################################
# Track how many of each tile type we've created

var _statistics_enabled: bool = false
var _tile_counts: Dictionary = {
	WATER: 0,
	SAND: 0,
	GRASS: 0,
	STONE: 0,
	SNOW: 0
}

##############################################################################
# CONSTRUCTOR
##############################################################################

## Creates a new TileMapper with optional custom thresholds
func _init(
	custom_water: float = -0.3,
	custom_sand: float = 0.0,
	custom_grass: float = 0.4,
	custom_stone: float = 0.7
) -> void:
	water_threshold = custom_water
	sand_threshold = custom_sand
	grass_threshold = custom_grass
	stone_threshold = custom_stone

	# Validate that thresholds are in order
	_validate_thresholds()

##############################################################################
# MAIN MAPPING FUNCTION
##############################################################################

## Converts a noise value to a tile type ID
##
## This is the heart of the terrain generation! It takes a smooth noise value
## and decides what type of terrain should appear at that location.
##
## Parameters:
##   noise_value: A float between -1.0 and 1.0 (from NoiseGenerator)
##
## Returns: An integer tile ID (0-4)
func map_noise_to_tile(noise_value: float) -> int:
	var tile_id: int

	# Check each threshold from lowest to highest
	# Think of this like checking elevation zones on a topographic map
	if noise_value < water_threshold:
		tile_id = WATER
	elif noise_value < sand_threshold:
		tile_id = SAND
	elif noise_value < grass_threshold:
		tile_id = GRASS
	elif noise_value < stone_threshold:
		tile_id = STONE
	else:
		tile_id = SNOW

	# Track statistics if enabled
	if _statistics_enabled:
		_tile_counts[tile_id] += 1

	return tile_id

##############################################################################
# THRESHOLD CONFIGURATION
##############################################################################

## Sets the water threshold (controls ocean size)
##
## Lower values = more water
## Higher values = less water
func set_water_threshold(value: float) -> void:
	water_threshold = value
	_validate_thresholds()

## Sets the sand threshold (controls beach width)
func set_sand_threshold(value: float) -> void:
	sand_threshold = value
	_validate_thresholds()

## Sets the grass threshold (controls grassland extent)
func set_grass_threshold(value: float) -> void:
	grass_threshold = value
	_validate_thresholds()

## Sets the stone threshold (controls mountain height)
func set_stone_threshold(value: float) -> void:
	stone_threshold = value
	_validate_thresholds()

## Sets all thresholds at once from a dictionary
##
## Example: set_thresholds({"water": -0.2, "sand": 0.1, "grass": 0.5, "stone": 0.8})
func set_thresholds(config: Dictionary) -> void:
	if config.has("water"):
		water_threshold = config["water"]
	if config.has("sand"):
		sand_threshold = config["sand"]
	if config.has("grass"):
		grass_threshold = config["grass"]
	if config.has("stone"):
		stone_threshold = config["stone"]

	_validate_thresholds()

##############################################################################
# UTILITY METHODS
##############################################################################

## Gets the human-readable name of a tile type
##
## Example: get_tile_name(GRASS) returns "Grass"
func get_tile_name(tile_id: int) -> String:
	match tile_id:
		WATER:
			return "Water"
		SAND:
			return "Sand"
		GRASS:
			return "Grass"
		STONE:
			return "Stone"
		SNOW:
			return "Snow"
		_:
			return "Unknown"

## Returns the total number of tile types supported
func get_tile_type_count() -> int:
	return 5

##############################################################################
# STATISTICS METHODS
##############################################################################

## Enables tracking of how many of each tile type is created
##
## Useful for debugging and balancing your terrain generation
func enable_statistics() -> void:
	_statistics_enabled = true
	reset_statistics()

## Disables statistics tracking
func disable_statistics() -> void:
	_statistics_enabled = false

## Gets the distribution of tile types as a dictionary
##
## Returns: Dictionary with counts like {"Water": 1000, "Grass": 5000, ...}
func get_tile_distribution() -> Dictionary:
	return {
		"Water": _tile_counts[WATER],
		"Sand": _tile_counts[SAND],
		"Grass": _tile_counts[GRASS],
		"Stone": _tile_counts[STONE],
		"Snow": _tile_counts[SNOW]
	}

## Gets the distribution as percentages
##
## Returns: Dictionary with percentages like {"Water": 25.5, "Grass": 48.2, ...}
func get_tile_distribution_percent() -> Dictionary:
	var total: int = 0
	for count in _tile_counts.values():
		total += count

	if total == 0:
		return {
			"Water": 0.0, "Sand": 0.0, "Grass": 0.0,
			"Stone": 0.0, "Snow": 0.0
		}

	return {
		"Water": (_tile_counts[WATER] * 100.0) / total,
		"Sand": (_tile_counts[SAND] * 100.0) / total,
		"Grass": (_tile_counts[GRASS] * 100.0) / total,
		"Stone": (_tile_counts[STONE] * 100.0) / total,
		"Snow": (_tile_counts[SNOW] * 100.0) / total
	}

## Resets all statistics counters to zero
func reset_statistics() -> void:
	_tile_counts = {
		WATER: 0,
		SAND: 0,
		GRASS: 0,
		STONE: 0,
		SNOW: 0
	}

##############################################################################
# VALIDATION
##############################################################################

## Checks that thresholds are in ascending order
##
## If they're out of order, terrain generation will produce weird results!
func _validate_thresholds() -> void:
	var is_valid: bool = true

	if water_threshold >= sand_threshold:
		push_warning("TileMapper: water_threshold should be < sand_threshold")
		is_valid = false

	if sand_threshold >= grass_threshold:
		push_warning("TileMapper: sand_threshold should be < grass_threshold")
		is_valid = false

	if grass_threshold >= stone_threshold:
		push_warning("TileMapper: grass_threshold should be < stone_threshold")
		is_valid = false

	if is_valid:
		# Optional: print confirmation in debug builds
		pass  # print("TileMapper: Thresholds validated successfully")
