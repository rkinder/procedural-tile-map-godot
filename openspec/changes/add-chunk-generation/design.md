## Context
Chunk-based generation is a fundamental architectural change enabling scalability beyond 512x512 maps and preventing UI freezing during generation. This is a breaking change requiring significant refactoring.

## Goals / Non-Goals
**Goals:**
- Eliminate UI freezing during large map generation
- Enable viewport-based dynamic loading for infinite/large maps
- Maintain seamless noise continuity across chunk boundaries
- Support progressive generation with progress feedback
- Improve memory efficiency for very large maps

**Non-Goals:**
- Infinite maps (still limited to configured dimensions, but chunk system enables future expansion)
- Real-time terrain modification (separate capability)
- Network-synchronized chunk streaming (single-player only)

## Decisions

### Decision: 32x32 Tile Chunks as Default
Use 32x32 tiles per chunk as the default size, with 16x16 and 64x64 as alternatives.

**Rationale:**
- 32x32 = 1024 tiles per chunk: good balance of granularity vs. overhead
- Divides common map sizes evenly (512x512 = 16x16 chunks)
- Small enough for quick generation, large enough to minimize chunk count
- Aligns with common game chunk sizes (Minecraft uses 16x16 but our tiles are smaller)

**Alternatives considered:**
- 16x16: More chunks, more overhead, but finer loading granularity
- 64x64: Fewer chunks but larger generation units (more freezing risk)
- Variable chunk size: Complexity not justified for learning project

### Decision: Progressive Generation with Yield Points
Generate chunks incrementally across multiple frames using yield/await, generating 1-4 chunks per frame based on target framerate.

**Rationale:**
- Prevents UI freezing (generation spread across frames)
- User sees progressive map appearance (better UX)
- Cancellable generation (user can interrupt)
- Godot's `await` supports this pattern naturally

**Alternatives considered:**
- Background thread: More complex, Godot's threading limitations with TileMap
- Instant generation: Freezes UI, poor UX for large maps

### Decision: Viewport-Based Chunk Loading with Hysteresis
Load chunks within `load_radius` chunks of viewport, unload chunks beyond `unload_radius` (where `unload_radius > load_radius`).

**Rationale:**
- Hysteresis prevents thrashing (rapid load/unload cycles near boundary)
- Typical values: load_radius=3, unload_radius=5
- Ensures smooth experience as player moves

**Alternatives considered:**
- Fixed loaded region: Doesn't adapt to player movement
- No hysteresis: Causes thrashing and performance issues

### Decision: LRU Chunk Cache with Configurable Limit
Cache generated chunks in memory using Least Recently Used eviction, default limit ~100-200 chunks (depends on chunk size).

**Rationale:**
- Prevents regeneration cost when revisiting areas
- LRU evicts least-used chunks when memory limit reached
- Configurable limit allows tuning for target platform

**Alternatives considered:**
- No caching: Expensive regeneration on every revisit
- Infinite cache: Memory leaks for large maps
- Disk-based cache: Complexity; defer to map-persistence capability

### Decision: Noise Continuity via Absolute World Coordinates
Generate noise using absolute world coordinates (not chunk-relative), ensuring seamless boundaries.

**Rationale:**
- Noise function at (64, 64) returns same value regardless of which chunk is being generated
- No special boundary handling needed
- Simple and proven approach

**Alternatives considered:**
- Chunk-relative with boundary stitching: Complex, error-prone
- Overlap regions: Wasteful, harder to implement

## Risks / Trade-offs

**Risk:** Increased complexity compared to single-pass generation
- **Mitigation:** Encapsulate chunk logic in ChunkManager; generators mostly agnostic to chunking

**Risk:** Performance overhead for small maps (64x64)
- **Mitigation:** Allow instant generation mode for small maps; chunk system opt-in

**Risk:** Chunk boundary visual artifacts if noise continuity fails
- **Mitigation:** Thorough testing; use absolute coordinates for noise sampling

**Trade-off:** Memory usage vs. regeneration cost
- **Impact:** Cached chunks use memory; no cache requires regeneration
- **Decision:** Configurable cache limit allows user/developer control

**Trade-off:** Chunk size selection
- **Impact:** Smaller chunks = more granular loading but more overhead
- **Decision:** Provide presets; document trade-offs

## Migration Plan
**Breaking Changes:**
1. Generator API changes: `generate_map()` → `generate_chunk(chunk_coords)`
2. TileMap population now chunk-based instead of single-pass
3. Configuration must include chunk size parameter

**Migration Steps:**
1. Implement new chunk-based system alongside old system temporarily
2. Add compatibility layer for old `generate_map()` API (calls chunk generation internally)
3. Update all examples and tests to use new API
4. Deprecate old API in documentation
5. Remove old API in next major version (if this becomes production)

**Backward Compatibility:**
- Provide `generate_map_legacy()` wrapper that generates all chunks at once
- Document migration path clearly
- Saved maps from old system can still be loaded (map-persistence handles data, not generation method)

## Open Questions
- Should chunk generation be deterministic given same seed? → Yes, absolute coordinates ensure determinism
- What's the optimal chunk generation rate (chunks per frame)? → Start with 2-4, make configurable, measure framerate impact
- Should we support different chunk sizes for different layers (terrain vs. objects)? → No, uniform chunk size for simplicity
- How to handle maps smaller than chunk size (e.g., 16x16 map with 32x32 chunks)? → Use single chunk, or reduce chunk size automatically
