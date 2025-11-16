# OpenSpec Proposals Summary

## Overview

Two new OpenSpec proposals have been created to address the architectural gaps identified for supporting a two-level (world/tactical) map system.

## Created Proposals

### 1. add-multi-scale-architecture

**Status:** Validated ✅
**Tasks:** 194
**Location:** `openspec/changes/add-multi-scale-architecture/`

**Purpose:**
Implements the core multi-scale architecture enabling a strategic world map with expandable tactical detail maps.

**Key Capabilities:**

- **world-map** - Strategic-level map (largely immutable)
- **tactical-map** - Detail-level maps (fully modifiable)
- **map-coordinator** - Orchestrates world↔tactical relationships, caching, lifecycle
- **coordinate-mapping** - Translates between world and tactical coordinate spaces

**Key Components:**
- `WorldMap` - Strategic map with metadata per cell
- `TacticalMap` - Detail maps with modification tracking
- `MapCoordinator` - Singleton managing map relationships and LRU cache
- `CoordinateMapper` - Coordinate translation utilities
- `ScaleConfig` - Configuration for world/tactical dimensions
- `TacticalGenerationContext` - World context passed to tactical generation

**Design Highlights:**
- Two-level hierarchy (world → tactical), not arbitrary N-levels
- On-demand tactical instantiation with LRU caching (default 50 maps)
- Deterministic tactical generation via position-seeded noise
- Generation inheritance (world biome/elevation influences tactical)
- World map immutability via locked modification flag
- Separate WorldMap and TacticalMap classes (composition over inheritance)

### 2. add-hierarchical-persistence

**Status:** Validated ✅
**Tasks:** 197
**Location:** `openspec/changes/add-hierarchical-persistence/`

**Purpose:**
Enables saving and loading campaigns with one world map plus multiple tactical maps using an organized file structure.

**Key Capabilities:**

- **hierarchical-persistence** - Multi-map save/load system
- **map-manifest** - Campaign metadata and tactical map inventory

**Key Components:**
- `HierarchicalMapPersistence` - Multi-map save/load operations
- `MapManifest` - Tracks world metadata and tactical map list
- File structure: `campaign/manifest.json`, `campaign/world/`, `campaign/tactical/`
- Incremental saves (only modified tactical maps)
- Batch load/save operations with progress callbacks

**Design Highlights:**
- Three-part structure: manifest + world folder + tactical folder
- Tactical maps named by world position: `tactical_X_Y.procmap`
- Incremental save strategy (world always, tactical if modified)
- Referential integrity (tactical maps validate against world seed)
- Manifest updated after each save for consistency
- Graceful error handling for missing/corrupted files

**File Structure Example:**
```
saves/my_campaign/
├── manifest.json              # Inventory + metadata
├── world/
│   └── world_map.procmap
└── tactical/
    ├── tactical_10_20.procmap
    ├── tactical_10_21.procmap
    └── tactical_50_75.procmap
```

## Addressing Architecture Assessment Gaps

### Critical Gaps Resolved

| Gap | Status | Addressed By |
|-----|--------|-------------|
| **Multi-scale architecture** | ✅ Resolved | add-multi-scale-architecture |
| **Coordinate mapping** | ✅ Resolved | add-multi-scale-architecture (coordinate-mapping spec) |
| **Tactical instantiation** | ✅ Resolved | add-multi-scale-architecture (map-coordinator spec) |
| **Generation inheritance** | ✅ Resolved | add-multi-scale-architecture (TacticalGenerationContext) |
| **Separate persistence** | ✅ Resolved | add-hierarchical-persistence |
| **World immutability** | ✅ Resolved | add-multi-scale-architecture (world-map spec) |

## Integration with Existing Proposals

### Dependencies

**add-multi-scale-architecture** depends on:
- `add-noise-terrain-generation` - Noise generation for both world and tactical
- `add-generation-config` - Configuration system (extended with ScaleConfig)

**add-hierarchical-persistence** depends on:
- `add-multi-scale-architecture` - WorldMap, TacticalMap, MapCoordinator
- `add-map-persistence` - Base persistence capability (extended)
- `add-map-serialization` - Modification tracking for tactical maps

### Modifications to Existing Proposals

**add-generation-config** - Extended with:
- `scale_config: ScaleConfig` property
- `enable_multi_scale: bool` flag

**add-map-persistence** - Extended with:
- `save_with_metadata()` method (includes map_type, world_seed)
- `load_with_validation()` method (validates map_type)

**add-map-serialization** - Extended with:
- `map_type` field ("world" or "tactical")
- `world_seed` field for referential integrity

**add-chunk-generation** - May be refocused:
- Original intent: streaming large single-scale maps
- New focus: tactical map chunks (if needed for very large tactical maps)
- Recommendation: Implement multi-scale first, then evaluate if chunk generation needed

## Updated Roadmap Integration

### Recommended Phase Insertion

**Phase 2.5: Multi-Scale Architecture** (new phase)
- Duration: 3-4 weeks
- Proposals: `add-multi-scale-architecture`, `add-hierarchical-persistence`
- Dependencies: Phase 1 (noise generation), Phase 2 (biomes)

**Updated Timeline:**

