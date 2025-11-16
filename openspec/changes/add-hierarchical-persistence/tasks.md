# Implementation Tasks: Hierarchical Map Persistence

## 1. MapManifest Implementation

- [ ] 1.1 Create `scripts/map_manifest.gd` with class_name MapManifest
- [ ] 1.2 Add property campaign_name: String
- [ ] 1.3 Add property format_version: String = "1.0.0"
- [ ] 1.4 Add property created_timestamp: int
- [ ] 1.5 Add property last_saved_timestamp: int
- [ ] 1.6 Add property world_seed: int
- [ ] 1.7 Add property world_dimensions: Vector2i
- [ ] 1.8 Add property world_generation_config: Dictionary
- [ ] 1.9 Add property tactical_maps: Array (array of dictionaries)
- [ ] 1.10 Implement `add_tactical_map(pos: Vector2i, filename: String, modified: bool)`
- [ ] 1.11 Implement `remove_tactical_map(pos: Vector2i) -> bool`
- [ ] 1.12 Implement `has_tactical_map(pos: Vector2i) -> bool`
- [ ] 1.13 Implement `get_tactical_entry(pos: Vector2i) -> Dictionary`
- [ ] 1.14 Implement `get_tactical_filename(pos: Vector2i) -> String`
- [ ] 1.15 Implement `set_tactical_modified(pos: Vector2i, modified: bool)`
- [ ] 1.16 Implement `update_last_saved()` to set last_saved_timestamp
- [ ] 1.17 Implement `to_json() -> Dictionary` serialization
- [ ] 1.18 Implement static `from_json(data: Dictionary) -> MapManifest` deserialization
- [ ] 1.19 Implement `validate() -> bool` to check required fields
- [ ] 1.20 Add inline documentation for all public methods

## 2. File System Helpers

- [ ] 2.1 Create `scripts/file_system_helper.gd` with static utility methods
- [ ] 2.2 Implement `ensure_directory_exists(path: String) -> bool`
- [ ] 2.3 Implement `get_tactical_filename(world_pos: Vector2i) -> String` (format: "tactical_X_Y.procmap")
- [ ] 2.4 Implement `parse_tactical_filename(filename: String) -> Vector2i` (extract position from filename)
- [ ] 2.5 Implement `list_files_in_directory(path: String, extension: String) -> Array[String]`
- [ ] 2.6 Implement `get_file_modification_time(path: String) -> int`
- [ ] 2.7 Implement `delete_file_safe(path: String) -> bool` with error handling
- [ ] 2.8 Add inline documentation

## 3. HierarchicalMapPersistence Implementation - Core

- [ ] 3.1 Create `scripts/hierarchical_map_persistence.gd` with class_name HierarchicalMapPersistence
- [ ] 3.2 Add constant MANIFEST_FILENAME = "manifest.json"
- [ ] 3.3 Add constant WORLD_FOLDER = "world"
- [ ] 3.4 Add constant TACTICAL_FOLDER = "tactical"
- [ ] 3.5 Add constant WORLD_MAP_FILENAME = "world_map.procmap"
- [ ] 3.6 Add property file_system_helper reference
- [ ] 3.7 Add property map_persistence: MapPersistence (from add-map-persistence)
- [ ] 3.8 Add property map_serializer: MapSerializer (from add-map-serialization)
- [ ] 3.9 Implement `_get_campaign_path_parts(campaign_path: String) -> Dictionary` helper
- [ ] 3.10 Implement `_get_world_folder_path(campaign_path: String) -> String`
- [ ] 3.11 Implement `_get_tactical_folder_path(campaign_path: String) -> String`
- [ ] 3.12 Implement `_get_manifest_path(campaign_path: String) -> String`

## 4. HierarchicalMapPersistence - Manifest Operations

