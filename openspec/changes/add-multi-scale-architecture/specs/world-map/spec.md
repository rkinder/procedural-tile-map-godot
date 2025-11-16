# Specification: World Map

Strategic-level map representing the overall game world at coarse granularity.

## ADDED Requirements

### Requirement: World map must store strategic-level tile data

WorldMap class SHALL store a grid of tile IDs representing strategic features (biomes, terrain types).

#### Scenario: Create and populate world map

```gdscript
var world = WorldMap.new()
world.dimensions = Vector2i(256, 256)
world.generation_seed = 12345
world.initialize()

# Set strategic tiles
world.set_cell(Vector2i(10, 20), BIOME_FOREST)
world.set_cell(Vector2i(11, 20), BIOME_GRASSLAND)

assert(world.get_cell(Vector2i(10, 20)) == BIOME_FOREST)
assert(world.get_dimensions() == Vector2i(256, 256))
```

### Requirement: World map must store metadata for each cell

Each world cell SHALL store metadata (biome, elevation, temperature, moisture) used to influence tactical generation.

#### Scenario: Store and retrieve cell metadata

```gdscript
var world = WorldMap.new()
world.dimensions = Vector2i(256, 256)
world.initialize()

# Set metadata for a world cell
world.set_cell_metadata(Vector2i(50, 75), {
    "biome": "forest",
    "elevation": 0.6,
    "moisture": 0.7,
    "temperature": 0.5
})

var metadata = world.get_cell_metadata(Vector2i(50, 75))
assert(metadata["biome"] == "forest")
assert(metadata["elevation"] == 0.6)
```

### Requirement: World map must enforce immutability by default

World maps SHALL be locked for modifications by default. Attempts to modify locked world maps MUST fail with error.

#### Scenario: Reject modifications when locked

```gdscript
var world = WorldMap.new()
world.dimensions = Vector2i(256, 256)
world.initialize()
world.modification_locked = true

var success = world.set_cell(Vector2i(10, 10), BIOME_DESERT)
assert(success == false)  # Modification rejected
# Error logged: "WorldMap is locked: modifications not allowed"
```

#### Scenario: Allow modifications when unlocked

```gdscript
var world = WorldMap.new()
world.dimensions = Vector2i(256, 256)
world.initialize()
world.modification_locked = false  # Unlock for special cases

var success = world.set_cell(Vector2i(10, 10), BIOME_DESERT)
assert(success == true)  # Modification allowed
assert(world.get_cell(Vector2i(10, 10)) == BIOME_DESERT)
```

### Requirement: World map must support procedural generation

World map generation SHALL use noise-based algorithms to create strategic terrain layout.

#### Scenario: Generate world map from configuration

```gdscript
var config = GenerationConfig.new()
config.world_dimensions = Vector2i(256, 256)
config.world_seed = 42
config.world_noise_frequency = 0.02

var generator = WorldMapGenerator.new()
var world = generator.generate(config)

assert(world.dimensions == Vector2i(256, 256))
assert(world.generation_seed == 42)
assert(world.is_generated() == true)
```

### Requirement: World map must validate coordinates

Out-of-bounds coordinate access SHALL return null/error rather than crashing.

#### Scenario: Handle out-of-bounds access gracefully

```gdscript
var world = WorldMap.new()
world.dimensions = Vector2i(256, 256)
world.initialize()

var tile = world.get_cell(Vector2i(500, 500))  # Out of bounds
assert(tile == -1)  # Invalid tile ID
# Warning logged: "Coordinate (500, 500) out of bounds"
```

### Requirement: World map must store generation metadata

World map SHALL store its generation seed, configuration, and timestamp for reproducibility.

#### Scenario: Access generation metadata

```gdscript
var world = WorldMap.new()
world.generation_seed = 98765
world.generation_config = config_dict
world.generation_timestamp = Time.get_unix_time_from_system()

assert(world.generation_seed == 98765)
assert(world.generation_config.has("world_noise_frequency"))
assert(world.generation_timestamp > 0)
```