| Phase | Proposals | Duration | Focus |
|-------|-----------|----------|-------|
| Phase 1 | noise-terrain, generation-config | 2-3 weeks | Foundation |
| Phase 2 | biome-generation | 2-3 weeks | Variety |
| **Phase 2.5** | **multi-scale-architecture, hierarchical-persistence** | **3-4 weeks** | **Multi-scale** |
| Phase 3 | chunk-generation*, generator-plugins | 3-4 weeks | Scalability |
| Phase 4 | map-serialization | 2-3 weeks | State mgmt |

**Total:** ~16 weeks (4 months)

*chunk-generation may be deferred or refocused based on multi-scale needs

## Implementation Order

### Recommended Sequence

1. **Phase 1: Foundation**
   - ✅ Implement `add-noise-terrain-generation`
   - ✅ Implement `add-generation-config`

2. **Phase 2: Enhanced Generation**
   - ✅ Implement `add-biome-generation`

3. **Phase 2.5: Multi-Scale** (NEW)
   - ⚠️ Implement `add-multi-scale-architecture` first
   - ⚠️ Implement `add-hierarchical-persistence` second (depends on multi-scale)

4. **Phase 3: Extensibility**
   - Implement `add-generator-plugins`
   - Evaluate `add-chunk-generation` (may refocus on tactical chunks)

5. **Phase 4: State Management**
   - Implement `add-map-serialization` (modification tracking)
   - `add-map-persistence` already integrated via hierarchical-persistence

### Why Multi-Scale Before Plugins/Chunks?

- **Architectural Foundation**: Multi-scale is fundamental to the use case
- **Dependencies**: Persistence and serialization need multi-scale structure
- **Risk Reduction**: Validate architecture before adding complexity (plugins, chunks)
- **User Value**: Enables core gameplay loop earlier (world → tactical → modify → save)

## Testing Strategy

### Multi-Scale Architecture Tests

- Coordinate mapping (world ↔ tactical) correctness
- Tactical instantiation and caching (LRU eviction)
- Deterministic generation (same position = same seed)
- Generation inheritance (world context → tactical generation)
- World immutability enforcement
- MapCoordinator cache management

### Hierarchical Persistence Tests

- Campaign save/load round-trip
- Incremental saves (only modified tactical maps)
- Batch operations with progress callbacks
- Referential integrity validation
- Manifest accuracy (matches filesystem)
- Error handling (missing files, corrupted data)
- Performance with 10, 100 tactical maps

### Integration Tests

- Full workflow: generate world → visit tactical → modify → save → load → verify
- World regeneration with existing tactical modifications
- Cache eviction → save → load → verify modifications preserved
- Campaign deletion and cleanup

## Next Steps

1. **Review Proposals** - Stakeholder review of both proposals
2. **Refine Requirements** - Address any clarifications or questions
3. **Update Roadmap** - Officially insert Phase 2.5 in project roadmap
4. **Begin Implementation** - Start with `add-multi-scale-architecture`
5. **Continuous Validation** - Test multi-scale before moving to hierarchical-persistence

## Files Created

### Proposals
- `openspec/changes/add-multi-scale-architecture/proposal.md`
- `openspec/changes/add-multi-scale-architecture/design.md`
- `openspec/changes/add-multi-scale-architecture/tasks.md`
- `openspec/changes/add-hierarchical-persistence/proposal.md`
- `openspec/changes/add-hierarchical-persistence/design.md`
- `openspec/changes/add-hierarchical-persistence/tasks.md`

### Specs
- `openspec/changes/add-multi-scale-architecture/specs/world-map/spec.md`
- `openspec/changes/add-multi-scale-architecture/specs/tactical-map/spec.md`
- `openspec/changes/add-multi-scale-architecture/specs/map-coordinator/spec.md`
- `openspec/changes/add-multi-scale-architecture/specs/coordinate-mapping/spec.md`
- `openspec/changes/add-hierarchical-persistence/specs/hierarchical-persistence/spec.md`
- `openspec/changes/add-hierarchical-persistence/specs/map-manifest/spec.md`

### Documentation
- `docs/ARCHITECTURE_ASSESSMENT.md` - Gap analysis
- `docs/OPENSPEC_PROPOSALS_SUMMARY.md` - This file

## Validation Status

Both proposals validated successfully with `openspec validate --strict`:

```
✅ add-multi-scale-architecture is valid (194 tasks)
✅ add-hierarchical-persistence is valid (197 tasks)
```

All requirements have:
- Proper SHALL/MUST normative language
- At least one scenario per requirement
- Clear acceptance criteria
- Comprehensive test coverage

## Questions for Stakeholder

1. **World Map Dimensions**: Confirm target world map size (256x256 recommended)
2. **Tactical Map Dimensions**: Confirm tactical map size per world cell (64x64 recommended)
3. **World Immutability**: Should world map be fully immutable or allow limited edits?
4. **Tactical Persistence**: Should tactical maps always persist, or allow regeneration option?
5. **Cache Size**: Default 50 cached tactical maps acceptable, or adjust based on target platform?
6. **Phase Priority**: Agree on Phase 2.5 insertion before Phases 3-4?

## Summary

Two comprehensive OpenSpec proposals have been created that fully address the multi-scale architecture requirements:

1. **add-multi-scale-architecture** - Implements world/tactical map system with coordinate mapping, generation inheritance, and lifecycle management
2. **add-hierarchical-persistence** - Enables saving/loading campaigns with organized file structure and incremental saves

Both proposals are validated, well-documented, and ready for stakeholder review and implementation.
