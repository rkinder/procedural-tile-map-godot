##############################################################################
# MapGenerator - The main orchestrator for procedural terrain generation
##############################################################################
#
# PURPOSE:
#   This is the "conductor" of our terrain generation orchestra! It brings
#   together the NoiseGenerator and TileMapper to create complete tile maps.
#
# HOW IT WORKS:
#   1. Creates a NoiseGenerator with your chosen seed and settings
#   2. Creates a TileMapper with your threshold settings
#   3. Loops through every tile position in the map
#   4. Asks NoiseGenerator for a noise value at that position
#   5. Asks TileMapper to convert that noise to a tile type
#   6. Places the tile in the TileMap
#
# USAGE:
#   1. Add this script to a Node in your scene
#   2. Set the TileMap node path
#   3. Configure the exported variables in the Inspector
#   4. Run the scene - it will auto-generate if auto_generate is true!
#
##############################################################################

extends Node
class_name MapGenerator

##############################################################################
# EXPORTED VARIABLES (Editable in Godot Inspector)
##############################################################################

## Map dimensions
@export_group("Map Settings")
@export_range(1, 2048) var map_width: int = 512
@export_range(1, 2048) var map_height: int = 512

## Random seed for generation (0 = use random seed)
@export var random_seed: int = 0

## Should the map generate automatically when the scene starts?
@export var auto_generate: bool = true

## Noise configuration
@export_group("Noise Settings")
@export_enum("Simplex", "Perlin", "Cellular") var noise_type_name: String = "Simplex"
@export_range(0.001, 0.1) var noise_frequency: float = 0.01
@export_range(1, 8) var noise_octaves: int = 3
@export_range(0.0, 1.0) var noise_fractal_gain: float = 0.5

## Tile mapping thresholds
@export_group("Terrain Thresholds")
@export_range(-1.0, 1.0) var water_threshold: float = -0.3
@export_range(-1.0, 1.0) var sand_threshold: float = 0.0
@export_range(-1.0, 1.0) var grass_threshold: float = 0.4
@export_range(-1.0, 1.0) var stone_threshold: float = 0.7

## Debug and statistics
@export_group("Debug")
@export var debug_timing: bool = false
@export var show_statistics: bool = false

## Reference to the TileMap node
@export_group("Node References")
@export var tile_map_path: NodePath
var tile_map: TileMap

##############################################################################
# SIGNALS
##############################################################################

## Emitted when map generation completes
signal map_generated(width: int, height: int, time_ms: float, seed_used: int)

##############################################################################
# INTERNAL STATE
##############################################################################

var _noise_generator: NoiseGenerator
var _tile_mapper: TileMapper

##############################################################################
# LIFECYCLE METHODS
##############################################################################

func _ready() -> void:
	# Get reference to the TileMap node
	if tile_map_path:
		tile_map = get_node(tile_map_path)
	else:
		push_error("MapGenerator: tile_map_path not set! Please assign it in the Inspector.")
		return

	# Validate TileMap
	if not tile_map:
		push_error("MapGenerator: TileMap node not found at path: " + str(tile_map_path))
		return

	# Auto-generate if enabled
	if auto_generate:
		generate_map()

##############################################################################
# PUBLIC API
##############################################################################

