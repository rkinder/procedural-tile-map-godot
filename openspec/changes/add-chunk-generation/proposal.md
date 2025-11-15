## Why
Generating entire 512x512 maps at once can cause performance issues and UI freezing. Chunk-based generation enables progressive loading, viewport-based generation for larger maps, and better memory management. This is **BREAKING** as it fundamentally changes the generation architecture.

## What Changes
- **BREAKING**: Refactor generation pipeline to operate on chunks instead of full maps
- Implement configurable chunk size (e.g., 16x16, 32x32 tiles per chunk)
- Add viewport-based chunk loading/unloading system
- Implement seamless chunk boundary handling for noise continuity
- Add progressive generation with yield points to prevent UI freezing
- Support both on-demand and pre-generation modes
- Add chunk caching and memory management

## Impact
- Affected specs: terrain-generation (MODIFIED - breaking change), biome-generation (MODIFIED)
- Affected code: Complete generator refactoring, TileMap integration changes
- **BREAKING**: Existing generation API changes (chunk-based instead of single-pass)
- Dependencies: Interacts with map-persistence (chunk-based saves)
- Performance: Improved for large maps, adds complexity for small maps
