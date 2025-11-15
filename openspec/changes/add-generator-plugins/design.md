## Context
A plugin-based generator architecture aligns with the project's core goal of creating an extensible, modular system. This is a significant architectural change enabling composition and customization without modifying core code.

## Goals / Non-Goals
**Goals:**
- Composable generation pipeline from independent plugins
- Easy addition of custom generators without core modifications
- Clear plugin interface and lifecycle
- Support plugin ordering and dependencies
- Demonstrate plugin architecture as learning goal
- Enable community/user-contributed generators (future)

**Non-Goals:**
- Dynamic plugin loading from external files at runtime (manual registration for now)
- Plugin marketplace or distribution system
- Sandboxed plugin execution (trust model: all plugins are trusted)
- Version management for plugin compatibility (simple contract for now)

## Decisions

### Decision: Abstract Base Class with Virtual Methods
Use GDScript class inheritance with abstract methods (base methods that must be overridden) for plugin interface.

**Rationale:**
- Native GDScript pattern (class_name, extends)
- Type safety via inheritance
- Clear contract via abstract methods
- Easy to understand for learning project

**Alternatives considered:**
- Duck typing (no base class): Less type-safe, no enforced contract
- Composition over inheritance: More complex for this use case
- Signal-based plugins: Too loose, harder to reason about data flow

### Decision: Sequential Pipeline with Explicit Ordering
Execute plugins sequentially in configured order, passing data from one to next via shared data structure.

**Rationale:**
- Predictable execution order (easier to debug)
- Simple data flow (map data → plugin A → plugin B → final map)
- Explicit ordering makes dependencies clear
- Easier to implement than parallel/DAG-based execution

**Alternatives considered:**
- Parallel execution with DAG: Complex, overkill for initial implementation
- Event-driven execution: Less predictable, harder to control order
- Automatic dependency resolution: Complex, explicit ordering simpler

### Decision: Shared MapData Object for Plugin Communication
Use a single MapData object (containing tile array, config, metadata) passed through all plugins, which each plugin can read and modify.

**Rationale:**
- Simple data flow model (one object through pipeline)
- Plugins can read previous plugin results
- Efficient (no copying, just references)
- Easy to debug (inspect MapData at any stage)

**Alternatives considered:**
- Immutable data with copies: Expensive for large maps
- Per-plugin input/output: More complex wiring
- Global state: Harder to test, less modular

### Decision: Manual Plugin Registration (Not Auto-Discovery)
Require explicit plugin registration in code rather than automatic filesystem scanning.

**Rationale:**
- Simpler implementation (no filesystem scanning, class introspection)
- More control over which plugins are active
- Easier to debug (explicit list of plugins)
- Suitable for learning project scope

**Alternatives considered:**
- Automatic discovery via directory scanning: More complex, Godot has limited reflection
- Resource-based plugin definitions: Additional abstraction layer

### Decision: Built-in Generators as First-Class Plugins
Refactor existing terrain and biome generators to be plugins, not special-cased.

**Rationale:**
- Dogfooding: proves plugin system is sufficient
- Consistency: all generators use same interface
- Demonstrates best practices for plugin development
- No "plugin vs. core generator" distinction

## Risks / Trade-offs

**Risk:** Plugin architecture adds complexity for simple use cases
- **Mitigation:** Provide default pipeline preset (terrain → biome); users can ignore plugins if desired

**Risk:** Performance overhead from plugin abstraction
- **Mitigation:** Minimal - just function calls; profile and optimize if needed

**Risk:** Plugin interface may be too rigid or too flexible
- **Mitigation:** Start simple, iterate based on plugin development experience

**Trade-off:** Sequential vs. parallel execution
- **Impact:** Sequential is simpler but slower for independent plugins
- **Decision:** Start with sequential; add parallelism later if needed

**Trade-off:** Explicit registration vs. auto-discovery
- **Impact:** Manual registration is less "magical" but more explicit
- **Decision:** Explicit for learning project; auto-discovery could be added later

## Migration Plan
**Breaking Changes:**
- Existing generator APIs change to plugin interface
- Generation invocation changes from direct calls to pipeline execution

**Migration Steps:**
1. Create GeneratorPlugin base class and pipeline system
2. Implement plugin registration
3. Refactor terrain generator as TerrainPlugin (keep old API temporarily)
4. Refactor biome generator as BiomePlugin
5. Create default pipeline preset (terrain → biome)
6. Update all generation call sites to use pipeline
7. Deprecate old direct generator APIs
8. Provide migration examples

**Backward Compatibility:**
- Provide wrapper functions that create default pipeline internally
- Example: `generate_map()` creates pipeline with default plugins and executes

## Open Questions
- Should plugins be able to add new tile layers? → Yes, MapData should support multi-layer tiles
- How to handle plugin errors (abort pipeline or skip plugin)? → Configurable: default abort, allow "continue on error" flag
- Should plugins have access to other plugins' state? → No, only shared MapData; keeps plugins isolated
- How to version plugin interface for future changes? → Add version field to base class; check compatibility on registration
- Should we support plugin composition (plugin that contains other plugins)? → Defer to future; keep simple initially
