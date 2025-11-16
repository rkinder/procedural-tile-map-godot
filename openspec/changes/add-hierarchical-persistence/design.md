# Design: Hierarchical Map Persistence

## Context

Multi-scale architecture requires saving/loading one world map plus multiple tactical maps. Unlike single-map persistence, this involves:
- Coordinating saves across multiple files
- Tracking which tactical maps exist
- Maintaining referential integrity (tactical → world)
- Supporting incremental saves (don't resave unchanged maps)

## Goals / Non-Goals

**Goals:**
- Save world map independently from tactical maps
- Save only generated/visited tactical maps (not all possible maps)
- Track tactical map inventory in manifest file
- Support incremental saves (only modified tactical maps)
- Maintain referential integrity between world and tactical saves
- Enable efficient batch load/save of multiple tactical maps
- Provide progress feedback for multi-file operations

**Non-Goals:**
- Cloud storage or networked saves
- Automatic conflict resolution for concurrent saves
- Version control integration
- Compression across multiple files (each file compressed individually)
- Transactional save guarantees (all-or-nothing)

## Decisions

### Decision: Three-Part File Structure (Manifest + World + Tactical)

Organize saves as: manifest.json (inventory), world/ (world map), tactical/ (N tactical maps).

**Rationale:**
- Clear separation of concerns
- Manifest provides quick overview without loading map data
- World map isolated (rarely changes after initial generation)
- Tactical maps in dedicated folder for easy discovery
- Standard directory structure across all saves

**Alternatives considered:**
- Single monolithic file: inefficient, requires loading all tactical maps
- Flat structure (all files in one folder): cluttered, harder to manage
- Database (SQLite): overkill for file-based procedural generation

**Structure:**
```
saves/
└── campaign_name/
    ├── manifest.json              # Inventory + metadata
    ├── world/
    │   └── world_map.procmap
    └── tactical/
        ├── tactical_X_Y.procmap   # One file per world position
        └── ...
```

### Decision: Manifest File Tracks World Metadata and Tactical Inventory

Manifest contains world generation seed, dimensions, and list of saved tactical maps.

**Rationale:**
- Fast loading: know what tactical maps exist without scanning directory
- Metadata available without deserializing world map
- Supports validation (detect missing/orphaned tactical maps)
- JSON format: human-readable, debuggable, version-controllable

**Alternatives considered:**
- No manifest (scan directory): slower, no centralized metadata
- Manifest in world map file: requires loading world map to get inventory
- Separate inventory file: unnecessary duplication

**Manifest structure:**
```json
{
  "format_version": "1.0.0",
  "campaign_name": "My Campaign",
  "created_timestamp": 1699564800000,
  "last_saved_timestamp": 1699564900000,
  "world": {
    "seed": 12345,
    "dimensions": {"x": 256, "y": 256},
    "generation_config": { ... }
  },
  "tactical_maps": [
    {"world_position": {"x": 10, "y": 20}, "file": "tactical_10_20.procmap", "modified": true},
    {"world_position": {"x": 10, "y": 21}, "file": "tactical_10_21.procmap", "modified": false}
  ]
}
```

### Decision: Tactical Map Files Named by World Position

Tactical map files named `tactical_X_Y.procmap` where (X, Y) is world position.

**Rationale:**
- Self-documenting: filename indicates world position
- Easy to locate specific tactical map
- No collisions (one file per world position)
- Consistent naming convention

**Alternatives considered:**
- Hash-based names: less readable, harder to debug
- Sequential IDs: loses world position information
- UUID: overkill, no meaningful information

### Decision: Incremental Save Strategy (Modified Tactical Maps Only)

Save only tactical maps marked as modified since last save.

**Rationale:**
- Performance: avoid writing unchanged tactical maps
- Reduces I/O: most tactical maps don't change after initial generation
- Supports modification tracking from add-map-serialization
- Players only modify fraction of visited tactical maps

**Alternatives considered:**
- Always save all tactical maps: wasteful I/O, slow for many maps
- Save all loaded maps: still wastes I/O on unmodified maps
- Manual save selection: too complex for users

**Implementation:**
```gdscript
func save_campaign(campaign_path: String, coordinator: MapCoordinator):
    # Always save world map (small, infrequent changes)
    save_world_map(campaign_path, coordinator.world_map)

    # Save only modified tactical maps
    for pos in coordinator.tactical_cache.keys():
        var tactical = coordinator.tactical_cache[pos]
        if tactical.is_modified():
            save_tactical_map(campaign_path, tactical)
            mark_tactical_saved(pos)
```

### Decision: Referential Integrity via World Seed in Tactical Maps

Each tactical map file stores the world seed it was generated from.

**Rationale:**
- Validation: detect mismatched world/tactical saves
- Debugging: identify which world a tactical map belongs to
- Safety: prevent loading tactical map with wrong world
- Reproducibility: re-generate tactical if world seed changes

**Alternatives considered:**
- No validation: risk of mismatched saves causing bugs
- World ID/UUID: more complex, seed sufficient for unique identification
- Hash of world map: expensive to compute, seed simpler

**Validation:**
```gdscript
func load_tactical_map(file_path: String, world: WorldMap) -> TacticalMap:
    var tactical = deserialize_tactical(file_path)
    if tactical.world_seed != world.generation_seed:
        push_error("Tactical map world seed mismatch!")
        return null
    return tactical
```

### Decision: Batch Load/Save Operations for Performance

Provide methods to load/save multiple tactical maps in single operation with progress callbacks.

**Rationale:**
- Reduce per-file overhead (open/close operations)
- Enable progress UI (loading 50 tactical maps)
- Better error handling (partial failures)
- Async-friendly (can yield between batches)

**Alternatives considered:**
- Single-file operations only: caller must batch manually
- Automatic batching: hidden behavior, less control
- Background thread loading: complex, Godot threading limitations

**API:**
```gdscript
func batch_load_tactical_maps(
    campaign_path: String,
    positions: Array[Vector2i],
    progress_callback: Callable
) -> Dictionary:  # Vector2i -> TacticalMap
    var loaded = {}
    for i in range(positions.size()):
        var tactical = load_tactical_map(campaign_path, positions[i])
        loaded[positions[i]] = tactical
        if progress_callback:
            progress_callback.call(i + 1, positions.size())
    return loaded
```

### Decision: Manifest Updated After Each Save Operation

Manifest saved after every world/tactical save to keep inventory current.

**Rationale:**
- Consistency: manifest always reflects actual filesystem state
- Recovery: if save interrupted, manifest shows what was saved
- Simplicity: avoid complex transaction management

**Alternatives considered:**
- Manifest updated only on explicit flush: risks desync
- Transactional saves: complex, unnecessary for single-player game
- Manifest updated on load: doesn't capture saves

**Trade-off:** More I/O (write manifest frequently) vs consistency (always up-to-date)
**Decision:** Manifest writes are small/fast, consistency more important

## Risks / Trade-offs

**Risk:** Manifest can desync from actual files if files manually deleted
- **Mitigation:** Validate manifest on load, rescan tactical/ folder if mismatch detected

**Risk:** Many tactical maps (1000+) could slow manifest load/save
- **Mitigation:** JSON parsing is fast for thousands of entries; acceptable for this use case

**Risk:** Partial save failure leaves inconsistent state
- **Mitigation:** Save manifest last; if interrupted, manifest shows successful saves

**Trade-off:** File count vs file size
- **Impact:** Many small files (1 per tactical) vs fewer large files
- **Decision:** Many small files better for incremental saves, easier to manage

**Trade-off:** Incremental vs full saves
- **Impact:** Incremental saves faster but requires tracking modifications
- **Decision:** Incremental saves worth the complexity (uses existing modification tracking)

## Migration Plan

**Breaking Changes:** None (new capability)

**Integration Steps:**
1. Implement MapManifest class
2. Implement HierarchicalMapPersistence class
3. Extend MapPersistence to support save_world/save_tactical variants
4. Extend MapSerializer to include map_type metadata
5. Integrate with MapCoordinator for save/load operations
6. Add demo scene with save/load UI
7. Test with various numbers of tactical maps (1, 10, 100)

**Backward Compatibility:**
- Existing single-map saves still work (no migration needed)
- Hierarchical saves are new format, separate from single-map saves
- Provide conversion utility to migrate single tactical map to hierarchical format (future)

## Open Questions

- **Should manifest include tactical map modification counts?** → Yes, helpful for debugging
- **Should we support archiving (zipping) entire campaign folder?** → Defer to future enhancement
- **Should manifest track generation timestamps for each tactical map?** → Yes, include created/modified timestamps
- **How to handle orphaned tactical files (in folder but not in manifest)?** → Warn on load, optionally add to manifest or delete
- **Should we support partial campaign loads (world only, no tactical)?** → Yes, useful for world map browsing without loading tactical maps
