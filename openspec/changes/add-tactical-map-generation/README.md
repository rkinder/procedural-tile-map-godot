# Tactical Map Generation - Implementation Guide

This OpenSpec proposal defines a tactical-scale map generation system that builds on the existing world-scale noise terrain generation.

## Quick Overview

**What is this?**
A multi-layer procedural generation system that creates detailed 64×64 tactical maps showing individual trees, rocks, bushes, and terrain features.

**Why implement this?**
- Learn multi-layer noise composition
- Understand rule-based feature placement
- Practice coordinate transformation and seed derivation
- Build on existing world generation knowledge

**Estimated Implementation Time:** 8-16 hours for a learning implementation

## What You'll Build

### 4 Core Classes

1. **FeaturePlacementRules** - Defines which features can appear on which terrain
2. **MultiLayerNoiseGenerator** - Manages 3 noise instances (terrain, density, type)
3. **TacticalTileMapper** - Combines noise layers to decide terrain and features
4. **TacticalMapGenerator** - Orchestrates the whole system

### Key Concepts You'll Learn

- **Multi-Layer Noise:** Using multiple noise generators with different seeds and frequencies
- **Rule-Based Systems:** Defining and enforcing placement rules (trees on grass, not water)
- **Coordinate Derivation:** Generating deterministic seeds from world coordinates
- **Noise Composition:** Combining multiple noise values to make complex decisions

## Implementation Strategy

### Recommended Order

1. **Start Simple:** Build `TacticalSeedGenerator` first (coordinate → seed math)
2. **Build Rules:** Create `FeaturePlacementRules` (understand rule-based systems)
3. **Multi-Layer Noise:** Implement `MultiLayerNoiseGenerator` (reuses existing `NoiseGenerator`)
4. **Combine Layers:** Build `TacticalTileMapper` (uses rules + multi-layer noise)
5. **Orchestrate:** Create `TacticalMapGenerator` (brings it all together)
6. **Test & Tune:** Create demo scene and experiment with parameters

### Parallelizable Tasks

You can work on these independently:
- Creating tactical tileset assets (trees, rocks, bushes)
- Implementing `TacticalSeedGenerator` (just math)
- Building `FeaturePlacementRules` (no dependencies)
- Writing documentation as you learn

## Key Files to Create

### Scripts
```
scripts/
├── feature_placement_rules.gd       # Rule definitions
├── multi_layer_noise_generator.gd   # 3-layer noise orchestration
├── tactical_tile_mapper.gd          # Noise → terrain/features
├── tactical_map_generator.gd        # Main coordinator
└── tactical_seed_generator.gd       # Coordinate → seed math
```

### Assets
```
assets/tactical_tiles/
├── terrain/
│   ├── grass.svg
│   ├── dirt.svg
│   ├── stone.svg
│   └── ...
├── features/
│   ├── tree_oak.svg
│   ├── tree_pine.svg
│   ├── boulder.svg
│   └── ...
└── tactical_tileset.tres
```

### Scenes
```
scenes/
└── tactical_demo.tscn   # Demo scene with both TileMaps
```

### Documentation
```
TACTICAL_GENERATION_GUIDE.md   # Your learning documentation
```

## How It Works (Conceptual)

### The Three Noise Layers

```
For each tactical tile position (x, y):

1. TERRAIN NOISE (seed: base + 0)
   ↓
   Determines: What ground type? (grass, dirt, stone, sand)
   Frequency: 0.05-0.08 (medium detail)

2. DENSITY NOISE (seed: base + 1000)
   ↓
   Determines: Should we place a feature here?
   Threshold: 0.5 (50% of tiles have features)
   Frequency: 0.08-0.12 (creates clusters)

3. TYPE NOISE (seed: base + 2000)
   ↓
   Determines: Which specific feature? (oak, pine, boulder, etc.)
   Only sampled if density > threshold
   Frequency: 0.10-0.15 (fine variation)

Result: Base terrain + optional feature
```

### Seed Derivation

```
World Seed: 12345
World Position: (5, 10)
↓
Tactical Seed = 12345 + (5 × 10000) + 10 = 62355
↓
Terrain Layer:  62355 + 0    = 62355
Density Layer:  62355 + 1000 = 63355
Type Layer:     62355 + 2000 = 64355
```