- [ ] 4.1 Implement `save_manifest(campaign_path: String, manifest: MapManifest) -> bool`
- [ ] 4.2 Implement JSON serialization of manifest
- [ ] 4.3 Implement file write with error handling
- [ ] 4.4 Implement `load_manifest(campaign_path: String) -> MapManifest`
- [ ] 4.5 Implement file read with error handling
- [ ] 4.6 Implement JSON parsing with validation
- [ ] 4.7 Implement `create_manifest_from_coordinator(coordinator: MapCoordinator) -> MapManifest`
- [ ] 4.8 Extract world map metadata
- [ ] 4.9 Enumerate cached tactical maps
- [ ] 4.10 Add error logging for file operations

## 5. HierarchicalMapPersistence - World Map Operations

- [ ] 5.1 Implement `save_world_map(campaign_path: String, world: WorldMap) -> bool`
- [ ] 5.2 Create world/ directory if doesn't exist
- [ ] 5.3 Call map_persistence.save() for world map
- [ ] 5.4 Add error handling and logging
- [ ] 5.5 Implement `load_world_map(campaign_path: String) -> WorldMap`
- [ ] 5.6 Check if world map file exists
- [ ] 5.7 Call map_persistence.load() for world map
- [ ] 5.8 Validate world map data
- [ ] 5.9 Add error handling for missing/corrupted files

## 6. HierarchicalMapPersistence - Tactical Map Operations

- [ ] 6.1 Implement `save_tactical_map(campaign_path: String, tactical: TacticalMap) -> bool`
- [ ] 6.2 Create tactical/ directory if doesn't exist
- [ ] 6.3 Generate filename from world_position
- [ ] 6.4 Call map_persistence.save() for tactical map
- [ ] 6.5 Mark tactical map as saved (clear modified flag if using modification tracking)
- [ ] 6.6 Implement `load_tactical_map(campaign_path: String, world_pos: Vector2i, world: WorldMap) -> TacticalMap`
- [ ] 6.7 Generate filename from world_pos
- [ ] 6.8 Check file exists
- [ ] 6.9 Call map_persistence.load() for tactical map
- [ ] 6.10 Validate referential integrity (world seed match)
- [ ] 6.11 Return null if validation fails with error log

## 7. HierarchicalMapPersistence - Campaign Operations

- [ ] 7.1 Implement `save_campaign(campaign_path: String, coordinator: MapCoordinator) -> bool`
- [ ] 7.2 Create campaign directory structure
- [ ] 7.3 Create manifest from coordinator
- [ ] 7.4 Save world map
- [ ] 7.5 Save all cached tactical maps
- [ ] 7.6 Update manifest with tactical map entries
- [ ] 7.7 Save manifest
- [ ] 7.8 Return success/failure status
- [ ] 7.9 Implement `save_campaign_incremental(campaign_path: String, coordinator: MapCoordinator) -> bool`
- [ ] 7.10 Load existing manifest
- [ ] 7.11 Save world map (always save, small file)
- [ ] 7.12 Save only modified tactical maps
- [ ] 7.13 Update manifest tactical entries
- [ ] 7.14 Save manifest
- [ ] 7.15 Implement `load_campaign(campaign_path: String) -> MapCoordinator`
- [ ] 7.16 Load manifest
- [ ] 7.17 Load world map
- [ ] 7.18 Create MapCoordinator and set world map
- [ ] 7.19 Return coordinator (tactical maps loaded on-demand)
- [ ] 7.20 Add comprehensive error handling for each step

## 8. HierarchicalMapPersistence - Batch Operations

- [ ] 8.1 Implement `batch_load_tactical_maps(campaign_path: String, positions: Array[Vector2i], progress_callback: Callable) -> Dictionary`
- [ ] 8.2 Loop through positions array
- [ ] 8.3 Load each tactical map
- [ ] 8.4 Call progress_callback after each load (if provided)
- [ ] 8.5 Collect loaded maps in dictionary
- [ ] 8.6 Handle partial failures (skip failed maps, log errors)
- [ ] 8.7 Return dictionary of loaded maps
- [ ] 8.8 Implement `batch_save_tactical_maps(campaign_path: String, tactical_maps: Array[TacticalMap], progress_callback: Callable) -> int`
- [ ] 8.9 Loop through tactical maps array
- [ ] 8.10 Save each tactical map
- [ ] 8.11 Call progress_callback after each save
- [ ] 8.12 Count successful saves
- [ ] 8.13 Return count of successfully saved maps

