## ADDED Requirements

### Requirement: Multi-Layer Noise Generation
The system SHALL generate multiple independent noise layers (elevation and moisture at minimum) using FastNoiseLite with seed-based reproducibility.

#### Scenario: Independent noise layers
- **WHEN** a map is generated with seed 12345
- **THEN** elevation noise uses seed 12345
- **AND** moisture noise uses seed 12345 + 10000 (offset)
- **AND** both layers are statistically independent

#### Scenario: Reproducible multi-layer generation
- **WHEN** the same seed is used twice
- **THEN** all noise layers produce identical values
- **AND** biome classifications are identical

### Requirement: Biome Classification
The system SHALL classify each tile into a biome type based on elevation and moisture values using a configurable threshold matrix.

#### Scenario: Desert classification
- **WHEN** elevation is medium (0.4-0.6) AND moisture is low (< 0.3)
- **THEN** the tile is classified as DESERT biome

#### Scenario: Swamp classification
- **WHEN** elevation is low (< 0.3) AND moisture is high (> 0.7)
- **THEN** the tile is classified as SWAMP biome

#### Scenario: Mountain classification
- **WHEN** elevation is high (> 0.7)
- **THEN** the tile is classified as MOUNTAIN biome regardless of moisture

### Requirement: Biome-Based Tile Selection
The system SHALL select appropriate tile types/variants based on the classified biome for each map position.

#### Scenario: Forest tile selection
- **WHEN** a tile is classified as FOREST biome
- **THEN** a tile variant from the forest tile set is selected
- **AND** variants may be weighted randomly for visual variety

#### Scenario: Fallback tile handling
- **WHEN** a biome has no mapped tile variants
- **THEN** a default/fallback tile is used
- **AND** a warning is logged for debugging

### Requirement: Configurable Biome Parameters
The system SHALL provide configurable biome thresholds and noise parameters through exported variables or Resource files.

#### Scenario: Custom biome thresholds
- **WHEN** user sets desert moisture threshold to 0.4 instead of 0.3
- **THEN** desert biomes expand into previously grassland areas
- **AND** regeneration produces different biome distributions

#### Scenario: Noise parameter adjustment
- **WHEN** user changes moisture noise frequency
- **THEN** moisture patterns become more/less detailed
- **AND** biome boundaries shift accordingly

### Requirement: Biome Type Support
The system SHALL support at minimum 5 distinct biome types: OCEAN, GRASSLAND, FOREST, DESERT, and MOUNTAIN.

#### Scenario: All biomes represented
- **WHEN** a 512x512 map is generated with balanced parameters
- **THEN** all 5 core biome types appear in the map
- **AND** biome distributions follow the configured thresholds

### Requirement: Debug Visualization
The system SHALL provide a debug mode that visualizes biome classifications independently from tile rendering.

#### Scenario: Biome color overlay
- **WHEN** debug visualization mode is enabled
- **THEN** each biome type is rendered with a distinct debug color
- **AND** biome boundaries are clearly visible
- **AND** this aids in threshold tuning
