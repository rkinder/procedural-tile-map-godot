## 1. Core Configuration System
- [ ] 1.1 Create GenerationConfig class/Resource
- [ ] 1.2 Define configuration schema (map size, seed, noise params)
- [ ] 1.3 Add exported variables for inspector editing
- [ ] 1.4 Implement configuration validation logic

## 2. Parameter Definitions
- [ ] 2.1 Add map dimension parameters (width, height, min: 64, max: 512)
- [ ] 2.2 Add seed parameter (integer, null for random)
- [ ] 2.3 Add noise parameters (frequency, octaves, lacunarity, gain)
- [ ] 2.4 Add biome threshold parameters
- [ ] 2.5 Add tile set reference parameter

## 3. Validation System
- [ ] 3.1 Implement dimension range validation (64-512)
- [ ] 3.2 Implement noise parameter range validation
- [ ] 3.3 Add power-of-2 dimension validation (optional optimization)
- [ ] 3.4 Implement error reporting for invalid configs
- [ ] 3.5 Add warning system for performance-critical configs (e.g., very large maps)

## 4. Preset System
- [ ] 4.1 Create preset storage mechanism (built-in dictionary or resource files)
- [ ] 4.2 Implement preset loading/saving
- [ ] 4.3 Add default presets (Small Test, Medium, Large, Islands, Continents)
- [ ] 4.4 Add preset selection UI/interface

## 5. Integration
- [ ] 5.1 Refactor terrain generator to accept GenerationConfig
- [ ] 5.2 Refactor biome generator to accept GenerationConfig
- [ ] 5.3 Update TileMap generation to use config dimensions
- [ ] 5.4 Add config change signals for runtime updates

## 6. Testing & Documentation
- [ ] 6.1 Test with various dimension combinations
- [ ] 6.2 Test validation edge cases (negative, zero, oversized values)
- [ ] 6.3 Verify preset loading/saving
- [ ] 6.4 Performance test large configurations (512x512)
- [ ] 6.5 Document configuration parameters and valid ranges
