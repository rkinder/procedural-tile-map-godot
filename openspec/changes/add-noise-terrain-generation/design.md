# Technical Design: Core Noise-Based Terrain Generation

## Context

This is the first implementation in a learning project focused on procedural tile map generation. The system must be:
- Simple enough to understand for learning purposes
- Modular enough to be portable to other projects
- Extensible enough to support future enhancements (biomes, rivers, etc.)
- Performant enough for real-time generation of 512x512 maps

**Constraints:**
- GDScript only (no C#, GDExtension, or plugins)
- Godot 4.x API
- Minimal external dependencies
- Must work with standard Godot TileMap/TileSet workflow

## Goals / Non-Goals

### Goals
- Generate reproducible 512x512 tile maps using noise algorithms
- Achieve < 1 second generation time for full maps
- Support seed-based generation for consistency
- Create reusable, self-contained scripts
- Enable runtime parameter tuning via exported variables
- Provide clear separation between generation logic and rendering

### Non-Goals
- Chunk-based streaming generation (512x512 is small enough for single-pass)
- Advanced biome systems (future enhancement)
- Multiplayer synchronization
- Custom tile rendering (use standard TileMap)
- Editor plugin or tools mode implementation

## Decisions

### Decision 1: Three-Class Architecture

**Choice:** Split functionality into NoiseGenerator, TileMapper, and MapGenerator classes.

**Rationale:**
- **NoiseGenerator**: Encapsulates FastNoiseLite configuration and provides noise sampling
  - Single responsibility: noise generation
  - Easily swappable for different noise algorithms
  - Can be reused across multiple generators

- **TileMapper**: Converts continuous noise values to discrete tile types
  - Separates data transformation from generation
  - Allows different mapping strategies (thresholds, curves, etc.)
  - Independent unit testing

- **MapGenerator**: Orchestrates the generation process
  - Main entry point for consumers
  - Manages TileMap updates
  - Coordinates between noise and mapping

**Alternatives considered:**
- Single monolithic class: Rejected due to poor testability and extensibility
- Four+ classes with interfaces: Rejected as over-engineering for initial implementation
- Node-based components: Rejected to maintain portability (prefer pure GDScript classes)

### Decision 2: FastNoiseLite for Noise Generation

**Choice:** Use Godot's built-in FastNoiseLite class.

**Rationale:**
- Zero external dependencies
- Well-documented in Godot docs
- Good performance characteristics
- Supports multiple noise types (Perlin, Simplex, Cellular, etc.)
- Built-in seed support

**Alternatives considered:**
- Custom Perlin/Simplex implementation: Rejected due to complexity and unnecessary learning overhead
- External noise library: Rejected due to portability constraint

### Decision 3: Threshold-Based Tile Mapping

**Choice:** Use simple threshold ranges to map noise values to tile types.

**Rationale:**
- Easy to understand and configure
- Good starting point for learning
- Sufficient for basic terrain (water, sand, grass, stone, snow)
- Can be enhanced later with curves or more complex rules

**Implementation:**
```gdscript
# Example mapping
if noise_value < -0.3: return WATER
elif noise_value < 0.0: return SAND
elif noise_value < 0.4: return GRASS
elif noise_value < 0.7: return STONE
else: return SNOW
```

**Alternatives considered:**
- Curve-based mapping: Deferred as future enhancement
- Multi-noise biome system: Too complex for initial implementation
- Lookup tables: Less intuitive for learning purposes

### Decision 4: Exported Variables for Configuration

**Choice:** Use `@export` annotations for all tunable parameters.

**Rationale:**
- Enables runtime experimentation in Godot editor
- No need for external configuration files
- Immediate visual feedback when tweaking parameters
- Aligns with Godot best practices

**Parameters to expose:**
- Map dimensions (width, height)
- Random seed
- Noise type, frequency, octaves
- Tile mapping thresholds

**Alternatives considered:**
- Resource-based configuration: Deferred for future when multiple presets are needed
- JSON/INI files: Rejected as over-engineering

### Decision 5: Direct TileMap Cell Setting

**Choice:** Use `TileMap.set_cell()` directly in a nested loop.

**Rationale:**
- Simplest approach for learning
- 512x512 = 262,144 cells, easily handled in < 1 second
- No need for optimization complexity initially
- Clear, readable code

**Implementation approach:**
```gdscript
for y in range(height):
    for x in range(width):
        var noise_val = noise_generator.get_noise_2d(x, y)
        var tile_id = tile_mapper.map_noise_to_tile(noise_val)
        tile_map.set_cell(0, Vector2i(x, y), tile_id, Vector2i(0, 0))
```

**Alternatives considered:**
- Batch cell updates: Not available in Godot API
- Background thread generation: Deferred until performance testing proves it necessary
- Chunk-based generation: Unnecessary for 512x512 maps

### Decision 6: Pure GDScript Classes (No Node Inheritance)

**Choice:** NoiseGenerator and TileMapper are plain `class_name` scripts, not Node-derived.

**Rationale:**
- Better portability - can be used in any context
- Easier unit testing
- Clearer API without Node lifecycle overhead
- MapGenerator extends Node to interface with TileMap in scene tree

**Trade-off:** Slightly more manual instantiation, but clearer separation of concerns.

## Architecture Diagram

```
MapGenerator (Node)
    ├── NoiseGenerator (Object)
    │   └── FastNoiseLite (Godot built-in)
    └── TileMapper (Object)

TileMap (Godot Node) ← Updated by MapGenerator
```

## Data Flow

1. User calls `MapGenerator.generate_map(seed, width, height)`
2. MapGenerator creates/configures NoiseGenerator with seed
3. For each tile coordinate (x, y):
   - NoiseGenerator samples noise value at (x, y)
   - TileMapper converts noise to tile type ID
   - MapGenerator calls TileMap.set_cell() with tile ID
4. MapGenerator emits completion signal

## Performance Strategy

### Initial Implementation
- Single-threaded, synchronous generation
- Direct nested loop iteration
- Target: < 1 second for 512x512

### Optimization Opportunities (Future)
- If performance insufficient:
  1. Profile to identify bottleneck
  2. Consider worker thread for generation
  3. Batch operations if possible
  4. Reduce noise sampling frequency (interpolation)
  5. Cache noise values if reused

### Performance Monitoring
- Add `@export var debug_timing: bool = false` flag
- Log generation time to console when enabled
- Track: noise generation time vs. TileMap update time

## Risks / Trade-offs

### Risk: Performance < 1 second target
**Likelihood:** Low
**Impact:** Medium
**Mitigation:**
- Profile early with 512x512 maps
- FastNoiseLite is optimized; should be sufficient
- If needed, implement deferred generation or threading

### Risk: Limited extensibility for complex features
**Likelihood:** Medium
**Impact:** Low
**Mitigation:**
- Current architecture supports composition
- Can refactor to strategy pattern if needed
- Document extension points in code comments

### Risk: Tight coupling to TileMap API
**Likelihood:** Low
**Impact:** Medium
**Mitigation:**
- Keep MapGenerator's TileMap interaction isolated
- Could add abstraction layer if needed for different renderers
- For learning project, direct API usage is acceptable

### Trade-off: Simplicity vs. Features
**Decision:** Prioritize simplicity for initial implementation
**Rationale:** Learning objective requires understandable code; features can be added incrementally

## Migration Plan

N/A - This is the initial implementation with no existing code to migrate.

## Open Questions

1. **Q:** Should we support multiple TileMap layers initially?
   **A:** No, start with single layer. Add layer support in future iteration if needed.

2. **Q:** What tile types should be supported in the initial mapping?
   **A:** 5 basic types: Water, Sand, Grass, Stone, Snow (simple elevation-based)

3. **Q:** Should generation be triggered automatically on `_ready()` or require manual call?
   **A:** Provide both: `@export var auto_generate: bool = true` with exposed `generate()` method

4. **Q:** Should we validate map dimensions (max size limits)?
   **A:** Yes, add reasonable limits (e.g., 1-2048 range) with warning logs if exceeded
