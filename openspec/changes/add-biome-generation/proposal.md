## Why
Single-layer noise-based terrain lacks variety and realism. Multi-layer biome generation enables diverse terrain types (forests, deserts, tundra, swamps) by combining multiple noise layers (elevation, moisture, temperature) to create rich, varied procedural landscapes.

## What Changes
- Add multi-layer noise generation system using FastNoiseLite
- Implement biome classification algorithm based on elevation + moisture
- Create biome-to-tile mapping system for automatic tile variant selection
- Add configurable biome parameters and thresholds
- Support multiple tile variants per biome type

## Impact
- Affected specs: biome-generation (new capability)
- Affected code: Core generation pipeline, tile selection logic
- Dependencies: Requires noise-terrain-generation capability
- Performance: Additional noise layers may increase generation time
