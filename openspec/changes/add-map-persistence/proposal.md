## Why
Regenerating large procedural maps on every load is inefficient and prevents map modifications from being preserved. A persistence system allows users to save generated maps with their metadata, load them instantly, and preserve manual edits.

## What Changes
- Add map serialization system supporting multiple formats (JSON, binary, Godot Resource)
- Implement compression for efficient storage of 512x512 maps
- Store generation metadata (seed, config parameters, timestamp)
- Add validation for loaded map data to prevent corruption/crashes
- Support incremental saves for modified maps
- Implement version compatibility system for future format changes

## Impact
- Affected specs: map-persistence (new capability)
- Affected code: New save/load system, TileMap integration
- Dependencies: Requires generation-config for metadata storage
- Performance: Large maps (512x512) require compression
- Security: Must validate loaded data to prevent malicious files
