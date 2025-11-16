# Feature Placement Specification

## ADDED Requirements

### Requirement: Feature Placement Rules Definition
The system SHALL provide a FeaturePlacementRules class that defines terrain-feature compatibility.

#### Scenario: Define terrain types
- **WHEN** FeaturePlacementRules is loaded
- **THEN** it SHALL expose constants for all supported terrain types (GRASS, DIRT, STONE, SAND, GRAVEL)

#### Scenario: Define feature types
- **WHEN** FeaturePlacementRules is loaded
- **THEN** it SHALL expose constants for all supported features (TREE_OAK, TREE_PINE, BOULDER, ROCK_SMALL, BUSH, FLOWER)

#### Scenario: Map terrain to valid features
- **WHEN** FeaturePlacementRules is initialized
- **THEN** it SHALL contain a rules dictionary mapping each terrain type to array of valid features

### Requirement: Terrain-Feature Compatibility
The system SHALL enforce rules about which features can appear on which terrain.

#### Scenario: Trees allowed on grass
- **WHEN** checking if trees can be placed on grass terrain
- **THEN** system SHALL return true

#### Scenario: Trees forbidden on water
- **WHEN** checking if trees can be placed on water terrain
- **THEN** system SHALL return false

#### Scenario: Trees forbidden on stone
- **WHEN** checking if trees can be placed on stone terrain
- **THEN** system SHALL return false

#### Scenario: Rocks allowed on grass
- **WHEN** checking if rocks can be placed on grass terrain
- **THEN** system SHALL return true

#### Scenario: Rocks allowed on stone
- **WHEN** checking if rocks can be placed on stone terrain
- **THEN** system SHALL return true

#### Scenario: Boulders allowed on stone
- **WHEN** checking if boulders can be placed on stone terrain
- **THEN** system SHALL return true

#### Scenario: Bushes allowed on grass
- **WHEN** checking if bushes can be placed on grass terrain
- **THEN** system SHALL return true

#### Scenario: Flowers allowed on grass
- **WHEN** checking if flowers can be placed on grass terrain
- **THEN** system SHALL return true

#### Scenario: No features on water
- **WHEN** checking valid features for water terrain
- **THEN** system SHALL return empty array

### Requirement: Valid Feature Retrieval
The system SHALL provide methods to query valid features for terrain types.

#### Scenario: Get valid features for terrain
- **WHEN** get_valid_features(GRASS) is called
- **THEN** it SHALL return array containing TREE_OAK, TREE_PINE, BUSH, FLOWER

#### Scenario: Get valid features for stone
- **WHEN** get_valid_features(STONE) is called
- **THEN** it SHALL return array containing BOULDER, ROCK_SMALL

#### Scenario: Get valid features for water
- **WHEN** get_valid_features(WATER) is called
- **THEN** it SHALL return empty array

#### Scenario: Empty result for invalid terrain
- **WHEN** get_valid_features() is called with undefined terrain type
- **THEN** it SHALL return empty array and log warning

### Requirement: Feature Validation
The system SHALL validate feature placement requests.

#### Scenario: Validate legal placement
- **WHEN** can_place_feature(GRASS, TREE_OAK) is called
- **THEN** it SHALL return true

#### Scenario: Reject illegal placement
- **WHEN** can_place_feature(WATER, TREE_OAK) is called
- **THEN** it SHALL return false

#### Scenario: Reject undefined feature
- **WHEN** can_place_feature() is called with undefined feature type
- **THEN** it SHALL return false and log warning

### Requirement: Feature Selection from Noise
The system SHALL map noise values to specific features from valid set.

#### Scenario: Map normalized noise to feature
- **WHEN** noise value 0.2 is mapped to features for GRASS terrain
- **THEN** system SHALL select first feature from valid array (deterministic)

#### Scenario: Map normalized noise across range
- **WHEN** noise value 0.8 is mapped to features for GRASS terrain
- **THEN** system SHALL select last feature from valid array (deterministic)

#### Scenario: Even distribution across features
- **WHEN** mapping noise values 0.0-1.0 to GRASS features
- **THEN** each valid feature SHALL receive approximately equal representation

#### Scenario: Handle single valid feature
- **WHEN** terrain type has only one valid feature
- **THEN** that feature SHALL always be selected regardless of noise value

#### Scenario: Handle no valid features
- **WHEN** terrain type has no valid features
- **THEN** NO_FEATURE constant SHALL be returned

### Requirement: Rule Configuration
The system SHALL allow dynamic rule modification.

#### Scenario: Add feature to terrain
- **WHEN** add_feature_to_terrain(SAND, BUSH) is called
- **THEN** bushes SHALL become valid on sand terrain

#### Scenario: Remove feature from terrain
- **WHEN** remove_feature_from_terrain(GRASS, TREE_OAK) is called
- **THEN** oak trees SHALL no longer be valid on grass terrain

#### Scenario: Clear all features for terrain
- **WHEN** clear_terrain_features(GRASS) is called
- **THEN** grass terrain SHALL have no valid features

