##############################################################################
# NoiseGenerator - A beginner-friendly wrapper for Godot's FastNoiseLite
##############################################################################
#
# PURPOSE:
#   This class generates "noise" - random-looking but smooth patterns of numbers
#   that we can use to create natural-looking terrain. Think of it like clouds
#   or waves - not completely random, but flowing and organic.
#
# WHY NOISE FOR TERRAIN?
#   Pure randomness creates ugly, scattered patterns. Noise creates smooth,
#   natural-looking variations perfect for hills, valleys, and terrain features.
#
# USAGE EXAMPLE:
#   var noise = NoiseGenerator.new(12345)  # 12345 is the "seed"
#   var height = noise.get_noise_2d(10, 20)  # Get noise value at position (10, 20)
#   # height will be a number between -1.0 and 1.0
#
##############################################################################

class_name NoiseGenerator

# The underlying noise engine from Godot
var _noise: FastNoiseLite

# Store the current seed for reproducibility
var _current_seed: int = 0

##############################################################################
# CONSTRUCTOR
##############################################################################

## Creates a new NoiseGenerator
##
## Parameters:
##   seed: A number that determines the pattern. Same seed = same pattern!
##   noise_type: Type of noise algorithm (default: Simplex - smooth and fast)
##   frequency: How "zoomed in" the noise is (0.01 = large features, 0.1 = small features)
##   octaves: Layers of detail (1 = smooth, 5 = more detail/roughness)
##   fractal_gain: How much each detail layer affects the result (0.5 = balanced)
func _init(
	seed: int = 0,
	noise_type: int = FastNoiseLite.TYPE_SIMPLEX,
	frequency: float = 0.01,
	octaves: int = 3,
	fractal_gain: float = 0.5
) -> void:
	# Create the underlying noise engine
	_noise = FastNoiseLite.new()

	# If seed is 0, generate a random one
	if seed == 0:
		seed = randi()

	# Configure the noise parameters
	_current_seed = seed
	_noise.seed = seed
	_noise.noise_type = noise_type
	_noise.frequency = frequency
	_noise.fractal_octaves = octaves
	_noise.fractal_gain = fractal_gain
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM

##############################################################################
# NOISE SAMPLING METHODS
##############################################################################

## Gets noise value at a 2D coordinate
##
## Returns: A float between -1.0 and 1.0
##   -1.0 = lowest point (like ocean floor)
##    0.0 = middle elevation (like plains)
##   +1.0 = highest point (like mountain peaks)
func get_noise_2d(x: int, y: int) -> float:
	return _noise.get_noise_2d(float(x), float(y))

## Gets noise value normalized to 0.0 - 1.0 range
##
## This is useful when you want values that are always positive.
## Returns: A float between 0.0 and 1.0
func get_noise_normalized(x: int, y: int) -> float:
	# Convert from [-1.0, 1.0] to [0.0, 1.0]
	# Formula: (value + 1) / 2
	var raw_noise: float = get_noise_2d(x, y)
	return (raw_noise + 1.0) / 2.0

##############################################################################
# SEED MANAGEMENT
##############################################################################

## Changes the seed, which completely changes the noise pattern
##
## This is useful for generating different maps without creating new objects
func set_seed(new_seed: int) -> void:
	_current_seed = new_seed
	_noise.seed = new_seed

## Gets the current seed value
func get_seed() -> int:
	return _current_seed

## Generates and applies a new random seed
##
## Returns: The new seed value (useful for saving/sharing)
func generate_random_seed() -> int:
	var new_seed: int = randi()
	set_seed(new_seed)
	return new_seed

##############################################################################
# NOISE PARAMETER CONFIGURATION
##############################################################################

## Sets the noise type
##
## Options:
##   FastNoiseLite.TYPE_SIMPLEX - Smooth, fast (best for beginners)
##   FastNoiseLite.TYPE_PERLIN - Classic, smooth
##   FastNoiseLite.TYPE_CELLULAR - Creates cell-like patterns (good for biomes)
func set_noise_type(noise_type: int) -> void:
	_noise.noise_type = noise_type

## Sets the frequency (zoom level)
##
## Lower values (0.005) = Large, sweeping features (continents)
## Higher values (0.05) = Small, tight features (rocky terrain)
func set_frequency(frequency: float) -> void:
	_noise.frequency = frequency

## Sets the number of octaves (detail layers)
##
## 1 octave = Very smooth, simple shapes
## 3 octaves = Balanced (recommended)
## 6+ octaves = Very detailed, rough terrain
func set_octaves(octaves: int) -> void:
	_noise.fractal_octaves = octaves

## Sets the fractal gain (how much each octave contributes)
##
## Lower values (0.3) = Smoother, less chaotic
## Higher values (0.7) = Rougher, more chaotic
func set_fractal_gain(gain: float) -> void:
	_noise.fractal_gain = gain

##############################################################################
# UTILITY METHODS
##############################################################################

## Gets a reference to the underlying FastNoiseLite instance
##
## Advanced users can access this to use features not wrapped by this class
func get_noise_instance() -> FastNoiseLite:
	return _noise