## Generates a complete tile map
##
## This is the main method you'll call to create your terrain!
## It orchestrates the entire generation process.
##
## Returns: true if generation succeeded, false otherwise
func generate_map() -> bool:
	# Validate TileMap exists
	if not tile_map:
		push_error("MapGenerator: Cannot generate - TileMap not assigned!")
		return false

	# Validate map dimensions
	if map_width < 1 or map_width > 2048 or map_height < 1 or map_height > 2048:
		push_error("MapGenerator: Invalid map dimensions (%d x %d). Must be 1-2048." % [map_width, map_height])
		return false

	# Start timing if debug enabled
	var start_time: int = Time.get_ticks_msec()

	# Determine the seed to use
	var seed_to_use: int = random_seed
	if seed_to_use == 0:
		seed_to_use = randi()

	if debug_timing:
		print("MapGenerator: Starting generation with seed %d (%d x %d)" % [seed_to_use, map_width, map_height])

	# Create the noise generator with configured parameters
	var noise_type: int = _get_noise_type_from_name(noise_type_name)
	_noise_generator = NoiseGenerator.new(
		seed_to_use,
		noise_type,
		noise_frequency,
		noise_octaves,
		noise_fractal_gain
	)

	# Create the tile mapper with configured thresholds
	_tile_mapper = TileMapper.new(
		water_threshold,
		sand_threshold,
		grass_threshold,
		stone_threshold
	)

	# Enable statistics if requested
	if show_statistics:
		_tile_mapper.enable_statistics()

	# Clear existing tiles
	tile_map.clear()

	# THE MAIN GENERATION LOOP
	# This is where the magic happens! We visit every tile position
	# and decide what type of terrain should be there.
	for y in range(map_height):
		for x in range(map_width):
			# Step 1: Get the noise value at this position
			# This returns a number between -1.0 and 1.0
			var noise_value: float = _noise_generator.get_noise_2d(x, y)

			# Step 2: Convert the noise value to a tile type
			# This returns a tile ID (0-4: water, sand, grass, stone, snow)
			var tile_id: int = _tile_mapper.map_noise_to_tile(noise_value)

			# Step 3: Place the tile in the TileMap
			# Layer 0, position (x,y), source_id 0, atlas coords (tile_id, 0)
			tile_map.set_cell(0, Vector2i(x, y), 0, Vector2i(tile_id, 0))

	# Calculate generation time
	var end_time: int = Time.get_ticks_msec()
	var generation_time: float = (end_time - start_time)

	# Output results
	if debug_timing:
		print("MapGenerator: Generation completed in %.2f ms" % generation_time)

	if show_statistics:
		var distribution = _tile_mapper.get_tile_distribution_percent()
		print("MapGenerator: Tile Distribution:")
		print("  Water: %.1f%%" % distribution["Water"])
		print("  Sand:  %.1f%%" % distribution["Sand"])
		print("  Grass: %.1f%%" % distribution["Grass"])
		print("  Stone: %.1f%%" % distribution["Stone"])
		print("  Snow:  %.1f%%" % distribution["Snow"])

	# Emit completion signal
	map_generated.emit(map_width, map_height, generation_time, seed_to_use)

	return true

## Regenerates the map with a new random seed
func regenerate_with_new_seed() -> bool:
	random_seed = 0  # Force random seed
	return generate_map()

## Regenerates the map with the same seed (useful for testing)
func regenerate_same_seed() -> bool:
	return generate_map()

##############################################################################
# HELPER METHODS
##############################################################################

## Converts the noise type name to a FastNoiseLite constant
func _get_noise_type_from_name(type_name: String) -> int:
	match type_name:
		"Simplex":
			return FastNoiseLite.TYPE_SIMPLEX
		"Perlin":
			return FastNoiseLite.TYPE_PERLIN
		"Cellular":
			return FastNoiseLite.TYPE_CELLULAR
		_:
			push_warning("MapGenerator: Unknown noise type '%s', using Simplex" % type_name)
			return FastNoiseLite.TYPE_SIMPLEX

##############################################################################
# LEARNING NOTES FOR BEGINNERS
##############################################################################
#
# WHAT IS A SEED?
#   A seed is like a "recipe number" for randomness. The same seed always
#   produces the same result. This is super useful for:
#   - Sharing cool maps with friends (just share the seed number!)
#   - Debugging (you can regenerate the exact same map to test)
#   - Multiplayer games (everyone generates the same world)
#
# WHAT IS NOISE FREQUENCY?
#   Frequency controls the "zoom level" of your terrain:
#   - Low frequency (0.005): Creates huge, continent-sized features
#   - Medium frequency (0.01): Balanced, natural-looking terrain
#   - High frequency (0.05): Creates small, tight, detailed features
#
# WHAT ARE OCTAVES?
#   Octaves add layers of detail, like adding brush strokes to a painting:
#   - 1 octave: Smooth, simple blobs (good for quick testing)
#   - 3 octaves: Nice balance of shape and detail (recommended)
#   - 6 octaves: Very detailed, rough terrain (computationally expensive)
#
# WHAT IS FRACTAL GAIN?
#   Fractal gain controls how much each octave contributes:
#   - Low gain (0.3): Each layer adds gentle detail
#   - High gain (0.7): Each layer adds dramatic, chaotic detail
#
# PERFORMANCE TIPS:
#   For a 512x512 map (262,144 tiles), you're calling noise generation
#   262,144 times! Here's what affects performance:
#   - More octaves = slower (each octave is another noise calculation)
#   - Higher resolution = slower (more tiles to process)
#   - Noise type matters less (FastNoiseLite is optimized)
#
##############################################################################
