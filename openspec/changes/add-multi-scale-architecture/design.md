# Design: Multi-Scale Map Architecture

## Context

The project needs to support a two-tier map system:
- **World Map**: Strategic overview, largely immutable, coarse-grained
- **Tactical Maps**: Detailed views of world regions, player-modifiable, fine-grained

This pattern is common in strategy games (Civilization, XCOM) where a strategic map provides context and tactical maps provide gameplay depth.

## Goals / Non-Goals

**Goals:**
- Enable world map (strategic) and tactical map (detail) as distinct entities
- Support on-demand tactical map instantiation from world cells
- Ensure tactical generation inherits world characteristics (biome, elevation)
- Provide coordinate translation between world and tactical spaces
- Allow world map immutability while tactical maps are fully modifiable
- Support multiple active tactical maps with lifecycle management
- Maintain deterministic generation (same world cell always generates same tactical map)

**Non-Goals:**
- Infinite maps (both world and tactical have defined bounds)
- Real-time map transitions or smooth zooming (discrete world→tactical switches)
- Network synchronization of multi-scale maps
- More than two scale levels (no tactical→detail→micro hierarchy)
- Dynamic scale ratios (tactical:world ratio is fixed per configuration)

## Decisions

### Decision: Fixed Two-Level Hierarchy (World → Tactical)

Use exactly two scale levels: world and tactical, with fixed size relationships.

**Rationale:**
- Simplicity: two levels cover the stated use case
- Clear separation of concerns (strategic vs gameplay)
- Predictable memory and performance characteristics
- Matches common game design patterns

**Alternatives considered:**
- Arbitrary N-level hierarchy: excessive complexity, unclear use case
- Dynamic zoom levels: requires smooth interpolation, out of scope
- Single scale with detail layers: doesn't support separate modification policies

**Configuration:**
```gdscript
# Example: ScaleConfig
world_dimensions = Vector2i(256, 256)      # 256x256 world cells
tactical_dimensions = Vector2i(64, 64)     # Each cell expands to 64x64 tactical tiles
```

### Decision: On-Demand Tactical Instantiation with LRU Cache

Generate tactical maps on-demand when player selects a world cell, cache recently used maps, evict using LRU.

**Rationale:**
- Memory efficient: don't generate all possible tactical maps upfront (256×256 = 65,536 tactical maps!)
- Lazy evaluation: only generate what player visits
- LRU cache prevents regeneration for frequently visited areas
- Configurable cache size balances memory vs regeneration cost

**Alternatives considered:**
- Pre-generate all tactical maps: infeasible memory cost (65K+ maps)
- No caching: expensive to regenerate on every visit
- Fixed pool of tactical slots: complex management, unclear eviction policy

**Implementation:**
```gdscript
class MapCoordinator:
    var tactical_cache: Dictionary = {}  # Vector2i -> TacticalMap
    var cache_lru: Array[Vector2i] = []  # Access order
    var max_cache_size: int = 50  # Configurable

    func get_tactical_map(world_pos: Vector2i) -> TacticalMap:
        if tactical_cache.has(world_pos):
            _touch_cache(world_pos)  # Update LRU
            return tactical_cache[world_pos]
        else:
            return _generate_and_cache_tactical(world_pos)
```

### Decision: Deterministic Tactical Generation via Position-Seeded Noise

Derive tactical map seed from world seed + world position hash, ensuring same world cell always generates same tactical map.

**Rationale:**
- Reproducibility: same world location always looks the same (before player modifications)
- Cacheable: regenerated tactical map matches original if no player edits
- Stateless: don't need to store tactical seeds separately
- Supports procedural consistency across play sessions

**Alternatives considered:**
- Random tactical seeds: non-reproducible, confusing for players
- Store tactical seeds separately: unnecessary storage overhead
- No seeding: defeats purpose of procedural generation

**Seed derivation:**
```gdscript
func derive_tactical_seed(world_pos: Vector2i) -> int:
    var world_seed = world_map.generation_seed
    var position_hash = hash(Vector2(world_pos.x, world_pos.y))
    return world_seed ^ position_hash  # XOR for mixing
```

### Decision: Generation Inheritance via Context Passing

Pass world cell data (biome, elevation, metadata) as context to tactical generation, influencing noise parameters and tile selection.

**Rationale:**
- Coherence: tactical map matches world cell characteristics
- Flexibility: world data suggests but doesn't dictate tactical details
- Extensibility: easy to add more inherited properties (moisture, temperature)
- Clear flow: world → context → tactical generator

**Alternatives considered:**
- Independent tactical generation: breaks visual coherence
- Strict deterministic mapping: too rigid, limits tactical variety
- Implicit inheritance via shared seed only: insufficient control over characteristics

**Context structure:**
```gdscript
class TacticalGenerationContext:
    var world_position: Vector2i
    var base_seed: int
    var biome_type: String  # From world cell
    var elevation_offset: float  # Base height from world
    var world_metadata: Dictionary  # Additional properties
```

### Decision: Coordinate Mapping via Simple Multiplication

Convert world cell coordinates to tactical tile coordinates using scale factor: `tactical_coord = world_coord * tactical_dimensions`.

**Rationale:**
- Simplicity: trivial calculation, O(1) complexity
- Clarity: easy to reason about and debug
- Bidirectional: easy to convert tactical → world as well
- No edge cases: works for all valid coordinates

**Alternatives considered:**
- Offset-based mapping: more complex, no clear benefit
- Non-uniform scaling: breaks grid alignment
- Overlapping tactical regions: complex boundary handling