This ensures:
- Same world position always generates same tactical map
- Different world positions generate different tactical maps
- Each noise layer is independent but deterministic

### Feature Placement Rules

```gdscript
Rules = {
    GRASS:  [TREE_OAK, TREE_PINE, BUSH, FLOWER],
    DIRT:   [ROCK_SMALL, BUSH],
    STONE:  [BOULDER, ROCK_SMALL],
    SAND:   [ROCK_SMALL],
    WATER:  []  # No features
}
```

When placing a feature:
1. Check terrain type at position
2. Get valid features for that terrain
3. If valid features exist AND density > threshold:
   - Use type noise to pick from valid features
   - Place that feature

## Testing Your Implementation

### Reproducibility Test
1. Generate tactical map for world position (5, 10)
2. Note what it looks like
3. Generate again for same position
4. They should be identical!

### Variety Test
1. Generate tactical map for position (5, 10)
2. Generate tactical map for position (5, 11)
3. They should look different!

### Rules Test
1. Look at water tiles - should have NO features
2. Look at grass tiles - should have trees, bushes, flowers
3. Look at stone tiles - should have boulders and rocks

### Performance Test
1. Enable `debug_timing = true`
2. Generate 64×64 map
3. Should complete in < 100ms

## Learning Checkpoints

After each section, you should understand:

**After TacticalSeedGenerator:**
- How to derive deterministic randomness from coordinates
- Why this enables reproducible but varied maps

**After FeaturePlacementRules:**
- How to design rule-based systems
- How to validate constraints

**After MultiLayerNoiseGenerator:**
- How multiple noise layers combine
- Why different frequencies create different scales

**After TacticalTileMapper:**
- How to combine multiple criteria (terrain + density + rules)
- How thresholds create binary decisions from continuous noise

**After TacticalMapGenerator:**
- How to orchestrate complex systems
- How to expose configuration via @export

## Common Pitfalls to Avoid

1. **Forgetting to derive unique layer seeds:** All layers need different seeds!
   - ❌ All layers use same seed → all layers identical
   - ✅ Each layer uses base_seed + offset → independent patterns

2. **Wrong frequency ranges:** Tactical scale needs higher frequency than world
   - ❌ Using 0.01 (world scale) → terrain too smooth
   - ✅ Using 0.05-0.15 → appropriate detail

3. **Not checking rules:** Features appear on wrong terrain
   - ❌ Placing trees without checking terrain → trees on water
   - ✅ Check rules first → natural placement

4. **Hardcoding values:** Makes experimentation difficult
   - ❌ Hardcoded thresholds in code
   - ✅ Use @export variables → tune in Inspector

## Integration with World Generation

While this proposal is self-contained, you can later integrate:

```gdscript
# In a world map click handler:
func _on_world_tile_clicked(world_x: int, world_y: int):
    var tactical_gen = get_node("TacticalMapGenerator")
    tactical_gen.world_position_x = world_x
    tactical_gen.world_position_y = world_y
    tactical_gen.generate_tactical_map()
```

## Resources

- Read `TERRAIN_GENERATION_GUIDE.md` first to understand single-layer noise
- Review `scripts/noise_generator.gd` to see what you're building on
- Review `scripts/tile_mapper.gd` to see the single-layer pattern

## Success Criteria

You've succeeded when:
- ✅ Same world position generates identical tactical maps
- ✅ Different positions generate varied maps
- ✅ Features only appear on valid terrain
- ✅ Generation completes in < 100ms for 64×64
- ✅ You can explain how multi-layer noise works
- ✅ You can tune parameters to create different map types

## Next Steps After Completion

Once you've mastered tactical generation:

1. **Add biome influence:** Pass world terrain type to affect tactical generation
2. **Weighted features:** Some features rarer than others
3. **Multi-biome support:** Forest has different features than desert
4. **Seasonal variations:** Same seed, different seasons
5. **Interactive features:** Resources to harvest, obstacles to navigate

---

**Ready to begin?** Start with `tasks.md` for the detailed implementation checklist!

Questions? The `design.md` has detailed technical decisions and rationale.
