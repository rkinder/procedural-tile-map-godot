# Technical Design: Tactical-Scale Map Generation

## Context

This design extends the existing world-scale procedural generation system to support tactical-scale maps with detailed environmental features. The implementation should be educational, demonstrating multi-layer noise composition and rule-based feature placement.

**Constraints:**
- GDScript only (consistent with existing codebase)
- Godot 4.x API
- Must be seed-deterministic (same world position = same tactical map)
- Performance target: < 100ms for 64×64 tactical map
- Backward compatible (doesn't modify existing world generation)

## Goals / Non-Goals

### Goals
- Generate detailed 64×64 tactical maps from world map coordinates
- Use multi-layer noise for natural-looking feature distribution
- Implement rule-based feature placement (terrain-aware)
- Maintain seed-based reproducibility
- Create educational implementation suitable for learning
- Demonstrate noise composition techniques

### Non-Goals
- Modifying existing world generation system (keep it intact)
- Real-time streaming or infinite tactical maps (single-screen focus)
- Advanced AI pathfinding integration (basic placement only)
- Animated features or entity systems
- Save/load tactical map state (generate on-demand)

## Decisions

### Decision 1: Three-Layer Noise Architecture

**Choice:** Use three separate noise layers for tactical generation.

**Layers:**
1. **Base Terrain Noise** - Ground tile type (grass, dirt, stone, sand, gravel)
2. **Feature Density Noise** - Where features cluster vs sparse areas
3. **Feature Type Noise** - Which specific feature (oak, pine, boulder, bush)

**Rationale:**
- **Separation of concerns**: Each layer has a single responsibility
- **Flexibility**: Can tune each layer independently
- **Natural clustering**: Density noise creates realistic groupings
- **Variety**: Type noise prevents repetitive patterns

**Implementation:**
```gdscript
# Example generation flow
var terrain_noise = NoiseGenerator.new(tactical_seed)
var density_noise = NoiseGenerator.new(tactical_seed + 1000)
var type_noise = NoiseGenerator.new(tactical_seed + 2000)

for each tile:
    terrain = terrain_noise.get_noise_2d(x, y)
    density = density_noise.get_noise_2d(x, y)
    type_val = type_noise.get_noise_2d(x, y)

    place_base_terrain(terrain)
    if density > placement_threshold:
        place_feature(terrain, type_val)
```

**Alternatives considered:**
- Single noise layer: Rejected, insufficient variety and control
- Two layers (terrain + features): Rejected, no control over feature clustering
- Four+ layers: Deferred as over-engineering for initial implementation

---

### Decision 2: Rule-Based Feature Placement System

**Choice:** Create a `FeaturePlacementRules` class that defines legal feature placements.

**Rule Structure:**
```gdscript
class FeaturePlacementRules:
    # Define what features can appear on each terrain type
    var rules: Dictionary = {
        TerrainType.GRASS: [FeatureType.TREE, FeatureType.BUSH, FeatureType.FLOWER],
        TerrainType.DIRT: [FeatureType.ROCK_SMALL, FeatureType.BUSH],
        TerrainType.STONE: [FeatureType.BOULDER, FeatureType.ROCK_SMALL],
        TerrainType.SAND: [FeatureType.ROCK_SMALL],
        TerrainType.WATER: []  # No features on water
    }
```

**Rationale:**
- **Realistic placement**: Trees don't grow on water or stone
- **Easy to understand**: Clear visual mapping of rules
- **Easy to extend**: Add new terrain or feature types
- **Educational**: Demonstrates rule-based systems

**Validation Process:**
1. Check if terrain type allows any features
2. Filter feature list by terrain compatibility
3. Use type noise to select from valid features
4. Apply density threshold for spacing

**Alternatives considered:**
- Hardcoded placement logic: Rejected, inflexible and hard to maintain
- Probability-based weights: Deferred for future enhancement
- Script-based rules (GDScript files): Rejected as over-engineering

---

### Decision 3: Coordinate-Derived Seed System

**Choice:** Derive tactical map seeds from world coordinates deterministically.

**Formula:**
```gdscript
func get_tactical_seed(world_x: int, world_y: int, base_seed: int) -> int:
    return base_seed + (world_x * 10000) + world_y
```

**Rationale:**
- **Deterministic**: Same world position always generates same tactical map
- **Unique**: Each world tile gets a unique seed
- **Simple**: Easy to understand and implement
- **Reproducible**: Can regenerate tactical maps on demand

**Example:**
```
Base world seed: 12345
World position (5, 10):
Tactical seed = 12345 + (5 * 10000) + 10 = 62355

World position (3, 7):
Tactical seed = 12345 + (3 * 10000) + 7 = 42352
```

**Alternatives considered:**
- Hash-based seed derivation: Rejected as unnecessarily complex
- Random seed per tactical map: Rejected, not reproducible
- Concatenate coordinates as string: Rejected, less performant

---

### Decision 4: Multiple TileMap Layers

**Choice:** Use multiple TileMap nodes or layers for different element types.

**Layer Structure:**
```
TacticalMap (Node2D)
├── GroundTileMap (TileMap) - Base terrain
└── FeatureTileMap (TileMap) - Trees, rocks, bushes
```

**Rationale:**
- **Visual clarity**: Features render above ground naturally
- **Easy editing**: Can toggle feature visibility
- **Flexibility**: Can add more layers later (decorations, effects)
- **Performance**: Godot optimizes TileMap rendering per layer

**Alternative considered:**
- Single TileMap with multiple layers: Equivalent, either approach works
- Separate TileMaps per feature type: Rejected as over-engineering

---

### Decision 5: Higher Frequency for Tactical Detail

**Choice:** Use frequency range 0.05-0.15 for tactical maps vs 0.005-0.02 for world maps.

**Comparison:**
```
World Map:
- Frequency: 0.01
- Scale: Each tile = 1km (example)
- Features: Continents, mountain ranges

Tactical Map:
- Frequency: 0.08
- Scale: Each tile = 5m (example)
- Features: Individual trees, rocks
```

**Rationale:**
- **Appropriate detail**: Higher frequency creates smaller, tighter features
- **Visual distinction**: Clearly different scale from world map
- **Natural variation**: Creates realistic feature placement patterns
- **Performance acceptable**: Still fast enough for real-time generation

**Tuning Recommendations:**
- Terrain layer: 0.05-0.08 (larger ground features)
- Density layer: 0.06-0.1 (medium clustering)
- Type layer: 0.08-0.15 (fine-grained variety)

---

### Decision 6: Feature Type Mapping via Noise Ranges

**Choice:** Map noise ranges to specific features using normalized noise.

**Implementation:**
```gdscript
func map_noise_to_feature(noise_value: float, terrain_type: int) -> int:
    var valid_features = placement_rules.get_valid_features(terrain_type)
    if valid_features.is_empty():
        return NO_FEATURE

    # Normalize noise to 0-1 range
    var normalized = (noise_value + 1.0) / 2.0

    # Divide range by number of valid features
    var feature_index = int(normalized * valid_features.size())
    feature_index = clamp(feature_index, 0, valid_features.size() - 1)

    return valid_features[feature_index]
```

**Rationale:**
- **Even distribution**: Each valid feature gets equal probability
- **Deterministic**: Same noise value = same feature
- **Simple**: Easy to understand and debug
- **Extensible**: Easy to add weighted probabilities later

---

### Decision 7: Tactical Map Size and Scale

**Choice:** Default to 64×64 tiles per tactical map.

**Sizing:**
- **64×64** (4,096 tiles) - Default, good balance
- Smaller (32×32) - Quick generation, limited detail
- Larger (128×128) - More detail, slower generation

**Rationale:**
- **Performance**: 4,096 tiles × 3 noise samples = ~12,000 calculations (~50ms)
- **Viewport fit**: Fills typical game screen nicely
- **Memory reasonable**: ~16KB for tile data
- **Matches common tactical game scales**

**Configurable via export:**
```gdscript
@export_range(32, 256) var tactical_width: int = 64
@export_range(32, 256) var tactical_height: int = 64
```

---

## Architecture Diagram

```
TacticalMapGenerator (Node)
    ├── MultiLayerNoiseGenerator
    │   ├── NoiseGenerator (terrain)
    │   ├── NoiseGenerator (density)
    │   └── NoiseGenerator (type)
    ├── TacticalTileMapper
    │   └── FeaturePlacementRules
    └── References:
        ├── GroundTileMap (updates base terrain)
        └── FeatureTileMap (places features)
```

## Data Flow

```
1. User requests tactical map for world position (wx, wy)
2. TacticalMapGenerator:
   a. Derive tactical_seed from world coordinates
   b. Create MultiLayerNoiseGenerator with tactical_seed
   c. Create TacticalTileMapper with placement rules
3. For each tactical tile (x, y):
   a. Sample terrain_noise → terrain_type
   b. Sample density_noise → should_place_feature
   c. Sample type_noise → feature_variant
   d. TacticalTileMapper:
      - Check if terrain allows features
      - Check if density exceeds threshold
      - Select valid feature from type noise
   e. Place base terrain tile
   f. Place feature tile (if applicable)
4. Emit generation_complete signal
```

## Performance Strategy

### Initial Implementation
- Single-threaded, synchronous generation
- Direct nested loop iteration
- Target: < 100ms for 64×64 tactical map

### Expected Performance
```
Calculations per 64×64 map:
- Terrain noise: 4,096 samples
- Density noise: 4,096 samples
- Type noise: ~2,000 samples (only where density > threshold)
- Total: ~10,000 noise samples
- Estimated time: 40-80ms on modern hardware
```

### Optimization Opportunities (Future)
1. Pre-generate noise in chunks if needed
2. Use worker thread for generation
3. Cache tactical maps for recently visited areas
4. Batch tile placement calls

---

## Risks / Trade-offs

### Risk: Performance with multiple noise layers
**Likelihood:** Low
**Impact:** Medium
**Mitigation:**
- Profile early with 64×64 maps
- Each noise sample is ~5-10 microseconds (very fast)
- Can reduce tactical map size if needed
- Can adjust octaves per layer for speed

### Risk: Feature placement feels too uniform
**Likelihood:** Medium
**Impact:** Low
**Mitigation:**
- Tune density threshold per feature type
- Add "no-feature" zones via density threshold
- Use different frequencies per layer for variety
- Document tuning process for users

### Risk: Coordinate derivation seed collisions
**Likelihood:** Low
**Impact:** Low
**Mitigation:**
- Use large multiplier (10000) to avoid collisions
- Validate with automated tests
- Document the formula clearly

### Trade-off: Simplicity vs Features
**Decision:** Prioritize educational clarity over advanced features
**Rationale:** This is a learning project; users can extend later
**Impact:** Some advanced features deferred (weighted placement, biome integration)

---

## Migration Plan

N/A - This is a new feature with no existing tactical generation to migrate.

**Integration with existing system:**
- Existing world generation remains unchanged
- TacticalMapGenerator exists alongside MapGenerator
- Users can choose to use world-only, tactical-only, or both
- Demonstrates how to extend modular architecture

---

## Open Questions

### Q1: Should tactical generation integrate directly with world tiles?
**A:** No, keep them decoupled initially. Users can manually link them (e.g., click world tile → generate tactical map). This keeps the implementation simple and educational.

### Q2: How many feature types should the initial implementation support?
**A:** Start with 5-8 feature types:
- Trees (2-3 variants)
- Rocks/Boulders (2 sizes)
- Bushes
- Flowers/grass tufts
Sufficient for learning without overwhelming complexity.

### Q3: Should features have collision or gameplay properties?
**A:** Optional, for educational purposes. TileSet can define collision, but TacticalMapGenerator doesn't need to handle gameplay logic. Keep it focused on procedural generation.

### Q4: Should different world terrain types (from world map) affect tactical generation?
**A:** Good future enhancement, but not required initially. Start with generic tactical maps. Later versions can pass world terrain as a parameter to influence tactical base terrain distribution.

---

## Implementation Notes

### Educational Focus
This implementation should:
- Include extensive comments explaining multi-layer noise
- Provide examples of different parameter combinations
- Document the relationship between frequency and visual scale
- Show before/after comparisons of density threshold effects

### Testing Strategy
- Unit test coordinate-to-seed derivation
- Visual testing of feature placement rules
- Performance profiling with various map sizes
- Reproducibility testing (same coordinates = same map)

### Documentation Deliverables
- TACTICAL_GENERATION_GUIDE.md (similar to TERRAIN_GENERATION_GUIDE.md)
- Inline code documentation for all classes
- Example parameter configurations (forest, rocky, sparse, dense)
- Troubleshooting guide for common issues

---

## Success Criteria

Implementation succeeds if:
- ✅ Generates 64×64 tactical map in < 100ms
- ✅ Same world coordinates produce identical tactical maps
- ✅ Features respect terrain placement rules
- ✅ Visual variety between different world positions
- ✅ No errors or warnings during generation
- ✅ Parameters are tunable via Inspector
- ✅ Code is well-documented and educational
- ✅ Demonstrates multi-layer noise composition clearly
