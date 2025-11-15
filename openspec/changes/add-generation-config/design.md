## Context
Configuration management is foundational for flexible procedural generation. This change affects all generator components and establishes patterns for parameter handling throughout the system.

## Goals / Non-Goals
**Goals:**
- Centralized configuration accessible to all generators
- Type-safe parameter validation preventing crashes
- User-friendly configuration via Godot inspector
- Preset system for quick experimentation
- Runtime configurability

**Non-Goals:**
- UI/Editor plugin for configuration (may be added later)
- Serialization of generation history (separate capability)
- Network synchronization of configs (out of scope for single-player learning project)

## Decisions

### Decision: Use Godot Resource for Configuration
Implement GenerationConfig as a Resource class with exported variables, allowing inspector editing and file-based storage.

**Rationale:**
- Native Godot pattern, familiar to users
- Automatic inspector UI generation
- Built-in serialization (.tres files)
- Type hints and validation support

**Alternatives considered:**
- Dictionary-based config: Less type-safe, no inspector integration
- JSON files: Requires custom parsing, less Godot-native
- Singleton/autoload: Limits multi-config scenarios, less flexible

### Decision: Fail-Fast Validation
Validate all parameters immediately when config is created or modified, throwing errors for invalid values before generation starts.

**Rationale:**
- Prevents cryptic runtime errors during generation
- Clear error messages aid debugging
- Safer than silent clamping (avoids unexpected behavior)

**Alternatives considered:**
- Silent clamping: Hides errors, user may not notice invalid inputs
- Lazy validation: Errors occur mid-generation, harder to debug

### Decision: Seed Management via Optional Integer
Seed parameter is nullable (Variant type): `null` generates random seed, integer uses specified seed.

**Rationale:**
- User-friendly: empty field = random, filled field = reproducible
- Common pattern in procedural generation tools
- Maintains reproducibility when needed

### Decision: Built-in Presets as Dictionary Constants
Store default presets as dictionary constants in GenerationConfig class rather than external files.

**Rationale:**
- Ensures presets always available (no missing files)
- Easy to version control and distribute
- Can still save/load custom presets as .tres files

**Alternatives considered:**
- External .tres preset files: Risk of missing files, more complex distribution
- Database/registry: Overkill for this scope

## Risks / Trade-offs

**Risk:** Overly restrictive validation limits experimentation
- **Mitigation:** Set generous ranges; use warnings instead of errors for non-critical bounds

**Risk:** Breaking change for existing generators
- **Mitigation:** Refactor generators systematically; this is early development so limited impact

**Trade-off:** Type safety vs. flexibility
- **Impact:** Resource-based config is less dynamic than dictionaries
- **Decision:** Prioritize type safety and editor integration

## Migration Plan
This is a new capability. Generators must be updated to:
1. Accept GenerationConfig parameter in generation functions
2. Read parameters from config instead of hardcoded values
3. Use config seed for noise initialization

Integration order:
1. Create GenerationConfig class and validation
2. Add default preset configurations
3. Refactor terrain generator to use config
4. Refactor biome generator to use config
5. Update demo/test scenes

## Open Questions
- Should dimension validation enforce power-of-2 sizes? → No, allow any size 64-512; power-of-2 is optimization, not requirement
- Should noise parameters have different ranges per layer? → Start with unified ranges; add layer-specific params if needed
- How to handle config changes at runtime (regenerate automatically or require manual trigger)? → Manual trigger for now; auto-regeneration is risky for large maps