**Implementation:**
```gdscript
class CoordinateMapper:
    var tactical_dimensions: Vector2i

    func world_to_tactical_region(world_pos: Vector2i) -> Rect2i:
        var top_left = world_pos * tactical_dimensions
        return Rect2i(top_left, tactical_dimensions)

    func tactical_to_world(tactical_pos: Vector2i) -> Vector2i:
        return tactical_pos / tactical_dimensions
```

### Decision: World Map Immutability via Locked Modification Flag

Mark world maps as modification-locked by default; reject edit attempts with clear error messages.

**Rationale:**
- Clear intent: world map is reference, not playground
- Simple implementation: single boolean flag
- Debuggable: explicit errors when edits attempted
- Configurable: can unlock for special cases (map editor mode)

**Alternatives considered:**
- No enforcement: relies on discipline, easy to break accidentally
- Read-only data structures: more complex, unnecessary overhead
- Permission system: overkill for binary locked/unlocked

**Implementation:**
```gdscript
class WorldMap:
    var modification_locked: bool = true

    func set_cell(pos: Vector2i, tile_id: int) -> bool:
        if modification_locked:
            push_error("WorldMap is locked: modifications not allowed")
            return false
        # ... actual modification logic
        return true
```

### Decision: Separate WorldMap and TacticalMap Classes (Composition over Inheritance)

Define WorldMap and TacticalMap as distinct classes with shared interface but different behavior, rather than inheriting from common MapBase.

**Rationale:**
- Clarity: clear distinction between world and tactical
- Flexibility: different internal representations if needed
- Simplicity: avoid abstract base class complexity
- GDScript compatibility: composition more idiomatic than deep inheritance

**Alternatives considered:**
- Common MapBase class: premature abstraction, unnecessary complexity
- Single Map class with type flag: harder to enforce different behaviors
- Duck typing only: loses type safety and clarity

**Structure:**
```gdscript
# WorldMap (strategic scale)
class_name WorldMap extends Resource
    var dimensions: Vector2i
    var generation_seed: int
    var tile_data: Array  # Flat array of tile IDs
    var metadata: Dictionary  # Per-cell biome, elevation, etc.
    var modification_locked: bool = true

# TacticalMap (detail scale)
class_name TacticalMap extends Resource
    var world_position: Vector2i  # Which world cell this represents
    var dimensions: Vector2i
    var generation_seed: int
    var tile_data: Array
    var modification_tracker: ModificationTracker  # Player edits
    var modification_locked: bool = false
```

### Decision: MapCoordinator as Singleton Service

Implement MapCoordinator as an autoload singleton managing world map and tactical map lifecycle.

**Rationale:**
- Global access: any scene can request tactical maps
- Centralized state: single source of truth for active maps
- Lifecycle management: handles loading, caching, eviction
- Godot pattern: autoload singletons are idiomatic

**Alternatives considered:**
- Pass coordinator as parameter: tedious, deep call chains
- Scene tree node: lifecycle tied to specific scene
- Static class: less flexible, harder to test

**Autoload registration:**
```
Project Settings > Autoload > MapCoordinator: scripts/map_coordinator.gd
```

## Risks / Trade-offs

**Risk:** Tactical generation may be slow, blocking player transitions
- **Mitigation:** Implement progressive generation (Phase 3: chunk generation), show loading indicator

**Risk:** Cache thrashing if player rapidly switches between many tactical maps
- **Mitigation:** Configurable cache size, prioritize recently/frequently visited maps

**Risk:** World and tactical maps may become visually inconsistent
- **Mitigation:** Ensure generation inheritance passes sufficient context, visual testing

**Risk:** Coordinate mapping errors could cause misalignment
- **Mitigation:** Thorough unit testing of CoordinateMapper, visual debug overlays

**Trade-off:** Memory usage vs regeneration cost
- **Impact:** Larger cache uses more memory but reduces regeneration
- **Decision:** Default to 50 cached tactical maps, make configurable

**Trade-off:** Deterministic generation vs variety
- **Impact:** Same world cell always generates same tactical map (predictable but potentially repetitive)
- **Decision:** Accept determinism for reproducibility; add optional variation parameter in future if needed

## Migration Plan

**Breaking Changes:**
1. Generation API extended: generators must support scale context
2. Map persistence must distinguish world vs tactical (see add-hierarchical-persistence proposal)
3. Configuration extended with ScaleConfig resource

**Migration Steps:**
1. Implement new classes (WorldMap, TacticalMap, MapCoordinator, CoordinateMapper)
2. Extend GenerationConfig with ScaleConfig
3. Update NoiseGenerator to accept TacticalGenerationContext
4. Update MapGenerator to support both world and tactical modes
5. Integrate with map-serialization for tactical modification tracking
6. Update demo scenes to showcase world→tactical transitions
7. Document multi-scale usage patterns

**Backward Compatibility:**
- Existing single-map code can operate in "tactical-only mode" (no world map)
- Provide compatibility wrapper: `MapGenerator.generate_standalone_tactical()` for single-scale use

## Open Questions

- **What should world map tile IDs represent?** → Biome types (water, grassland, forest, mountain, etc.)
- **Should tactical maps support multiple visits?** → Yes, modifications persist via map-serialization
- **How to handle tactical maps that cross world cell boundaries?** → No cross-boundary; each tactical map is fully contained in one world cell
- **Should world map allow annotations (markers, notes)?** → Defer to future enhancement; initial version is fully immutable
- **What's the optimal tactical cache size?** → Default 50, make configurable, profile memory usage
- **Should we support unloading world map?** → No, world map always loaded (small memory footprint)
