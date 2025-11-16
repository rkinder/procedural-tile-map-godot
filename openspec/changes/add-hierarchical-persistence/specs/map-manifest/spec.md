# Specification: Map Manifest

Campaign metadata file tracking world information and tactical map inventory.

## ADDED Requirements

### Requirement: Manifest must store world map metadata

Manifest SHALL contain world generation seed, dimensions, and configuration.

#### Scenario: Create manifest with world metadata

```gdscript
var manifest = MapManifest.new()
manifest.campaign_name = "My Campaign"
manifest.world_seed = 12345
manifest.world_dimensions = Vector2i(256, 256)
manifest.world_generation_config = {"noise_frequency": 0.02}

assert(manifest.world_seed == 12345)
assert(manifest.world_dimensions == Vector2i(256, 256))
```

### Requirement: Manifest must track tactical map inventory

Manifest SHALL maintain list of all saved tactical maps with world positions and modification status.

#### Scenario: Add tactical map entries to manifest

```gdscript
var manifest = MapManifest.new()

manifest.add_tactical_map(Vector2i(10, 20), "tactical_10_20.procmap", true)
manifest.add_tactical_map(Vector2i(10, 21), "tactical_10_21.procmap", false)

assert(manifest.tactical_maps.size() == 2)
assert(manifest.has_tactical_map(Vector2i(10, 20)) == true)
assert(manifest.get_tactical_filename(Vector2i(10, 20)) == "tactical_10_20.procmap")
```

### Requirement: Manifest must track timestamps

Manifest SHALL store campaign creation timestamp and last saved timestamp.

#### Scenario: Track manifest timestamps

```gdscript
var manifest = MapManifest.new()
manifest.created_timestamp = Time.get_unix_time_from_system()

# Simulate save operation
await get_tree().create_timer(1.0).timeout
manifest.update_last_saved()

assert(manifest.last_saved_timestamp > manifest.created_timestamp)
```

### Requirement: Manifest must serialize to JSON

Manifest SHALL support serialization to/from JSON format.

#### Scenario: Serialize manifest to JSON

```gdscript
var manifest = MapManifest.new()
manifest.campaign_name = "Test Campaign"
manifest.world_seed = 42
manifest.add_tactical_map(Vector2i(5, 5), "tactical_5_5.procmap", true)

var json = manifest.to_json()
assert(json.has("campaign_name"))
assert(json.has("world"))
assert(json.has("tactical_maps"))
assert(json["world"]["seed"] == 42)
```

#### Scenario: Deserialize manifest from JSON

```gdscript
var json_data = {
    "campaign_name": "Loaded Campaign",
    "world": {"seed": 99, "dimensions": {"x": 128, "y": 128}},
    "tactical_maps": [
        {"world_position": {"x": 1, "y": 2}, "file": "tactical_1_2.procmap", "modified": false}
    ]
}

var manifest = MapManifest.from_json(json_data)

assert(manifest.campaign_name == "Loaded Campaign")
assert(manifest.world_seed == 99)
assert(manifest.tactical_maps.size() == 1)
```

### Requirement: Manifest must support querying tactical maps

Manifest SHALL provide methods to query tactical map existence and properties.

#### Scenario: Query tactical map information

```gdscript
var manifest = MapManifest.new()
manifest.add_tactical_map(Vector2i(10, 20), "tactical_10_20.procmap", true)

assert(manifest.has_tactical_map(Vector2i(10, 20)) == true)
assert(manifest.has_tactical_map(Vector2i(99, 99)) == false)

var entry = manifest.get_tactical_entry(Vector2i(10, 20))
assert(entry != null)
assert(entry["modified"] == true)
```

### Requirement: Manifest must support updating tactical map status

Manifest SHALL allow updating modification status and timestamps for tactical maps.

#### Scenario: Update tactical map modification status

```gdscript
var manifest = MapManifest.new()
manifest.add_tactical_map(Vector2i(10, 20), "tactical_10_20.procmap", false)

# Mark as modified
manifest.set_tactical_modified(Vector2i(10, 20), true)

var entry = manifest.get_tactical_entry(Vector2i(10, 20))
assert(entry["modified"] == true)
```

### Requirement: Manifest must validate on load

Manifest SHALL validate required fields and data types when deserializing.

#### Scenario: Reject invalid manifest JSON

```gdscript
var invalid_json = {
    "campaign_name": "Test",
    # Missing required "world" field
    "tactical_maps": []
}

var manifest = MapManifest.from_json(invalid_json)

assert(manifest == null)
# Error logged: "Manifest missing required field: world"
```

### Requirement: Manifest must support removing tactical map entries

Manifest SHALL allow removing tactical map entries when maps are deleted.

#### Scenario: Remove tactical map from manifest

```gdscript
var manifest = MapManifest.new()
manifest.add_tactical_map(Vector2i(10, 20), "tactical_10_20.procmap", true)
manifest.add_tactical_map(Vector2i(10, 21), "tactical_10_21.procmap", false)

assert(manifest.tactical_maps.size() == 2)

manifest.remove_tactical_map(Vector2i(10, 20))

assert(manifest.tactical_maps.size() == 1)
assert(manifest.has_tactical_map(Vector2i(10, 20)) == false)
assert(manifest.has_tactical_map(Vector2i(10, 21)) == true)
```
