## ADDED Requirements

### Requirement: Configuration Data Structure
The system SHALL provide a GenerationConfig Resource class containing all configurable parameters for map generation.

#### Scenario: Config creation
- **WHEN** a new GenerationConfig is created
- **THEN** it has default values for all parameters
- **AND** all parameters are editable via Godot inspector
- **AND** the config can be saved as a .tres file

#### Scenario: Config parameter access
- **WHEN** a generator accesses the config
- **THEN** it can read map dimensions, seed, and noise parameters
- **AND** values are type-safe (integers for dimensions, floats for noise params)

### Requirement: Map Dimension Configuration
The system SHALL support configurable map dimensions from 64x64 to 512x512 tiles.

#### Scenario: Valid dimension configuration
- **WHEN** user sets map width to 256 and height to 256
- **THEN** the configuration is accepted
- **AND** generation produces a 256x256 map

#### Scenario: Invalid dimension rejection
- **WHEN** user sets map width to 1024 (exceeds maximum)
- **THEN** validation fails with clear error message
- **AND** generation is prevented

#### Scenario: Minimum dimension enforcement
- **WHEN** user sets map width to 32 (below minimum)
- **THEN** validation fails
- **AND** error indicates minimum is 64

### Requirement: Seed Configuration
The system SHALL support both manual seed specification and random seed generation.

#### Scenario: Manual seed reproducibility
- **WHEN** user sets seed to 42
- **THEN** generation uses seed 42
- **AND** repeated generations with seed 42 produce identical maps

#### Scenario: Random seed generation
- **WHEN** user leaves seed as null/empty
- **THEN** a random seed is generated
- **AND** the generated seed is accessible for later reproduction

### Requirement: Noise Parameter Configuration
The system SHALL provide configurable noise parameters including frequency, octaves, lacunarity, and gain.

#### Scenario: Custom noise frequency
- **WHEN** user sets noise frequency to 0.02
- **THEN** terrain features become larger/smoother
- **AND** generation uses the specified frequency

#### Scenario: Octave configuration
- **WHEN** user sets octaves to 6
- **THEN** terrain has more detail layers
- **AND** generation time may increase

#### Scenario: Invalid noise parameters
- **WHEN** user sets frequency to -1 (invalid)
- **THEN** validation fails with descriptive error
- **AND** suggests valid range (e.g., 0.001 to 0.1)

### Requirement: Parameter Validation
The system SHALL validate all configuration parameters before generation begins and provide clear error messages for invalid values.

#### Scenario: Comprehensive validation
- **WHEN** config.validate() is called
- **THEN** all parameters are checked against valid ranges
- **AND** first error found is returned with descriptive message
- **AND** no generation occurs if validation fails

#### Scenario: Valid configuration acceptance
- **WHEN** all parameters are within valid ranges
- **THEN** validation passes
- **AND** generation can proceed

### Requirement: Configuration Presets
The system SHALL provide built-in configuration presets for common map types.

#### Scenario: Preset availability
- **WHEN** user requests available presets
- **THEN** at least 5 presets are available (e.g., Small Test, Medium, Large, Islands, Continents)
- **AND** each preset has unique parameter combinations

#### Scenario: Preset loading
- **WHEN** user selects the "Islands" preset
- **THEN** config parameters are set to island-optimized values
- **AND** validation passes automatically

#### Scenario: Custom preset saving
- **WHEN** user creates custom configuration
- **THEN** user can save it as a .tres resource file
- **AND** the preset can be loaded later

### Requirement: Configuration Change Signals
The system SHALL emit signals when configuration parameters change to enable runtime updates.

#### Scenario: Parameter change notification
- **WHEN** any config parameter is modified
- **THEN** a config_changed signal is emitted
- **AND** listeners can react to the change (e.g., regenerate preview)

### Requirement: Performance Warning System
The system SHALL warn users when configurations may impact performance.

#### Scenario: Large map warning
- **WHEN** user configures a 512x512 map with 8 octaves
- **THEN** a warning is issued about potential performance impact
- **AND** generation still proceeds if user confirms
- **AND** warning includes estimated generation time if available
