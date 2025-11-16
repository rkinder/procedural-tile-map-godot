# Specification: Map Coordinator

Orchestrates relationships between world map and tactical maps, managing lifecycle and caching.

## ADDED Requirements

### Requirement: Map coordinator must manage world map lifecycle

MapCoordinator SHALL load, store, and provide access to the world map.

#### Scenario: Set and retrieve world map

```gdscript
var coordinator = MapCoordinator.new()
var world = WorldMap.new()
world.dimensions = Vector2i(256, 256)
world.initialize()

coordinator.set_world_map(world)

var retrieved = coordinator.get_world_map()
assert(retrieved == world)
assert(retrieved.dimensions == Vector2i(256, 256))
```

### Requirement: Map coordinator must instantiate tactical maps on-demand

When requesting a tactical map for a world cell, coordinator SHALL generate it if not cached, or return cached instance.

#### Scenario: Generate tactical map on first access

```gdscript
var coordinator = MapCoordinator.new()
var world = WorldMap.new()
world.generation_seed = 42
coordinator.set_world_map(world)

var tactical = coordinator.get_tactical_map(Vector2i(10, 10))

assert(tactical != null)
assert(tactical.world_position == Vector2i(10, 10))
assert(coordinator.is_tactical_cached(Vector2i(10, 10)) == true)
```

#### Scenario: Return cached tactical map on subsequent access

```gdscript
var coordinator = MapCoordinator.new()
coordinator.set_world_map(world)

var tactical1 = coordinator.get_tactical_map(Vector2i(5, 5))
tactical1.set_cell(Vector2i(0, 0), TILE_CUSTOM)  # Modify

var tactical2 = coordinator.get_tactical_map(Vector2i(5, 5))

assert(tactical1 == tactical2)  # Same instance
assert(tactical2.get_cell(Vector2i(0, 0)) == TILE_CUSTOM)  # Modification preserved
```

### Requirement: Map coordinator must implement LRU cache for tactical maps

Coordinator SHALL cache up to max_cache_size tactical maps, evicting least recently used when limit exceeded.

#### Scenario: Evict least recently used tactical map

```gdscript
var coordinator = MapCoordinator.new()
coordinator.max_cache_size = 3
coordinator.set_world_map(world)

var t1 = coordinator.get_tactical_map(Vector2i(0, 0))
var t2 = coordinator.get_tactical_map(Vector2i(1, 1))
var t3 = coordinator.get_tactical_map(Vector2i(2, 2))

# Cache full (3/3)
assert(coordinator.get_cache_size() == 3)

var t4 = coordinator.get_tactical_map(Vector2i(3, 3))

# Vector2i(0, 0) should be evicted (LRU)
assert(coordinator.is_tactical_cached(Vector2i(0, 0)) == false)
assert(coordinator.is_tactical_cached(Vector2i(3, 3)) == true)
assert(coordinator.get_cache_size() == 3)
```

### Requirement: Map coordinator must update LRU order on access

Accessing a cached tactical map SHALL move it to most-recently-used position.

#### Scenario: Refresh LRU position on access

```gdscript
var coordinator = MapCoordinator.new()
coordinator.max_cache_size = 3
coordinator.set_world_map(world)

var t1 = coordinator.get_tactical_map(Vector2i(0, 0))
var t2 = coordinator.get_tactical_map(Vector2i(1, 1))
var t3 = coordinator.get_tactical_map(Vector2i(2, 2))

# Re-access t1 (refresh its LRU position)
var t1_again = coordinator.get_tactical_map(Vector2i(0, 0))

# Add new map
var t4 = coordinator.get_tactical_map(Vector2i(3, 3))

# Vector2i(1, 1) should be evicted (was LRU before t1 refresh)
assert(coordinator.is_tactical_cached(Vector2i(0, 0)) == true)  # Refreshed
assert(coordinator.is_tactical_cached(Vector2i(1, 1)) == false)  # Evicted
```

### Requirement: Map coordinator must derive tactical seeds from world seed and position

Tactical generation seed SHALL be derived from f(world_seed, world_position) for deterministic generation.

#### Scenario: Generate deterministic tactical seed

```gdscript
var coordinator = MapCoordinator.new()
var world = WorldMap.new()
world.generation_seed = 12345
coordinator.set_world_map(world)

var seed1 = coordinator.derive_tactical_seed(Vector2i(10, 10))
var seed2 = coordinator.derive_tactical_seed(Vector2i(10, 10))
var seed3 = coordinator.derive_tactical_seed(Vector2i(10, 11))

assert(seed1 == seed2)  # Same position = same seed
assert(seed1 != seed3)  # Different position = different seed
```

### Requirement: Map coordinator must pass world context to tactical generation

When generating tactical map, coordinator SHALL extract world cell metadata and pass as context.

#### Scenario: Extract world context for tactical generation

```gdscript
var coordinator = MapCoordinator.new()
var world = WorldMap.new()
world.set_cell_metadata(Vector2i(50, 50), {"biome": "desert", "elevation": 0.3})
coordinator.set_world_map(world)

var tactical = coordinator.get_tactical_map(Vector2i(50, 50))

# Tactical should inherit world context
assert(tactical.generation_context["biome"] == "desert")
assert(tactical.generation_context["elevation"] == 0.3)
```

### Requirement: Map coordinator must support manual cache eviction

System SHALL allow explicit eviction of tactical maps from cache (e.g., for memory management).

#### Scenario: Manually evict tactical map

```gdscript
var coordinator = MapCoordinator.new()
coordinator.set_world_map(world)

var tactical = coordinator.get_tactical_map(Vector2i(5, 5))
assert(coordinator.is_tactical_cached(Vector2i(5, 5)) == true)

coordinator.evict_tactical_map(Vector2i(5, 5))
assert(coordinator.is_tactical_cached(Vector2i(5, 5)) == false)
```

### Requirement: Map coordinator must support clearing entire cache

System SHALL allow clearing all cached tactical maps (e.g., when switching worlds).

#### Scenario: Clear all cached tactical maps

```gdscript
var coordinator = MapCoordinator.new()
coordinator.set_world_map(world)

coordinator.get_tactical_map(Vector2i(0, 0))
coordinator.get_tactical_map(Vector2i(1, 1))
coordinator.get_tactical_map(Vector2i(2, 2))

assert(coordinator.get_cache_size() == 3)

coordinator.clear_tactical_cache()
assert(coordinator.get_cache_size() == 0)
```

### Requirement: Map coordinator must validate world position before tactical generation

Requesting tactical map for out-of-bounds world position SHALL return null/error.

#### Scenario: Reject invalid world position

```gdscript
var coordinator = MapCoordinator.new()
var world = WorldMap.new()
world.dimensions = Vector2i(256, 256)
coordinator.set_world_map(world)

var tactical = coordinator.get_tactical_map(Vector2i(300, 300))  # Out of bounds

assert(tactical == null)
# Error logged: "World position (300, 300) out of bounds"
```
