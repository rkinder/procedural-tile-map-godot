# Specification: Tactical Map

Detail-level map representing a zoomed-in region of the world map with fine-grained tiles.

## ADDED Requirements

### Requirement: Tactical map must reference its world position

TacticalMap SHALL store which world cell it represents, enabling coordinate translation and context inheritance.

#### Scenario: Create tactical map for world cell

```gdscript
var tactical = TacticalMap.new()
tactical.world_position = Vector2i(100, 200)
tactical.dimensions = Vector2i(64, 64)
tactical.initialize()

assert(tactical.world_position == Vector2i(100, 200))
assert(tactical.dimensions == Vector2i(64, 64))
```

### Requirement: Tactical map must store detailed tile data

TacticalMap SHALL store a grid of detailed tile IDs representing gameplay-level terrain.

#### Scenario: Set and retrieve tactical tiles

```gdscript
var tactical = TacticalMap.new()
tactical.dimensions = Vector2i(64, 64)
tactical.initialize()

tactical.set_cell(Vector2i(10, 10), TILE_GRASS)
tactical.set_cell(Vector2i(10, 11), TILE_TREE)

assert(tactical.get_cell(Vector2i(10, 10)) == TILE_GRASS)
assert(tactical.get_cell(Vector2i(10, 11)) == TILE_TREE)
```

### Requirement: Tactical map must support player modifications

Tactical maps SHALL allow unrestricted tile modifications and track changes via ModificationTracker.

#### Scenario: Track player modifications

```gdscript
var tactical = TacticalMap.new()
tactical.dimensions = Vector2i(64, 64)
tactical.initialize()
tactical.enable_modification_tracking()

tactical.set_cell(Vector2i(5, 5), TILE_DIRT)
tactical.mark_tile_modified(Vector2i(5, 5), "player_edit")

assert(tactical.is_tile_modified(Vector2i(5, 5)) == true)
assert(tactical.get_modification_count() == 1)
```

### Requirement: Tactical map must derive from world context

Tactical generation SHALL receive world cell metadata as context, influencing biome distribution and elevation.

#### Scenario: Generate tactical map with world context

```gdscript
var world_metadata = {
    "biome": "forest",
    "elevation": 0.6,
    "moisture": 0.7
}

var context = TacticalGenerationContext.new()
context.world_position = Vector2i(50, 50)
context.base_seed = 12345
context.biome_type = world_metadata["biome"]
context.elevation_offset = world_metadata["elevation"]

var generator = TacticalMapGenerator.new()
var tactical = generator.generate(context)

assert(tactical.world_position == Vector2i(50, 50))
# Tactical tiles should reflect forest biome influence
```

### Requirement: Tactical map generation must be deterministic

Same world position with same world seed SHALL always generate identical tactical map (before modifications).

#### Scenario: Reproduce tactical map from world position

```gdscript
var world = WorldMap.new()
world.generation_seed = 42

var coordinator = MapCoordinator.new()
coordinator.set_world_map(world)

var tactical1 = coordinator.get_tactical_map(Vector2i(10, 10))
var tactical2 = coordinator.get_tactical_map(Vector2i(10, 10))

# Should be identical (unless player modified tactical1)
assert(tactical1.generation_seed == tactical2.generation_seed)
```

### Requirement: Tactical map must validate coordinates

Out-of-bounds coordinate access SHALL return null/error rather than crashing.

#### Scenario: Handle out-of-bounds access gracefully

```gdscript
var tactical = TacticalMap.new()
tactical.dimensions = Vector2i(64, 64)
tactical.initialize()

var tile = tactical.get_cell(Vector2i(100, 100))  # Out of bounds
assert(tile == -1)  # Invalid tile ID
# Warning logged: "Coordinate (100, 100) out of bounds for tactical map"
```

### Requirement: Tactical map must store generation metadata

Tactical map SHALL store generation seed, world position, and context for debugging and regeneration.

#### Scenario: Access tactical generation metadata

```gdscript
var tactical = TacticalMap.new()
tactical.world_position = Vector2i(25, 30)
tactical.generation_seed = 54321
tactical.generation_context = {"biome": "desert", "elevation": 0.3}

assert(tactical.world_position == Vector2i(25, 30))
assert(tactical.generation_seed == 54321)
assert(tactical.generation_context["biome"] == "desert")
```

### Requirement: Tactical map must allow unrestricted modifications

Unlike WorldMap, TacticalMap SHALL allow modifications by default (modification_locked = false).

#### Scenario: Modify tactical map freely

```gdscript
var tactical = TacticalMap.new()
tactical.dimensions = Vector2i(64, 64)
tactical.initialize()

assert(tactical.modification_locked == false)  # Unlocked by default

var success = tactical.set_cell(Vector2i(20, 20), TILE_WATER)
assert(success == true)  # Modification allowed
```
