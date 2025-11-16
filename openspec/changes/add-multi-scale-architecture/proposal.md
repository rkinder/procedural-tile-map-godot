# Proposal: Multi-Scale Map Architecture

## Why

The project requires a two-level map system where a strategic world map can be drilled down into detailed tactical maps. Currently, all proposals assume single-map generation at a single scale. Without multi-scale architecture, the system cannot support:

- Strategic world overview with selectable regions
- Detailed tactical maps that expand from world cells
- Separate modification policies (immutable world, modifiable tactical)
- Coordinate translation between world and tactical spaces
- Multiple concurrent tactical map instances

This architectural foundation is critical for the project's core use case: a strategy game with world map exploration and tactical detail views.

## What Changes

- **NEW**: WorldMap class for strategic-level map management
- **NEW**: TacticalMap class for detail-level map management
- **NEW**: MapCoordinator class to manage world↔tactical relationships
- **NEW**: Coordinate mapping system (world coords ↔ tactical coords)
- **NEW**: Tactical map instantiation on-demand from world cells
- **NEW**: Generation inheritance (world data influences tactical generation)
- **NEW**: Immutability controls for world maps
- **NEW**: Multi-map lifecycle management (loading/unloading tactical maps)

### Key Components

1. **WorldMap** - Strategic map with defined dimensions, largely immutable
2. **TacticalMap** - Detail maps instantiated from world cells, fully modifiable
3. **MapCoordinator** - Orchestrates relationships, instantiation, caching
4. **CoordinateMapper** - Translates between world and tactical coordinate spaces
5. **ScaleConfig** - Defines size relationships and scaling factors

## Impact

### Affected Specs
- **world-map** (NEW) - Strategic-level map capability
- **tactical-map** (NEW) - Detail-level map capability
- **map-coordinator** (NEW) - Multi-map orchestration
- **coordinate-mapping** (NEW) - Coordinate translation system

### Affected Code
- New files to be created:
  - `scripts/world_map.gd` - WorldMap class
  - `scripts/tactical_map.gd` - TacticalMap class
  - `scripts/map_coordinator.gd` - MapCoordinator class
  - `scripts/coordinate_mapper.gd` - CoordinateMapper class
  - `scripts/scale_config.gd` - ScaleConfig resource

### Dependencies
- **Requires**: `add-noise-terrain-generation` (noise generation capability)
- **Requires**: `add-generation-config` (configuration system)
- **Modifies**: `add-map-serialization` (extend to support tactical map modifications)
- **Modifies**: `add-map-persistence` (extend for multi-map saves - see add-hierarchical-persistence)
- **Influences**: `add-chunk-generation` (refocus on tactical chunks, not world streaming)

### Performance Considerations
- World map generation: one-time cost
- Tactical map generation: on-demand, cached
- Memory footprint: 1 world + N active tactical maps (configurable limit)
- Coordinate translation: O(1) operations

### Breaking Changes
- **BREAKING**: Generation architecture now hierarchical (world → tactical)
- **BREAKING**: MapGenerator needs to support scale-aware generation
- Migration path: existing single-map code becomes "tactical-only mode"
