# Proposal: Hierarchical Map Persistence

## Why

With multi-scale architecture (world + tactical maps), the persistence system needs to manage multiple related maps rather than a single standalone map. The current `add-map-persistence` proposal assumes single-map saves. Without hierarchical persistence:

- Cannot save world map separately from tactical maps
- Cannot efficiently persist only visited tactical maps (not all 65K+ possible maps)
- Cannot track which tactical maps have been generated/modified
- Cannot maintain referential integrity between world and tactical saves
- Cannot support incremental saves (world once, tactical as visited)

This capability is essential for the multi-scale architecture to function as a complete game system.

## What Changes

- **NEW**: Multi-map save/load architecture for world + N tactical maps
- **NEW**: Hierarchical file structure (world folder + tactical subfolder)
- **NEW**: Manifest file tracking generated tactical map list
- **NEW**: Referential integrity (tactical saves reference world seed/ID)
- **NEW**: Incremental save strategy (world once, tactical as modified)
- **NEW**: Batch load/save operations for multiple tactical maps
- **MODIFIED**: MapPersistence extended to support hierarchical saves
- **MODIFIED**: MapSerializer updated to include map type (world vs tactical)

### Key Components

1. **HierarchicalMapPersistence** - Manages multi-map save/load operations
2. **MapManifest** - Tracks world metadata and tactical map inventory
3. **World/Tactical file structure** - Organized directory hierarchy
4. **Incremental save** - Save only modified tactical maps
5. **Batch operations** - Load multiple tactical maps efficiently

## Impact

### Affected Specs
- **hierarchical-persistence** (NEW) - Multi-map save/load system
- **map-manifest** (NEW) - World + tactical map inventory tracking

### Affected Code
- New files to be created:
  - `scripts/hierarchical_map_persistence.gd` - Multi-map persistence manager
  - `scripts/map_manifest.gd` - Map inventory and metadata
- Modified files:
  - Extend `scripts/map_persistence.gd` (from add-map-persistence) for multi-map support
  - Extend `scripts/map_serializer.gd` (from add-map-serialization) for map type metadata

### Dependencies
- **Requires**: `add-multi-scale-architecture` (WorldMap, TacticalMap, MapCoordinator)
- **Requires**: `add-map-persistence` (base persistence capability)
- **Requires**: `add-map-serialization` (modification tracking for tactical maps)
- **Extends**: `add-map-persistence` and `add-map-serialization` with multi-map support

### File Structure

```
saves/campaign_name/
├── manifest.json                  # World metadata + tactical inventory
├── world/
│   └── world_map.procmap          # Strategic map (rarely changes)
└── tactical/
    ├── tactical_10_20.procmap     # Per-region tactical maps
    ├── tactical_10_21.procmap
    └── tactical_50_75.procmap
```

### Performance Considerations
- World map: save once, load once per campaign
- Tactical maps: save on modification, load on-demand
- Manifest: small JSON file, fast load/save
- Batch operations: reduce I/O overhead for multiple tactical loads

### Breaking Changes
- **MODIFIED**: MapPersistence API extended (backward compatible)
- **NEW**: Hierarchical save format (new capability, no migration needed)
