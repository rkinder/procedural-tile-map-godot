# Project Context

## Purpose
This is a learning project focused on creating a procedurally generated 512x512 tile map system. The primary goals are:
- Learn procedural generation techniques for tile-based maps
- Create a reusable, modular system that can be integrated into other Godot projects
- Build an extensible architecture that allows for future enhancements and customization
- Develop practical skills in GDScript and Godot Engine

## Tech Stack
- **Godot Engine** (version 4.x recommended)
- **GDScript** (primary scripting language)
- **TileMap/TileSet** (Godot's built-in tile system)
- **Noise generation libraries** (FastNoiseLite or similar for procedural generation)

## Project Conventions

### Code Style
Follow the official [GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html):
- **Naming Conventions:**
  - Classes: PascalCase (e.g., `MapGenerator`, `TileData`)
  - Functions/Variables: snake_case (e.g., `generate_map()`, `tile_size`)
  - Constants: UPPER_SNAKE_CASE (e.g., `MAP_WIDTH`, `DEFAULT_SEED`)
  - Signals: snake_case (e.g., `map_generated`, `tile_placed`)
  - Private/internal members: prefix with underscore (e.g., `_internal_cache`)
- **Formatting:**
  - Use tabs for indentation (Godot default)
  - One statement per line
  - Space after commas in function calls and arrays
  - Type hints preferred where applicable (e.g., `var count: int = 0`)
- **Documentation:**
  - Add comments for complex algorithms
  - Use docstrings for public functions explaining parameters and return values

### Architecture Patterns
- **Modularity:** Design the map generator as standalone scripts/classes that don't depend on specific scenes
- **Separation of Concerns:**
  - Generation logic (algorithm) separate from rendering (TileMap)
  - Data models separate from generators
  - Configuration separate from implementation
- **Plugin Architecture:** Structure code to be easily portable:
  - Core generator classes should work independently
  - Minimal dependencies on project-specific assets
  - Configuration via exported variables or resource files
- **Extensibility Principles:**
  - Use composition over inheritance where appropriate
  - Implement generator as modular components (noise generator, biome selector, etc.)
  - Support configuration through Resources or dictionaries
  - Use signals to allow external systems to react to generation events
- **Node Structure:**
  - Keep generation logic in pure GDScript classes when possible
  - Use Node-based scripts only when scene tree integration is required

### Testing Strategy
- **Manual Testing:** Primary approach for this learning project
  - Visual verification of generated maps
  - Testing with different seeds and parameters
  - Performance testing with full 512x512 maps
- **Unit Testing (optional):**
  - Consider using GdUnit or Gut for testing core algorithms
  - Test data structures and helper functions
  - Validate edge cases (e.g., boundary conditions, invalid parameters)
- **Debugging Tools:**
  - Use Godot's built-in debugger and print statements
  - Visual debug overlays for generation steps
  - Performance profiler for optimization

### Git Workflow
- **Branching Strategy:**
  - `master`: main development branch
  - Feature branches for experimental features or major changes (optional for solo learning project)
- **Commit Conventions:**
  - Use clear, descriptive commit messages
  - Prefix commits with type: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`
  - Example: `feat: add Perlin noise-based terrain generation`
- **Commit Frequency:**
  - Commit working iterations frequently
  - Each commit should represent a logical unit of work

## Domain Context
### Procedural Generation Concepts
- **Noise Functions:** Perlin, Simplex, or FastNoise for natural-looking terrain
- **Seeded Generation:** Use random seeds for reproducible maps
- **Biomes/Terrain Types:** Different tile types based on noise values, elevation, moisture, etc.
- **Chunk-based Generation:** Consider generating in chunks for performance (though 512x512 may be small enough for single-pass)
- **Post-processing:** Smoothing, erosion, river generation, etc.

### Godot-Specific Knowledge
- **TileMap Node:** Grid-based 2D tile rendering system
- **TileSet Resource:** Defines available tiles, their properties, and collision
- **Layers:** TileMap supports multiple layers (terrain, objects, decorations)
- **Cells:** Individual tiles addressed by Vector2i coordinates
- **Atlas Textures:** Tile graphics typically stored in sprite sheets/atlases

### Map Dimensions
- Target size: 512x512 tiles
- Consider performance implications of full map generation
- May want configurable sizes for testing (e.g., 64x64, 128x128)

## Important Constraints
- **Portability:** Code must be self-contained and not rely on project-specific resources
- **GDScript Only:** Avoid C#, GDExtension, or other languages to keep it simple
- **Performance:** 512x512 tile generation should complete in reasonable time (< 1 second ideal)
- **Godot Version:** Target Godot 4.x (significant API differences from 3.x)
- **Memory:** Be mindful of memory usage with large arrays/data structures
- **Extensibility:** Architecture should allow easy addition of new generation algorithms or features

## External Dependencies
- **Godot Engine:** The core dependency (version 4.x)
- **FastNoiseLite:** Built-in Godot noise generation class (no external install needed)
- **Tile Assets:** Will need tile graphics (can use placeholder/simple tiles initially)
- **No External Plugins Required:** Keep dependencies minimal to maintain portability