## 9. HierarchicalMapPersistence - Utility Methods

- [ ] 9.1 Implement `list_campaigns(saves_directory: String) -> Array[String]`
- [ ] 9.2 Scan saves_directory for subdirectories
- [ ] 9.3 Check each for manifest.json
- [ ] 9.4 Return array of campaign names
- [ ] 9.5 Implement `delete_campaign(campaign_path: String) -> bool`
- [ ] 9.6 Recursively delete campaign directory
- [ ] 9.7 Add confirmation/safety checks
- [ ] 9.8 Implement `validate_campaign(campaign_path: String) -> Dictionary` (returns validation results)
- [ ] 9.9 Check manifest exists and is valid
- [ ] 9.10 Check world map file exists
- [ ] 9.11 Check all tactical maps in manifest exist
- [ ] 9.12 Check for orphaned tactical files (not in manifest)
- [ ] 9.13 Return validation report dictionary

## 10. Extension of MapPersistence

- [ ] 10.1 Open `scripts/map_persistence.gd` (from add-map-persistence proposal)
- [ ] 10.2 Add method `save_with_metadata(file_path: String, map: Resource, metadata: Dictionary) -> bool`
- [ ] 10.3 Include map_type ("world" or "tactical") in saved data
- [ ] 10.4 Include world_seed for referential integrity
- [ ] 10.5 Add method `load_with_validation(file_path: String, expected_type: String) -> Resource`
- [ ] 10.6 Validate map_type matches expected_type
- [ ] 10.7 Return null if validation fails
- [ ] 10.8 Add inline documentation

## 11. Extension of MapSerializer

- [ ] 11.1 Open `scripts/map_serializer.gd` (from add-map-serialization proposal)
- [ ] 11.2 Add map_type field to serialized data ("world" or "tactical")
- [ ] 11.3 Add world_seed field to serialized data
- [ ] 11.4 Update serialization methods to include new fields
- [ ] 11.5 Update deserialization methods to read new fields
- [ ] 11.6 Add validation helpers for required fields

## 12. Demo Scene: Save/Load UI

- [ ] 12.1 Create `scenes/save_load_demo.tscn`
- [ ] 12.2 Add UI elements: campaign name input, save button, load button
- [ ] 12.3 Add campaign list (ItemList or Tree)
- [ ] 12.4 Add MapCoordinator reference
- [ ] 12.5 Add HierarchicalMapPersistence instance
- [ ] 12.6 Implement save button click: call save_campaign()
- [ ] 12.7 Implement load button click: call load_campaign()
- [ ] 12.8 Implement campaign list population on _ready()
- [ ] 12.9 Add progress bar for batch operations
- [ ] 12.10 Add status label for operation feedback
- [ ] 12.11 Add error display (RichTextLabel for error messages)

## 13. Demo Scene: Campaign Browser

- [ ] 13.1 Create `scenes/campaign_browser.tscn`
- [ ] 13.2 Add UI to list all campaigns
- [ ] 13.3 Display campaign metadata (name, world seed, created date, tactical map count)
- [ ] 13.4 Add "Load Campaign" button
- [ ] 13.5 Add "Delete Campaign" button with confirmation dialog
- [ ] 13.6 Add "Validate Campaign" button
- [ ] 13.7 Display validation results (missing files, orphaned files, etc.)
- [ ] 13.8 Implement refresh functionality

## 14. Testing and Validation

