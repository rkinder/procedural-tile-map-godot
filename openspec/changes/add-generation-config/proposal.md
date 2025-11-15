## Why
Hardcoded generation parameters limit flexibility and experimentation. A configurable system enables users to tune map generation without modifying code, supports preset sharing, and allows runtime parameter adjustments for testing and gameplay variety.

## What Changes
- Add GenerationConfig resource/class for centralized parameter management
- Implement validation for parameter ranges to prevent crashes/invalid maps
- Support map dimension configuration (64x64 to 512x512)
- Add noise parameter configuration (frequency, octaves, lacunarity, etc.)
- Implement seed management (manual input or random generation)
- Create configuration presets for common map types

## Impact
- Affected specs: generation-config (new capability)
- Affected code: All generator classes must consume config data
- Dependencies: Required by terrain-generation and biome-generation capabilities
- Breaking: Generators must be refactored to accept config objects
