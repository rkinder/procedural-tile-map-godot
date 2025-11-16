## Context
Map serialization must handle both procedurally generated content and player modifications. The system needs to distinguish between original procedural tiles and player edits, support efficient delta saves, enable undo/redo, and allow merging modifications with regenerated content. This requires careful data structure design, memory optimization, and serialization format decisions.

## Goals / Non-Goals
**Goals:**
- Track modification state for each tile with minimal memory overhead
- Support delta saves that only serialize changed tiles
- Enable undo/redo of player modifications
- Merge player edits onto regenerated procedural content
- Provide multiple serialization formats (JSON, binary, Godot Resource)
- Maintain O(1) or O(log n) lookup performance for modification queries

**Non-Goals:**
- Network synchronization of modifications (local only)
- Conflict resolution for multi-user editing (single-player focus)
- Version control integration (beyond human-readable JSON format)
- Automatic modification compression beyond delta saves
- Real-time collaborative editing

## Decisions

### Decision: Sparse Dictionary-Based Modification Storage
Use a Dictionary (hash map) keyed by Vector2i tile coordinates to store only modified tiles, not the entire map grid.

**Rationale:**
- Memory efficient: only store modified tiles (typical < 5% of map)
- O(1) lookup performance for modification queries
- Easy to iterate over modified tiles for delta serialization
- Natural fit for GDScript's built-in Dictionary type

**Alternatives considered:**
- Dense array (512x512): wastes memory for mostly unmodified maps
- Quadtree: more complex, O(log n) lookup, unnecessary for tile-level granularity
- Separate modification layer TileMap: cleaner but less flexible for metadata

**Data structure:**
```gdscript
# ModificationTracker class
var modifications: Dictionary = {}  # Vector2i -> TileModification

class TileModification:
    var position: Vector2i
    var layer: int
    var original_tile_id: int
    var new_tile_id: int
    var timestamp: int  # Unix timestamp in milliseconds
    var modification_type: ModificationType  # PLAYER_EDIT, BATCH_EDIT, etc.
```

### Decision: Delta File Format with Modification List
Store only modified tiles in delta files, with header metadata and optional checksums.

**Rationale:**
- Drastically reduces file size for maps with few modifications
- Fast save/load for incremental changes
- Supports merging multiple delta files
- Enables partial region saves

**Alternatives considered:**
- Always save full map: simple but inefficient for large maps with few edits
- Binary diff format: complex, overkill for discrete tile changes
- Patch-based system: unnecessary complexity for tile-based data

**Delta file structure (JSON format):**
```json
{
  "format_version": "1.0.0",
  "map_id": "generated_map_12345",
  "delta_timestamp": 1699564800000,
  "map_dimensions": {"x": 512, "y": 512},
  "modifications": [
    {
      "position": {"x": 100, "y": 50},
      "layer": 0,
      "original_tile_id": 3,
      "new_tile_id": 7,
      "timestamp": 1699564750000
    }
  ],
  "checksum": "sha256:abc123..."
}
```

### Decision: Circular Buffer for Undo/Redo History
Implement undo/redo using a fixed-size circular buffer to limit memory usage.

**Rationale:**
- Predictable memory usage (e.g., last 100 operations)
- Simple implementation with array and head/tail pointers
- Automatic eviction of oldest history when limit reached
- Fast O(1) push/pop operations

**Alternatives considered:**
- Unlimited history: unbounded memory growth
- Command pattern with full state snapshots: too memory-intensive for tiles
- Event sourcing: overkill for simple undo/redo

**Implementation approach:**
```gdscript
class UndoRedoStack:
    var history: Array[TileModification] = []
    var max_size: int = 100
    var current_index: int = -1

    func push(modification: TileModification):
        # Truncate redo history if we're in the middle
        history.resize(current_index + 1)
        history.append(modification)
        if history.size() > max_size:
            history.pop_front()
        else:
            current_index += 1
```

### Decision: Player-First Conflict Resolution for Procedural Merge
When merging player modifications onto regenerated content, player edits always take precedence by default.

