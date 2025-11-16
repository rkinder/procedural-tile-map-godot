## ADDED Requirements

### Requirement: Tile Modification State Tracking
The system SHALL track the modification state of each tile, distinguishing between procedurally generated and player-modified tiles.

#### Scenario: Player modifies a tile
- **WHEN** a player changes a tile from grass to stone
- **THEN** the tile is marked as player-modified
- **AND** the original procedural tile type is preserved in metadata
- **AND** the modification timestamp is recorded

#### Scenario: Procedurally generated tile remains unchanged
- **WHEN** a tile is generated procedurally and never modified
- **THEN** the tile is marked as procedural-only
- **AND** no modification metadata is stored for that tile
- **AND** the tile can be regenerated without losing data

#### Scenario: Multiple modifications to same tile
- **WHEN** a player modifies the same tile multiple times
- **THEN** only the most recent modification state is preserved
- **AND** the modification count is incremented
- **AND** the latest modification timestamp is updated

### Requirement: Delta Serialization
The system SHALL support delta serialization, saving only modified tiles rather than the entire map.

#### Scenario: Incremental save with few modifications
- **WHEN** a player modifies 100 tiles out of 262,144 total tiles
- **THEN** only the 100 modified tiles are serialized
- **AND** the save operation completes in under 50ms
- **AND** the save file size is proportional to modifications, not map size

#### Scenario: Full map serialization option
- **WHEN** a full map save is explicitly requested
- **THEN** all tiles are serialized regardless of modification state
- **AND** the save includes both procedural and modified tiles
- **AND** the save can be loaded without access to original generation config

#### Scenario: Delta save merging
- **WHEN** multiple delta saves exist for the same map
- **THEN** the system can merge them into a single consolidated state
- **AND** later modifications override earlier ones for the same tile
- **AND** the merged state reflects the correct modification history

### Requirement: Modification Metadata Storage
The system SHALL store metadata for each modification including tile coordinates, original value, new value, and timestamp.

#### Scenario: Modification metadata capture
- **WHEN** a tile at position (100, 50) is changed from type 3 to type 7
- **THEN** metadata records position (100, 50)
- **AND** original tile type 3 is stored
- **AND** new tile type 7 is stored
- **AND** timestamp of modification is captured

#### Scenario: Batch modification metadata
- **WHEN** a player uses a brush tool to modify 50 tiles at once
- **THEN** each tile modification is recorded with shared timestamp
- **AND** batch operation is tracked as a single modification event
- **AND** undo can revert the entire batch atomically

### Requirement: Layer-Specific Serialization
The system SHALL support serialization of multiple TileMap layers with independent modification tracking.

#### Scenario: Multi-layer modification tracking
- **WHEN** a map has terrain, decoration, and collision layers
- **THEN** each layer tracks modifications independently
- **AND** saving only affects layers with modifications
- **AND** loading restores each layer's modification state correctly

#### Scenario: Layer-selective save
- **WHEN** only the decoration layer has been modified
- **THEN** the save can include only the decoration layer deltas
- **AND** other layers are not saved unnecessarily
- **AND** loading merges decoration deltas with existing terrain layer

### Requirement: Modification History for Undo/Redo
The system SHALL maintain a modification history that supports undo and redo operations.

#### Scenario: Single-step undo
- **WHEN** a player places a tile and then requests undo
- **THEN** the tile is reverted to its previous state
- **AND** the modification tracking is rolled back
- **AND** the tile is marked as procedural if it was originally generated

#### Scenario: Multi-step undo/redo
- **WHEN** a player makes 10 modifications and undoes 5 of them
- **THEN** the modification history preserves all 10 operations
- **AND** redo can restore the 5 undone modifications
- **AND** the current state reflects the 5 remaining modifications

#### Scenario: Undo history persistence
- **WHEN** a map with modification history is saved
- **THEN** the undo/redo stack is optionally saved
- **AND** loading the map restores the undo capability
- **AND** the history depth is configurable (e.g., last 100 operations)

### Requirement: Procedural-Modified Merge Support
The system SHALL support merging player modifications onto regenerated procedural content.

