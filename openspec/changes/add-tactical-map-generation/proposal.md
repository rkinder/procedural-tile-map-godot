# Proposal: Tactical-Scale Map Generation

## Why

The current noise-based terrain generation creates beautiful world-scale maps (continents, oceans, mountains). However, games often need **tactical-scale maps** - zoomed-in views showing individual trees, rocks, bushes, and terrain details for combat, exploration, or resource gathering.

This proposal extends the existing procedural generation system to create detailed tactical maps that:
- Derive from world map coordinates (each world tile can generate a unique tactical map)
- Use multi-layer noise for rich, varied environments
- Place features intelligently based on terrain type (trees on grass, rocks on stone, etc.)
- Maintain the same seed-based reproducibility for consistency

**Learning Objectives:**
- Understand multi-layer noise composition
- Learn feature placement algorithms and ruleset design
- Practice coordinate transformation (world → tactical scale)
- Explore performance optimization for denser maps

## What Changes

- **NEW**: Multi-layer noise generation system for tactical features
- **NEW**: Feature placement rules engine (trees, rocks, bushes, etc.)
- **NEW**: TacticalMapGenerator that orchestrates multiple noise layers
- **NEW**: Coordinate derivation system (world position → tactical seed)
- **NEW**: Feature-specific TileMaps for different object types
- **NEW**: Tactical tileset with terrain details and environmental objects

### Key Components

1. **FeaturePlacementRules** - Defines what features can appear on which terrain
2. **MultiLayerNoiseGenerator** - Manages multiple noise instances for different purposes
3. **TacticalTileMapper** - Maps noise combinations to specific features
4. **TacticalMapGenerator** - Orchestrates tactical-scale generation
5. **Tactical TileSet** - Trees, rocks, bushes, flowers, grass variants, etc.

### Generation Strategy

**Three-Layer Noise Approach:**
1. **Base Terrain** - Ground type (grass, dirt, stone, sand)
2. **Feature Density** - Where clusters of objects appear
3. **Feature Type** - Which specific feature to place

**Example Flow:**
```
World map position (5, 10) → Tactical map seed = base_seed + (5 * 10000) + 10
Generate 64×64 tactical tiles representing that world tile
Use higher frequency (0.05-0.1) for fine detail
Layer 1: Base terrain from terrain noise
Layer 2: Features from density + type noise
```

## Impact

### Affected Specs
- **noise-generation** (MODIFIED) - Document multi-instance usage patterns
- **tactical-map-generation** (NEW) - Core tactical generation system
- **feature-placement** (NEW) - Feature placement rules and logic

### Affected Code
- Existing files unchanged (backward compatible)
- New files to be created:
  - `scripts/feature_placement_rules.gd` - Feature placement ruleset
  - `scripts/multi_layer_noise_generator.gd` - Multi-noise orchestration
  - `scripts/tactical_tile_mapper.gd` - Feature-aware mapping
  - `scripts/tactical_map_generator.gd` - Tactical map coordinator
  - `scenes/tactical_demo.tscn` - Demo scene for tactical maps
  - `assets/tactical_tiles/` - Tactical-scale tileset

### Dependencies
- Builds on existing `NoiseGenerator` and `TileMapper` (reuses pattern)
- Requires new tactical tileset assets (trees, rocks, bushes, etc.)
- Compatible with existing world generation system

### Performance Considerations
- Tactical maps are smaller (64×64 typical) but denser
- Multiple noise evaluations per tile (3-4 layers)
- Target: < 100ms for 64×64 tactical map generation
- Feature placement adds overhead but remains lightweight

### Learning Path
This proposal is designed as a **hands-on learning project** to:
1. Apply knowledge from world generation to a new context
2. Understand noise composition and layering
3. Design and implement rule-based systems
4. Practice deriving deterministic randomness from coordinates
5. Optimize multi-layer generation for performance

### Extensibility
Foundation for future enhancements:
- Dynamic feature generation (different tree species per biome)
- Seasonal variations (winter, spring, summer, fall)
- Weather effects (rain puddles, snow coverage)
- Interactive features (harvestable resources, destructible objects)
- Pathfinding-aware placement (leave navigable corridors)
