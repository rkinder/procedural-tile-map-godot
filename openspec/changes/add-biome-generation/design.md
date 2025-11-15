## Context
Multi-layer biome generation requires combining multiple noise sources to classify terrain into distinct biome types. This is a cross-cutting change affecting the generation pipeline, data models, and tile selection logic.

## Goals / Non-Goals
**Goals:**
- Support diverse biome types through multi-layer noise combination
- Enable easy biome configuration and tuning
- Maintain performance targets (< 1 second for 512x512)
- Allow for future biome system extensions

**Non-Goals:**
- Biome transitions/blending (smooth gradients between biomes) - future enhancement
- Dynamic biome changes at runtime
- Biome-specific gameplay mechanics

## Decisions

### Decision: Two-Layer Biome Classification (Elevation + Moisture)
Use elevation and moisture as primary classification axes. This creates a 2D matrix of biomes (e.g., high elevation + low moisture = tundra, low elevation + high moisture = swamp).

**Rationale:**
- Proven pattern in procedural generation (e.g., Minecraft-style generation)
- Intuitive for configuration and tuning
- Computationally efficient (only 2 noise samples per tile)

**Alternatives considered:**
- Three-layer (elevation + moisture + temperature): More variety but higher cost and complexity. Deferred as optional enhancement.
- Single noise with thresholds: Insufficient variety, predictable patterns
- Voronoi-based biome placement: Non-continuous, harder to control

### Decision: Independent Noise Seeds per Layer
Each noise layer (elevation, moisture) uses the same base seed with a large offset (e.g., +10000 for moisture) to ensure statistical independence while maintaining reproducibility.

**Rationale:**
- Ensures layers are uncorrelated (avoids unwanted patterns)
- Single seed input maintains user-friendly seeded generation
- Deterministic and reproducible

### Decision: Biome Configuration via Dictionary/Resource
Store biome definitions (thresholds, tile mappings) in a configurable structure accessible via exported variables or Resource files.

**Rationale:**
- Supports runtime tuning without code changes
- Enables preset sharing and extensibility
- Aligns with Godot's Resource system patterns

## Risks / Trade-offs

**Risk:** Performance degradation with multiple noise layers
- **Mitigation:** Profile generation time; optimize if needed; consider caching noise values

**Risk:** Complex biome threshold tuning
- **Mitigation:** Provide debug visualization mode; include sensible default presets

**Trade-off:** Two-layer vs. three-layer system
- **Impact:** Two layers limit biome variety but ensure performance
- **Decision:** Start with two layers; add temperature as optional third layer if needed

## Migration Plan
This is a new capability building on noise-terrain-generation. No migration needed. Integration steps:
1. Implement BiomeGenerator as standalone class
2. Add biome layer to generation pipeline after elevation noise
3. Update tile selection to use biome classifications
4. Provide configuration interface for biome parameters

## Open Questions
- Should biome transitions be smoothed (interpolated) or hard boundaries? → Start with hard boundaries; add blending later if needed
- What's the ideal number of biome types for initial release? → 5-7 core biomes (grassland, forest, desert, tundra, swamp, ocean, mountain)