#### Scenario: Regenerate with preserved modifications
- **WHEN** a map region is regenerated with a different seed
- **THEN** player modifications in that region are preserved
- **AND** modified tiles override newly generated tiles
- **AND** unmodified tiles receive the new procedural content

#### Scenario: Selective region regeneration
- **WHEN** regenerating a 64x64 chunk within a larger map
- **THEN** player modifications within the chunk are preserved
- **AND** modifications outside the chunk are unchanged
- **AND** procedural content in the chunk is regenerated only for unmodified tiles

#### Scenario: Modification conflict resolution
- **WHEN** regeneration would conflict with player modifications
- **THEN** player modifications take precedence by default
- **AND** the conflict resolution policy is configurable
- **AND** a report of overridden procedural changes is available

### Requirement: Partial Map Serialization
The system SHALL support saving only specific regions or chunks of the map, not just the entire map.

#### Scenario: Region-based save
- **WHEN** saving a rectangular region from (0,0) to (100,100)
- **THEN** only tiles within that region are serialized
- **AND** the save file includes region boundary metadata
- **AND** loading applies tiles only to the specified region

#### Scenario: Chunk-based incremental save
- **WHEN** a map is divided into 64x64 chunks
- **THEN** individual chunks can be saved independently
- **AND** loading can load specific chunks on demand
- **AND** modification tracking works per-chunk for efficiency

#### Scenario: Dirty region optimization
- **WHEN** only a small corner of a large map has modifications
- **THEN** the save automatically detects and saves only dirty regions
- **AND** save time is proportional to modified area, not total map size
- **AND** the optimization threshold is configurable

### Requirement: Serialization Format Compatibility
The system SHALL serialize modification data in a format compatible with standard map persistence formats (JSON, binary, Godot Resource).

#### Scenario: JSON format with modifications
- **WHEN** a map with modifications is saved to JSON
- **THEN** the JSON includes a modifications array
- **AND** each modification has coordinates, original, new value, and timestamp
- **AND** the file is human-readable and version-control friendly

#### Scenario: Binary format with modifications
- **WHEN** a map with modifications is saved to binary format
- **THEN** modification data is efficiently packed
- **AND** file size is minimized through delta encoding
- **AND** loading from binary is faster than JSON for large modification sets

#### Scenario: Godot Resource format with modifications
- **WHEN** a map is saved as a .tres resource
- **THEN** modifications are stored as Godot Array/Dictionary structures
- **AND** the resource can be inspected in the Godot editor
- **AND** modification metadata integrates with Godot's resource system

### Requirement: Efficient Memory Usage
The system SHALL minimize memory overhead for modification tracking, using sparse data structures for large maps.

#### Scenario: Sparse modification storage
- **WHEN** a 512x512 map has only 1000 modified tiles
- **THEN** memory usage is proportional to 1000 tiles, not 262,144
- **AND** lookup performance for modification state is O(1) or O(log n)
- **AND** iteration over modified tiles is efficient

#### Scenario: Memory footprint limits
- **WHEN** modification tracking is active
- **THEN** memory overhead per modified tile is under 64 bytes
- **AND** total overhead for typical edits (< 5% of map) is under 10MB
- **AND** memory is released when modifications are cleared or saved

### Requirement: Validation and Integrity Checks
The system SHALL validate serialized modification data to prevent corruption and ensure consistency.

#### Scenario: Modification data validation
- **WHEN** loading modification data from a file
- **THEN** tile coordinates are validated against map dimensions
- **AND** tile types are validated against current tileset
- **AND** invalid modifications are rejected with clear error messages

#### Scenario: Timestamp consistency validation
- **WHEN** modification timestamps are loaded
- **THEN** timestamps are checked for chronological consistency
- **AND** future timestamps are rejected or flagged
- **AND** timestamp format is validated

#### Scenario: Checksum verification for modifications
- **WHEN** a modification delta file includes a checksum
- **THEN** the checksum is verified on load
- **AND** corrupted files are rejected
- **AND** partial corruption is detected and reported