**Rationale:**
- Preserves player intent and effort
- Prevents loss of manual work during regeneration
- Matches user expectations (edits are sacred)
- Simple, predictable behavior

**Alternatives considered:**
- Procedural-first: confusing, players lose work
- Configurable policy: adds complexity, rare use case
- Interactive conflict resolution: too complex for tile-level edits

**Merge algorithm:**
```
1. Regenerate procedural content for target region
2. For each tile in region:
   a. If tile has modification entry, use modified tile
   b. Else use newly generated procedural tile
3. Update modification timestamps for merged region
```

### Decision: Support Three Serialization Formats
Provide JSON (debug/version control), binary (production), and Godot Resource (.tres) formats.

**Rationale:**
- JSON: human-readable, git-friendly, easy debugging
- Binary: compact, fast, production-ready
- .tres: Godot native, inspector integration, familiar to Godot users

**Alternatives considered:**
- Single format (binary only): less flexible, harder to debug
- Custom text format: reinventing JSON
- MessagePack or similar: external dependency, unnecessary complexity

**Format selection strategy:**
- Auto-detect on load based on file extension or magic bytes
- Allow explicit format specification for save
- Default to binary for production, JSON for development

### Decision: Layer-Independent Modification Tracking
Track modifications separately for each TileMap layer (terrain, decoration, collision).

**Rationale:**
- Layers often modified independently (e.g., only change decorations)
- Allows layer-selective serialization (save only modified layers)
- Cleaner separation of concerns
- Supports multi-layer workflow

**Alternatives considered:**
- Single modification tracker for all layers: simpler but less flexible
- Per-layer separate systems: duplicated code, harder to manage
- Flattened single-layer model: loses Godot TileMap structure

**Implementation:**
```gdscript
# ModificationTracker
var layer_modifications: Dictionary = {}  # int (layer) -> Dictionary (Vector2i -> TileModification)
```

### Decision: Coordinate-Based Checksums for Integrity
Use SHA-256 checksums of serialized modification data to detect corruption.

**Rationale:**
- Detects file corruption, transmission errors, malicious edits
- Standard cryptographic hash ensures reliability
- Minimal performance overhead (hash computation fast for small data)

**Alternatives considered:**
- No checksums: risky, silent corruption possible
- CRC32: faster but less robust
- Per-tile checksums: overkill, too much overhead

## Risks / Trade-offs

**Risk:** Dictionary-based storage may have overhead for very small modification counts
- **Mitigation:** Acceptable trade-off; Dictionary overhead negligible vs. benefits

**Risk:** Delta files accumulate over time, requiring periodic consolidation
- **Mitigation:** Implement merge tool; document best practices for consolidation

**Risk:** Undo history persistence increases save file size
- **Mitigation:** Make history persistence optional; allow configurable depth

**Trade-off:** Three serialization formats vs. single format
- **Impact:** More code to maintain, more testing needed
- **Decision:** Worth it for flexibility (JSON for debug, binary for production)

**Trade-off:** Player-first conflict resolution vs. configurable policy
- **Impact:** Less flexible, but simpler and more predictable
- **Decision:** Start with player-first; add configuration if users request it

## Migration Plan
This is a new capability. Integration steps:
1. Implement core data structures (TileModification, ModificationTracker)
2. Add modification tracking to TileMap wrapper
3. Implement delta serialization (JSON format first)
4. Add undo/redo system
5. Implement merge algorithm for procedural-modified integration
6. Add binary and .tres formats
7. Integrate with save/load UI
8. Benchmark and optimize
9. Document and provide examples

No migration of existing data (no modification tracking exists yet).

## Open Questions
- Should we support modification annotations (player notes, tags)? → Defer to future enhancement
- Should undo/redo be global or per-layer? → Start with global, evaluate per-layer if needed
- How to handle tileset changes that invalidate modification data? → Validate on load, use fallback tiles
- Should we support modification diffs between two save states? → Defer to future feature
- What's the optimal undo history depth? → Default 100, make configurable, benchmark memory usage