#### Scenario: Reset to defaults
- **WHEN** reset_to_defaults() is called
- **THEN** all rules SHALL revert to initial configuration

### Requirement: Feature Naming and Display
The system SHALL provide human-readable feature names.

#### Scenario: Get feature name
- **WHEN** get_feature_name(TREE_OAK) is called
- **THEN** it SHALL return "Oak Tree"

#### Scenario: Get terrain name
- **WHEN** get_terrain_name(GRASS) is called
- **THEN** it SHALL return "Grass"

#### Scenario: Handle unknown feature
- **WHEN** get_feature_name() is called with undefined feature ID
- **THEN** it SHALL return "Unknown Feature"

### Requirement: Feature Count and Types
The system SHALL provide information about available features.

#### Scenario: Count total feature types
- **WHEN** get_feature_type_count() is called
- **THEN** it SHALL return the total number of defined features

#### Scenario: Count features for terrain
- **WHEN** get_feature_count_for_terrain(GRASS) is called
- **THEN** it SHALL return number of valid features for grass

#### Scenario: List all feature types
- **WHEN** get_all_feature_types() is called
- **THEN** it SHALL return array of all feature type constants

### Requirement: Rule Documentation
The system SHALL include educational documentation about rule-based systems.

#### Scenario: Inline rule explanations
- **WHEN** reading FeaturePlacementRules source code
- **THEN** comments SHALL explain why each rule exists

#### Scenario: Usage examples
- **WHEN** reading class header comments
- **THEN** examples SHALL show how to query and modify rules

#### Scenario: Educational comments
- **WHEN** reading rule definitions
- **THEN** comments SHALL explain real-world reasoning (e.g., "trees need soil")

### Requirement: Rule Validation and Warnings
The system SHALL validate rule consistency.

#### Scenario: Warn about empty terrain
- **WHEN** a terrain type is defined with no valid features
- **THEN** system SHALL optionally log informational message (valid configuration)

#### Scenario: Warn about undefined feature reference
- **WHEN** a rule references an undefined feature constant
- **THEN** system SHALL log warning

#### Scenario: Validate terrain type existence
- **WHEN** rules are accessed for undefined terrain type
- **THEN** system SHALL log warning and return empty array

### Requirement: Default Rule Set
The system SHALL provide a sensible default rule configuration.

#### Scenario: Grass supports vegetation
- **WHEN** FeaturePlacementRules is initialized with defaults
- **THEN** GRASS terrain SHALL support trees, bushes, and flowers

#### Scenario: Stone supports rocks
- **WHEN** FeaturePlacementRules is initialized with defaults
- **THEN** STONE terrain SHALL support boulders and small rocks

#### Scenario: Dirt supports limited vegetation
- **WHEN** FeaturePlacementRules is initialized with defaults
- **THEN** DIRT terrain SHALL support bushes and small rocks

#### Scenario: Sand supports minimal features
- **WHEN** FeaturePlacementRules is initialized with defaults
- **THEN** SAND terrain SHALL support only small rocks

#### Scenario: Water supports no features
- **WHEN** FeaturePlacementRules is initialized with defaults
- **THEN** WATER terrain SHALL support no features

### Requirement: Performance
The system SHALL perform feature validation efficiently.

#### Scenario: Fast feature lookup
- **WHEN** get_valid_features() is called
- **THEN** it SHALL return in O(1) time (dictionary lookup)

#### Scenario: Fast validation check
- **WHEN** can_place_feature() is called
- **THEN** it SHALL complete in O(n) time where n is number of valid features (small)

#### Scenario: Bulk validation performance
- **WHEN** validating 4,096 tiles (64×64 tactical map)
- **THEN** total validation time SHALL be < 10 milliseconds

### Requirement: Extensibility
The system SHALL support future feature and terrain additions.

#### Scenario: Add new terrain type
- **WHEN** new terrain constant is defined
- **THEN** rules can be added for it without modifying existing logic

#### Scenario: Add new feature type
- **WHEN** new feature constant is defined
- **THEN** it can be added to terrain rules without breaking existing placements

#### Scenario: Support custom rulesets
- **WHEN** custom FeaturePlacementRules instance is created
- **THEN** it can define completely different rules for specialized maps

### Requirement: Rule Persistence (Optional)
The system MAY support saving and loading rule configurations.

#### Scenario: Export rules to dictionary
- **WHEN** export_rules() is called
- **THEN** it SHALL return dictionary representation of all rules

#### Scenario: Import rules from dictionary
- **WHEN** import_rules(rules_dict) is called
- **THEN** it SHALL replace current rules with imported configuration

#### Scenario: Save rules to file
- **WHEN** save_rules_to_file(path) is called
- **THEN** rules SHALL be saved as JSON for later loading

#### Scenario: Load rules from file
- **WHEN** load_rules_from_file(path) is called
- **THEN** rules SHALL be loaded from JSON file
