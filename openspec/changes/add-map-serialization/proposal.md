## Why
Procedurally generated maps need to preserve both generated content and player modifications. Without a serialization system that tracks modification state, players lose edits when maps regenerate, and saves cannot distinguish between original procedural content and player changes. This prevents seamless save/load workflows and limits the ability to merge player modifications with regenerated chunks.

## What Changes
- Add map serialization system that tracks tile modification state (procedural vs. player-modified)
- Implement delta serialization to save only modified tiles for efficiency
- Store layer-specific modification metadata (which tiles were changed, when, by what action)
- Support merging player modifications when regenerating map chunks
- Add modification history tracking for undo/redo support
- Implement partial map serialization (save only dirty regions)

## Impact
- Affected specs: map-serialization (new capability)
- Affected code: New MapSerializer class, TileMap modification tracking, save/load integration
- Dependencies: May complement map-persistence for full vs. incremental saves
- Performance: Delta saves significantly faster than full map serialization for large maps
- Memory: Modification tracking adds small overhead per modified tile
