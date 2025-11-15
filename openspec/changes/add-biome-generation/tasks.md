## 1. Core Biome System
- [ ] 1.1 Create BiomeGenerator class with multi-layer noise support
- [ ] 1.2 Implement biome classification algorithm (elevation + moisture matrix)
- [ ] 1.3 Add biome type enumeration (GRASSLAND, FOREST, DESERT, TUNDRA, SWAMP, etc.)
- [ ] 1.4 Create BiomeData resource/class for biome configuration

## 2. Noise Layer Integration
- [ ] 2.1 Add moisture noise layer with independent seed offset
- [ ] 2.2 Add temperature noise layer (optional for enhanced biome variety)
- [ ] 2.3 Implement layer blending and normalization
- [ ] 2.4 Add noise parameter presets per layer

## 3. Tile Mapping System
- [ ] 3.1 Create biome-to-tile mapping dictionary/resource
- [ ] 3.2 Implement tile variant selection logic per biome
- [ ] 3.3 Support weighted random selection for tile variants
- [ ] 3.4 Add fallback tile handling for unmapped biomes

## 4. Configuration & Testing
- [ ] 4.1 Add exported biome threshold parameters
- [ ] 4.2 Create biome debug visualization mode
- [ ] 4.3 Test with different parameter combinations
- [ ] 4.4 Performance test with full 512x512 generation
- [ ] 4.5 Add example biome configuration presets

## 5. Integration
- [ ] 5.1 Integrate BiomeGenerator into main generation pipeline
- [ ] 5.2 Update TileMap rendering to use biome-selected tiles
- [ ] 5.3 Add biome data export for debugging/analysis