- [ ] 14.1 Test MapManifest creation and serialization
- [ ] 14.2 Test MapManifest deserialization from JSON
- [ ] 14.3 Test MapManifest validation (reject invalid JSON)
- [ ] 14.4 Test save_campaign creates correct directory structure
- [ ] 14.5 Test save_campaign writes manifest, world map, tactical maps
- [ ] 14.6 Test load_campaign loads world map correctly
- [ ] 14.7 Test load_campaign with missing manifest (error handling)
- [ ] 14.8 Test load_campaign with missing world map (error handling)
- [ ] 14.9 Test save_campaign_incremental only saves modified tactical maps
- [ ] 14.10 Test batch_load_tactical_maps with progress callback
- [ ] 14.11 Test batch_save_tactical_maps with multiple maps
- [ ] 14.12 Test referential integrity validation (reject mismatched seed)
- [ ] 14.13 Test list_campaigns discovers all campaigns
- [ ] 14.14 Test delete_campaign removes all files
- [ ] 14.15 Test validate_campaign detects missing files
- [ ] 14.16 Test validate_campaign detects orphaned tactical files
- [ ] 14.17 Test save/load round-trip (save campaign, load campaign, verify data)
- [ ] 14.18 Test with various numbers of tactical maps (0, 1, 10, 100)
- [ ] 14.19 Test handling of corrupted manifest file
- [ ] 14.20 Test handling of corrupted world map file
- [ ] 14.21 Test handling of corrupted tactical map file

## 15. Performance Testing

- [ ] 15.1 Benchmark save_campaign with 10 tactical maps
- [ ] 15.2 Benchmark save_campaign with 100 tactical maps
- [ ] 15.3 Benchmark save_campaign_incremental vs full save
- [ ] 15.4 Benchmark load_manifest (should be < 50ms)
- [ ] 15.5 Benchmark batch_load_tactical_maps with 50 maps
- [ ] 15.6 Profile file I/O overhead
- [ ] 15.7 Measure manifest file size with 100 tactical entries
- [ ] 15.8 Document performance metrics

## 16. Code Quality

- [ ] 16.1 Verify all code follows GDScript style guide
- [ ] 16.2 Ensure all public methods have docstring comments
- [ ] 16.3 Add type hints to all function signatures and variables
- [ ] 16.4 Remove debug print statements or commented-out code
- [ ] 16.5 Verify no Godot warnings in editor
- [ ] 16.6 Run static analysis if available

## 17. Documentation

- [ ] 17.1 Add header comments to each script file
- [ ] 17.2 Document file structure and naming conventions
- [ ] 17.3 Create usage example for saving campaign
- [ ] 17.4 Create usage example for loading campaign
- [ ] 17.5 Create usage example for incremental saves
- [ ] 17.6 Document manifest JSON schema
- [ ] 17.7 Document error handling patterns
- [ ] 17.8 Add troubleshooting guide for common issues

## 18. Integration with Existing Systems

- [ ] 18.1 Verify integration with add-multi-scale-architecture (MapCoordinator)
- [ ] 18.2 Verify integration with add-map-persistence (base save/load)
- [ ] 18.3 Verify integration with add-map-serialization (modification tracking)
- [ ] 18.4 Test full workflow: generate world, visit tactical maps, modify, save, load, verify
- [ ] 18.5 Update project documentation with hierarchical persistence usage

## Dependencies

- Task 1.x (MapManifest) is foundational, should be done first
- Task 2.x (File System Helpers) can be done in parallel with 1.x
- Tasks 3.x-9.x (HierarchicalMapPersistence) depend on 1.x and 2.x
- Tasks 10.x-11.x (MapPersistence/MapSerializer extensions) can be done in parallel with 3.x-9.x
- Tasks 12.x-13.x (Demo scenes) depend on 3.x-11.x
- Tasks 14.x-15.x (Testing) depend on all implementation tasks
- Tasks 16.x-18.x can overlap with testing

## Parallelizable Work

- MapManifest (1.x) and File System Helpers (2.x) are independent
- MapPersistence extension (10.x) and MapSerializer extension (11.x) can be done in parallel
- Demo scenes (12.x and 13.x) can be developed in parallel
- Performance testing (15.x) can overlap with functional testing (14.x)
