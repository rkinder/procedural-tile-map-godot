# Integration Guide

## Overview

This guide explains how to integrate the Procedural Tile Map system into your own Godot 4.x projects. The system is designed to be modular, portable, and easy to integrate without dependencies on specific project structures or assets.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation Methods](#installation-methods)
3. [Basic Integration](#basic-integration)
4. [Configuration](#configuration)
5. [Advanced Usage](#advanced-usage)
6. [Custom Plugins](#custom-plugins)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required

- **Godot Engine 4.x** (4.0 or later)
- **GDScript support** (default in Godot)
- **TileMap and TileSet** configured in your project

### Recommended

- Basic understanding of Godot's TileMap system
- Familiarity with noise-based procedural generation concepts
- Knowledge of GDScript for customization

---

## Installation Methods

### Method 1: Direct Copy (Simplest)

1. Copy the core scripts to your project:
   ```
   your_project/
   ├── addons/
   │   └── procedural_tilemap/
   │       ├── scripts/
   │       │   ├── noise_generator.gd
   │       │   ├── tile_mapper.gd
   │       │   ├── map_generator.gd
   │       │   ├── biome_generator.gd
   │       │   ├── generation_config.gd
   │       │   └── plugins/
   │       │       └── generator_plugin.gd
   │       └── plugin.cfg (if packaging as addon)
   ```

2. Configure the scripts in your project settings (if needed)

### Method 2: As a Godot Addon (Future)

Once the plugin system is complete (Phase 3), you'll be able to:

1. Download/clone the addon
2. Place in `res://addons/procedural_tilemap/`
3. Enable in **Project Settings > Plugins**

### Method 3: Git Submodule (For Version Control)

```bash
git submodule add <repo-url> addons/procedural_tilemap
```

This method allows you to track updates and manage versions.

---

## Basic Integration

### Step 1: Prepare Your TileMap

1. Create a TileMap node in your scene
2. Configure a TileSet with your tile assets
3. Assign tile IDs that match the generator's output

**Example Scene Structure:**
```
Scene
├── TileMap (node)
│   └── TileSet (resource with your tiles)
└── MapGenerator (script attached to a Node)
```

### Step 2: Create a Generation Script

Create a script that uses the procedural generation system:

```gdscript
extends Node

# Reference the generator scripts
const NoiseGenerator = preload("res://addons/procedural_tilemap/scripts/noise_generator.gd")
const TileMapper = preload("res://addons/procedural_tilemap/scripts/tile_mapper.gd")
const MapGenerator = preload("res://addons/procedural_tilemap/scripts/map_generator.gd")
const GenerationConfig = preload("res://addons/procedural_tilemap/scripts/generation_config.gd")

@onready var tile_map: TileMap = $TileMap

func _ready() -> void:
	generate_map()

func generate_map() -> void:
	# Create configuration
	var config = GenerationConfig.new()
	config.map_width = 512
	config.map_height = 512
	config.seed_value = 12345  # Or use randi() for random
	config.noise_frequency = 0.05
	config.noise_octaves = 4

	# Create generator
	var generator = MapGenerator.new()
	generator.config = config
	generator.tile_map = tile_map

	# Generate the map
	generator.generate()

	print("Map generation complete!")
```

### Step 3: Configure Tile Mapping

The generator needs to know which noise values map to which tile IDs:

```gdscript
# In your generation script or config
config.tile_thresholds = {
	0: -1.0,    # Water (deep)
	1: -0.3,    # Water (shallow)
	2: 0.0,     # Sand/Beach
	3: 0.2,     # Grass
	4: 0.5,     # Forest
	5: 0.7,     # Mountain
	6: 0.9      # Snow
}
```

Make sure your TileSet has tiles at the corresponding IDs.

---

## Configuration

### GenerationConfig Options

The `GenerationConfig` class provides comprehensive control over map generation:

```gdscript
var config = GenerationConfig.new()

# Map Dimensions
config.map_width = 512
config.map_height = 512

# Seed (for reproducibility)
config.seed_value = 12345  # Fixed seed
# OR
config.seed_value = randi()  # Random seed

# Noise Parameters (FastNoiseLite)
config.noise_frequency = 0.05      # Lower = larger features
config.noise_octaves = 4            # More = more detail
config.noise_lacunarity = 2.0       # Frequency multiplier per octave
config.noise_gain = 0.5             # Amplitude multiplier per octave
config.noise_type = FastNoiseLite.TYPE_PERLIN  # Noise algorithm

# Tile Mapping
config.tile_thresholds = { ... }    # See above
```

### Biome Configuration (Phase 2+)

Once biome generation is implemented:

```gdscript
# Multi-layer biome configuration
config.use_biomes = true
config.moisture_frequency = 0.03
config.temperature_frequency = 0.02

config.biomes = {
	"desert": { "elevation": [0.0, 0.4], "moisture": [0.0, 0.3], "tiles": [8, 9] },
	"forest": { "elevation": [0.1, 0.6], "moisture": [0.4, 1.0], "tiles": [10, 11, 12] },
	"tundra": { "elevation": [0.5, 1.0], "moisture": [0.0, 0.5], "tiles": [13, 14] }
}
```

---

## Advanced Usage

### Runtime Map Regeneration

```gdscript
func regenerate_with_new_seed() -> void:
	config.seed_value = randi()
	generator.generate()
```

### Partial Map Updates (Phase 3+)

With chunk-based generation:

```gdscript
# Generate only a specific chunk
func generate_chunk_at(chunk_x: int, chunk_y: int) -> void:
	generator.generate_chunk(chunk_x, chunk_y)

# Load chunks around player position
func update_chunks_around_player(player_pos: Vector2) -> void:
	var chunk_pos = generator.world_to_chunk(player_pos)
	generator.load_chunks_in_radius(chunk_pos, 2)  # 2-chunk radius
```

### Save and Load Maps (Phase 4+)

```gdscript
# Save generated map
func save_map(file_path: String) -> void:
	var persistence = MapPersistence.new()
	persistence.save_map(generator, file_path)

# Load saved map
func load_map(file_path: String) -> void:
	var persistence = MapPersistence.new()
	persistence.load_map(generator, file_path)
```

### Track Player Modifications (Phase 4+)

```gdscript
# Enable modification tracking
generator.enable_modification_tracking()

# When player changes a tile
func on_player_modify_tile(pos: Vector2i, new_tile_id: int) -> void:
	tile_map.set_cell(0, pos, new_tile_id)
	generator.mark_tile_modified(pos)

# Save only modified tiles (delta save)
func save_modifications() -> void:
	var serializer = MapSerializer.new()
	serializer.save_delta(generator, "user://map_modifications.dat")
```

---

## Custom Plugins

### Creating a Generator Plugin (Phase 3+)

Extend the system with custom generation logic:

```gdscript
extends GeneratorPlugin

func _init() -> void:
	plugin_name = "RiverGenerator"
	plugin_version = "1.0"

func execute(map_data: Array, config: GenerationConfig) -> void:
	# Custom river generation logic
	for river in range(config.river_count):
		var start = _find_high_elevation(map_data)
		var path = _flow_downhill(start, map_data)
		_carve_river(path, map_data)

func _find_high_elevation(map_data: Array) -> Vector2i:
	# Implementation...
	pass

func _flow_downhill(start: Vector2i, map_data: Array) -> Array:
	# Implementation...
	pass

func _carve_river(path: Array, map_data: Array) -> void:
	# Implementation...
	pass
```

### Registering Custom Plugins

```gdscript
# In your initialization code
var river_plugin = RiverGenerator.new()
generator.register_plugin(river_plugin)

# Configure plugin execution order
generator.set_plugin_order(["TerrainGenerator", "BiomeGenerator", "RiverGenerator"])
```

---

## Best Practices

### Performance Optimization

1. **Start Small:** Test with smaller maps (64x64, 128x128) before full 512x512
2. **Profile Generation:** Use Godot's profiler to identify bottlenecks
3. **Chunk-Based for Large Maps:** Use chunk generation for maps larger than 512x512
4. **Cache Noise:** Reuse noise generators when possible

```gdscript
# Good: Reuse generator
var noise_gen = NoiseGenerator.new()
for i in range(10):
	noise_gen.seed_value = i
	noise_gen.generate()

# Bad: Create new generator each time
for i in range(10):
	var noise_gen = NoiseGenerator.new()
	noise_gen.generate()
```

### Memory Management

```gdscript
# Free large data structures when done
func cleanup_generation() -> void:
	generator.clear_cache()
	noise_data = null
```

### Modularity

- Keep generation logic separate from game logic
- Use signals to notify when generation completes
- Don't hardcode tile IDs; use configuration

```gdscript
# In MapGenerator
signal generation_complete

func generate() -> void:
	# ... generation code ...
	generation_complete.emit()

# In your game code
generator.generation_complete.connect(_on_map_ready)

func _on_map_ready() -> void:
	spawn_player()
	enable_gameplay()
```

### Version Compatibility

When saving/loading maps:

```gdscript
# Always include version information
var save_data = {
	"version": "1.0",
	"generator_version": generator.VERSION,
	"map_data": map_data,
	"config": config.to_dict()
}
```

---

## Troubleshooting

### Common Issues

#### Issue: "NoiseGenerator not found"

**Solution:** Check the preload paths match your project structure

```gdscript
# Update paths to match your installation
const NoiseGenerator = preload("res://YOUR_PATH/scripts/noise_generator.gd")
```

#### Issue: Map generates all one tile type

**Solution:** Check tile threshold configuration

```gdscript
# Ensure thresholds are in ascending order and cover full range
config.tile_thresholds = {
	0: -1.0,   # Must start at or below -1.0
	1: -0.5,
	2: 0.0,
	3: 0.5,
	4: 1.0     # Should end at or above 1.0
}
```

#### Issue: Generation is slow (> 1 second for 512x512)

**Solutions:**
1. Reduce noise octaves (try 3 instead of 4+)
2. Use chunk-based generation (Phase 3)
3. Reduce noise frequency
4. Profile to find bottlenecks

```gdscript
# Lower octaves = faster generation, less detail
config.noise_octaves = 3  # Instead of 5+
```

#### Issue: Chunks have visible seams

**Solution:** Ensure noise continuity across chunk boundaries (automatic in Phase 3)

#### Issue: Can't load saved maps

**Solutions:**
1. Check file exists and is readable
2. Verify version compatibility
3. Check for data corruption

```gdscript
if not FileAccess.file_exists(save_path):
	push_error("Save file not found: " + save_path)
	return
```

---

## Integration Checklist

Before deploying to your project:

- [ ] TileMap and TileSet configured with appropriate tiles
- [ ] Core scripts copied to project
- [ ] Tile IDs match configuration thresholds
- [ ] Tested with small map first (64x64)
- [ ] Performance acceptable for target map size
- [ ] Seed management implemented (if reproducibility needed)
- [ ] Save/load integration (if persistence needed)
- [ ] Custom plugins tested (if using)

---

## Support and Resources

### Documentation

- **Roadmap:** See `docs/ROADMAP.md` for development phases
- **OpenSpec Proposals:** Check `openspec/changes/` for detailed specs

### Community

- Report issues on the project's GitHub repository
- Check Godot documentation for TileMap/noise generation
- Reference FastNoiseLite documentation for noise parameters

---

## Example Projects

### Minimal Integration Example

```gdscript
extends Node2D

const MapGenerator = preload("res://addons/procedural_tilemap/scripts/map_generator.gd")
const GenerationConfig = preload("res://addons/procedural_tilemap/scripts/generation_config.gd")

@onready var tile_map: TileMap = $TileMap

func _ready() -> void:
	var config = GenerationConfig.new()
	config.map_width = 128
	config.map_height = 128
	config.seed_value = randi()

	var generator = MapGenerator.new()
	generator.config = config
	generator.tile_map = tile_map
	generator.generate()
```

### Full-Featured Integration Example

See the demo scenes in `scenes/` directory for complete examples including:
- UI for parameter adjustment
- Runtime regeneration
- Seed management
- Save/load functionality
- Custom plugin integration

---

## License

This system is provided as-is for use in your projects. Refer to the project LICENSE file for terms.

---

## Changelog

### Version 1.0 (Phase 1)
- Basic noise-based terrain generation
- Configuration system

### Version 2.0 (Phase 2)
- Biome generation
- Multi-layer noise support

### Version 3.0 (Phase 3)
- Chunk-based generation (BREAKING)
- Plugin architecture

### Version 4.0 (Phase 4)
- Map persistence
- Modification tracking and delta serialization
