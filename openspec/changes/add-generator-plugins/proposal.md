## Why
A monolithic generation system becomes difficult to extend and maintain as complexity grows. A modular plugin architecture enables composable generation pipelines, easier testing of individual components, and supports the project's core goal of extensibility and reusability.

## What Changes
- Create GeneratorPlugin base class/interface for modular generators
- Implement plugin registration and discovery system
- Add plugin execution pipeline with configurable ordering
- Refactor existing generators (terrain, biome) as plugins
- Support plugin chaining and composition
- Add plugin configuration system
- Implement plugin lifecycle management (init, execute, cleanup)
- Create example plugins demonstrating extensibility

## Impact
- Affected specs: generator-plugins (new capability), terrain-generation (MODIFIED), biome-generation (MODIFIED)
- Affected code: Refactor existing generators into plugin architecture
- Dependencies: Requires generation-config for plugin configuration
- Extensibility: Major improvement - users can add custom generators without modifying core
- Learning goal: Demonstrates composition patterns and plugin architecture
