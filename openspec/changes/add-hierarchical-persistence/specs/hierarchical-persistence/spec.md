# Specification: Hierarchical Persistence

Multi-map save/load system for world map + multiple tactical maps with organized file structure.

## ADDED Requirements

### Requirement: System must save world map and tactical maps separately

World map SHALL be saved in dedicated world/ folder, tactical maps SHALL be saved in tactical/ folder with position-based filenames.

#### Scenario: Save campaign with world and tactical maps

```gdscript
var persistence = HierarchicalMapPersistence.new()
var coordinator = MapCoordinator.new()
# ... setup world map and generate some tactical maps ...

persistence.save_campaign("user://saves/campaign1", coordinator)

# Check file structure
assert(FileAccess.file_exists("user://saves/campaign1/manifest.json"))
assert(FileAccess.file_exists("user://saves/campaign1/world/world_map.procmap"))
assert(FileAccess.file_exists("user://saves/campaign1/tactical/tactical_10_20.procmap"))
```

### Requirement: System must create and maintain manifest file

Manifest file SHALL track world metadata and list of all saved tactical maps.

#### Scenario: Generate manifest during save

```gdscript
var persistence = HierarchicalMapPersistence.new()
persistence.save_campaign("user://saves/campaign1", coordinator)

var manifest = persistence.load_manifest("user://saves/campaign1")
assert(manifest.world_seed == coordinator.world_map.generation_seed)
assert(manifest.tactical_maps.size() > 0)
assert(manifest.get_tactical_entry(Vector2i(10, 20)) != null)
```

### Requirement: System must support incremental tactical map saves

Only modified tactical maps SHALL be saved during incremental save operations.

#### Scenario: Save only modified tactical maps

```gdscript
var persistence = HierarchicalMapPersistence.new()

# Initial save
persistence.save_campaign("user://saves/campaign1", coordinator)

# Modify one tactical map
var tactical = coordinator.get_tactical_map(Vector2i(10, 20))
tactical.set_cell(Vector2i(5, 5), TILE_CUSTOM)
tactical.mark_modified()

# Incremental save
persistence.save_campaign_incremental("user://saves/campaign1", coordinator)

# Only the modified tactical map should be resaved
# (verify via file modification timestamp or save count tracking)
```

### Requirement: System must load world map independently

World map SHALL be loadable without loading any tactical maps.

#### Scenario: Load world map only

```gdscript
var persistence = HierarchicalMapPersistence.new()

var world = persistence.load_world_map("user://saves/campaign1")

assert(world != null)
assert(world.dimensions == Vector2i(256, 256))
# No tactical maps loaded yet
```

### Requirement: System must support batch loading tactical maps

Multiple tactical maps SHALL be loadable in single operation with optional progress callback.

#### Scenario: Batch load multiple tactical maps

```gdscript
var persistence = HierarchicalMapPersistence.new()

var positions = [Vector2i(10, 20), Vector2i(10, 21), Vector2i(50, 75)]
var progress_called = false

var loaded_maps = persistence.batch_load_tactical_maps(
    "user://saves/campaign1",
    positions,
    func(current, total): progress_called = true
)

assert(loaded_maps.size() == 3)
assert(loaded_maps.has(Vector2i(10, 20)))
assert(progress_called == true)
```

### Requirement: System must validate referential integrity

Tactical maps SHALL be validated against world seed to detect mismatches.

#### Scenario: Reject tactical map with mismatched world seed

```gdscript
var persistence = HierarchicalMapPersistence.new()

var world = persistence.load_world_map("user://saves/campaign1")
world.generation_seed = 12345

# Attempt to load tactical map with different world seed (99999)
var tactical = persistence.load_tactical_map(
    "user://saves/campaign1",
    Vector2i(10, 20),
    world
)

assert(tactical == null)  # Rejected due to seed mismatch
# Error logged: "Tactical map world seed mismatch"
```

### Requirement: System must create directory structure automatically

Save operation SHALL create necessary directories if they don't exist.

#### Scenario: Create save directories on first save

```gdscript
var persistence = HierarchicalMapPersistence.new()

# Directory doesn't exist yet
assert(not DirAccess.dir_exists_absolute("user://saves/new_campaign"))

persistence.save_campaign("user://saves/new_campaign", coordinator)

# Directories created
assert(DirAccess.dir_exists_absolute("user://saves/new_campaign"))
assert(DirAccess.dir_exists_absolute("user://saves/new_campaign/world"))
assert(DirAccess.dir_exists_absolute("user://saves/new_campaign/tactical"))
```

### Requirement: System must handle missing or corrupted files gracefully

Loading SHALL fail gracefully with clear errors for missing/corrupted files.

#### Scenario: Handle missing world map file

```gdscript
var persistence = HierarchicalMapPersistence.new()

var world = persistence.load_world_map("user://saves/nonexistent_campaign")

assert(world == null)
# Error logged: "World map file not found"
```

#### Scenario: Handle corrupted manifest

```gdscript
var persistence = HierarchicalMapPersistence.new()

# Corrupt the manifest file
var file = FileAccess.open("user://saves/campaign1/manifest.json", FileAccess.WRITE)
file.store_string("{ invalid json }")
file.close()

var manifest = persistence.load_manifest("user://saves/campaign1")

assert(manifest == null)
# Error logged: "Failed to parse manifest.json"
```

### Requirement: System must support listing available campaigns

System SHALL provide method to discover all saved campaigns in saves directory.

#### Scenario: List all saved campaigns

```gdscript
var persistence = HierarchicalMapPersistence.new()

var campaigns = persistence.list_campaigns("user://saves")

assert(campaigns.size() > 0)
assert(campaigns.has("campaign1"))
assert(campaigns.has("campaign2"))
```
