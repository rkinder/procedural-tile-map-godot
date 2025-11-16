# Architecture Assessment: Multi-Scale Map System

## Executive Summary

**Status:** ⚠️ **GAPS IDENTIFIED** - Current proposals do not fully support the two-level (world/tactical) map architecture.

The project's current OpenSpec proposals focus on single-map generation at a single scale. To support the described goal of a **strategic world map with expandable tactical detail maps**, significant architectural additions are needed.

---

## Stated Project Goal

### Two-Level Map System

1. **World/Strategic Level:**
   - Larger overall world map generated at coarse scale
   - Represents strategic overview (regions, biomes, major features)
   - **Largely immutable** - player cannot or should not modify
   - Generated once and persisted

2. **Tactical/Detail Level:**
   - Zoomed-in sections of the world map
   - Selected regions from world map get detailed generation
   - Higher resolution, more tile variety
   - **Extensively modifiable** by player
   - Player modifications must be tracked and persisted per-region

3. **Relationship:**
   - World map cell/region → expands to tactical map
   - Tactical generation influenced by world data (biome, elevation, etc.)
   - Multiple tactical maps can exist for different world regions
   - Tactical maps persist independently from world map

### Example Use Case
Similar to strategy games like:
- **Civilization:** Strategic map + tactical battle map
- **XCOM:** Geoscape (world) + tactical missions
- **Dwarf Fortress:** World generation + embark site detail

---

## Current Proposal Analysis

### What IS Supported

#### ✅ Basic Generation Capability
- **Proposals:** `add-noise-terrain-generation`, `add-biome-generation`
- **Assessment:** Can generate both world-level and tactical-level maps
- **Gap:** No distinction between the two scales or how they relate

#### ✅ Modification Tracking
- **Proposal:** `add-map-serialization`
- **Assessment:** Excellent support for tracking player modifications
- **Features:**
  - Sparse dictionary storage (efficient for few modifications)
  - Delta serialization (save only changed tiles)
  - Player-first conflict resolution
  - Undo/redo support
- **Applicability:** Perfect for tactical maps with player edits
- **Gap:** No concept of "tactical map instance" vs "world map"

#### ✅ Persistence System
- **Proposal:** `add-map-persistence`
- **Assessment:** Can save/load maps with metadata
- **Features:**
  - Multiple formats (JSON, binary, Resource)
  - Compression (RLE + optional GZip)
  - Metadata storage (seed, config, timestamp)
- **Applicability:** Can save both world and tactical maps
- **Gap:** No architecture for managing multiple related maps (world + N tactical maps)

#### ✅ Plugin Architecture
- **Proposal:** `add-generator-plugins`
- **Assessment:** Extensible generator system
- **Applicability:** Could support separate world-level and tactical-level generator plugins
- **Gap:** No guidance on multi-scale plugin patterns

---

### What IS NOT Supported

#### ❌ Multi-Scale Map Architecture

**Current State:**
- All proposals assume a single map at a single scale
- No concept of "world map" vs "tactical map" as distinct entities
- No hierarchical relationship between map scales

**What's Needed:**
- Clear definition of world map structure and size
- Definition of tactical map size and relationship to world cells
- Coordinate mapping system (world coords ↔ tactical coords)

**Example Missing Concepts:**
```
World Map: 256x256 cells (strategic scale)
Each world cell can expand to: 64x64 tactical tiles (detailed scale)
World cell (10, 15) → Tactical map covers world area (10, 15)
```

#### ❌ Tactical Map Instantiation System

**Current State:**
- Chunk generation proposal is about streaming a single large map
- No system for creating independent tactical map instances

**What's Needed:**
- Mechanism to "drill down" from world cell to tactical map
- Deterministic generation of tactical maps from world data
- Management of multiple active tactical map instances
- Loading/unloading tactical maps based on player focus

**Missing Questions:**
- When is a tactical map generated? (on-demand, pre-generated, cached?)
- How many tactical maps can exist simultaneously?
- Are tactical maps persistent (saved) or regenerated each visit?
- Can player visit same world location multiple times? (same tactical map or new instance?)

#### ❌ World-to-Tactical Generation Inheritance

**Current State:**
- No mechanism for world map data to influence tactical generation
- Noise generation doesn't support multi-scale seeding

**What's Needed:**
- Tactical generation uses world cell data as input
  - World biome → influences tactical biome distribution
  - World elevation → affects tactical height map baseline
  - World features → spawn tactical structures
- Coordinate-based seeding ensures determinism
  - Same world location always generates same tactical map (if no modifications)

**Example Missing Flow:**
```
1. Player selects world cell (100, 200) [biome: Forest, elevation: 0.6]
2. System generates tactical map:
   - Base seed = world_seed + hash(100, 200)
   - Biome config = ForestBiome (from world)
   - Elevation offset = 0.6 (from world)
   - Generate 64x64 tactical tiles with this context
```

#### ❌ Separate Persistence Models

**Current State:**
- Single persistence system for "a map"
- No distinction between world map (rarely changes) and tactical maps (heavily modified)

**What's Needed:**
- **World Map Storage:**
  - Save once after generation
  - Minimal or no modification tracking
  - Store as single file (e.g., `world_map.procmap`)
  - Include metadata: seed, dimensions, generation config

- **Tactical Map Storage:**
  - Save per-region (e.g., `tactical_100_200.procmap`)
  - Full modification tracking (use map-serialization proposal)
  - Delta saves for efficiency
  - Link back to world coordinates

**Example File Structure:**
```
saves/my_world/
├── world_map.procmap           # Strategic map (largely immutable)
├── world_metadata.json         # World generation config
└── tactical/
    ├── tactical_100_200.procmap  # Tactical map for world cell (100,200)
    ├── tactical_100_201.procmap  # Tactical map for world cell (100,201)
    └── tactical_105_200.procmap  # Tactical map for world cell (105,200)
```

#### ❌ World Map Mutability Enforcement

**Current State:**
- No concept of read-only or limited-modification maps
- Modification tracking applies uniformly to any map

**What's Needed:**
- World map should be **immutable** or **restricted**
- Options:
  1. **Fully Immutable:** World map cannot be edited at all
  2. **Limited Edits:** Allow marking/annotations but not tile changes
  3. **Regenerable:** World map can be edited but easily regenerated from seed
- Configuration flag: `map.allow_modifications = false`

---

## Critical Gaps Summary

| Capability | Current Status | Required For Multi-Scale | Priority |
|-----------|---------------|-------------------------|----------|
| **Multi-scale architecture** | ❌ Not present | Define world vs tactical relationship | 🔴 Critical |
| **Coordinate mapping** | ❌ Not present | World coords → Tactical coords | 🔴 Critical |
| **Tactical instantiation** | ❌ Not present | Create tactical maps on-demand | 🔴 Critical |
| **Generation inheritance** | ❌ Not present | World data influences tactical gen | 🟠 High |
| **Separate persistence** | ⚠️ Partial (can save multiple maps, but no multi-map management) | Store world + N tactical maps | 🟠 High |
| **World immutability** | ❌ Not present | Prevent world map edits | 🟡 Medium |
| **Chunk generation** | ✅ Planned (Phase 3) | Not strictly required but useful | 🟢 Low |

---

## Recommendations

### Option 1: Add New Proposal - "Multi-Scale Map System"

**Recommended Approach:** Create a new OpenSpec proposal that addresses the multi-scale architecture.

**Proposal Name:** `add-multi-scale-maps`

**Key Components:**
1. **WorldMap class** - Manages strategic-level map
2. **TacticalMap class** - Manages detail-level maps
3. **MapCoordinator** - Handles world↔tactical relationships
4. **ScaleConfig** - Defines size/scale relationships

**Impact:**
- **Modified proposals:**
  - `add-chunk-generation` - May not be needed, or refocus on tactical map streaming
  - `add-map-persistence` - Extend to support multi-map saves
  - `add-map-serialization` - Apply primarily to tactical maps
- **New capabilities:** Multi-scale generation, tactical instantiation
- **Breaking:** Potentially changes generation architecture

### Option 2: Extend Existing Proposals

**Alternative Approach:** Modify current proposals to incorporate multi-scale support

**Modifications Needed:**
1. **Extend `add-chunk-generation`:**
   - Rename/refocus on "tactical map chunks" rather than "world streaming chunks"
   - Add world-to-tactical mapping

2. **Extend `add-map-persistence`:**
   - Add support for "map collections" (1 world + N tactical)
   - Define file structure for multi-map saves

3. **Extend `add-generation-config`:**
   - Add scale-specific configs (world_config vs tactical_config)
   - Define coordinate mapping parameters

**Risk:** May overload existing proposals with additional complexity

---

## Proposed Architecture (High-Level)

### Data Model

```gdscript
# World Map
class WorldMap:
    var dimensions: Vector2i  # e.g., 256x256 cells
    var seed: int
    var tile_data: Array  # Strategic-level tiles
    var metadata: Dictionary  # Biomes, elevation per cell
    var modification_locked: bool = true  # Immutable

# Tactical Map Instance
class TacticalMap:
    var world_position: Vector2i  # Which world cell this represents
    var dimensions: Vector2i  # e.g., 64x64 tiles
    var tile_data: Array  # Detailed tiles
    var modification_tracker: ModificationTracker  # Track player edits
    var parent_world: WorldMap  # Reference to world

# Map Coordinator
class MapCoordinator:
    var world_map: WorldMap
    var active_tactical_maps: Dictionary  # Vector2i -> TacticalMap
    var tactical_cache: LRUCache  # Recently used tactical maps

    func get_tactical_map(world_pos: Vector2i) -> TacticalMap:
        # Load from disk if saved, or generate new
        pass

    func world_to_tactical_coords(world_pos: Vector2i, local_offset: Vector2i) -> Vector2i:
        # Convert world cell + offset to tactical tile coords
        pass
```

### Generation Flow

```
1. Generate World Map (once)
   ├─ Use world seed
   ├─ Generate strategic tiles (biomes, elevation)
   ├─ Save world_map.procmap
   └─ Lock world map (immutable)

2. Player Selects World Cell (100, 200)
   ├─ Check if tactical map exists: tactical/tactical_100_200.procmap
   ├─ If exists: Load tactical map (with modifications)
   └─ If not: Generate new tactical map
       ├─ Derive tactical seed from world seed + position
       ├─ Get world cell data (biome, elevation)
       ├─ Generate 64x64 tactical tiles using inherited context
       └─ Create new TacticalMap instance

3. Player Modifies Tactical Map
   ├─ Track modifications (ModificationTracker)
   ├─ Save delta: tactical/tactical_100_200.procmap
   └─ World map remains unchanged

4. Player Returns to World Map
   ├─ Unload tactical map (cache or persist)
   └─ Return to world view
```

### Persistence Structure

```
saves/my_campaign/
├── world/
│   ├── world_map.procmap          # Strategic map data
│   └── world_config.json          # World generation params
└── tactical/
    ├── tactical_100_200.procmap   # Per-region tactical maps
    ├── tactical_100_201.procmap
    └── tactical_105_200.procmap
```

---

## Integration with Roadmap

### Proposed Phase Insertion

**New Phase 2.5: Multi-Scale Architecture** (insert between current Phase 2 and 3)

- **Duration:** 3-4 weeks
- **Dependencies:** Phase 1 (noise generation), Phase 2 (biomes)
- **Proposals:**
  - `add-multi-scale-maps` (NEW)
  - Modifications to `add-generation-config` (add scale support)
- **Deliverables:**
  - WorldMap and TacticalMap classes
  - MapCoordinator for managing multiple maps
  - Coordinate mapping system
  - Demo scene showing world→tactical drill-down

**Updated Phase 3 and 4:**
- Phase 3 (chunk generation) - Refocus on tactical map chunks or defer/remove
- Phase 4 (persistence) - Extend to support multi-map collections

### Revised Timeline

| Phase | Duration | Purpose |
|-------|----------|---------|
| Phase 1: Foundation | 2-3 weeks | Core generation + config |
| Phase 2: Biomes | 2-3 weeks | Multi-layer generation |
| **Phase 2.5: Multi-Scale** | **3-4 weeks** | **World/tactical architecture** |
| Phase 3: Plugins & Chunks | 3-4 weeks | Extensibility + tactical chunks |
| Phase 4: Persistence | 2-3 weeks | Multi-map save/load |

**New Total:** ~16 weeks (4 months)

---

## Action Items

### Immediate

1. **Clarify Requirements:**
   - Define exact world map dimensions (e.g., 256x256? 512x512?)
   - Define exact tactical map dimensions (e.g., 64x64? 128x128?)
   - Confirm world map mutability (fully immutable or limited edits?)
   - Confirm tactical map regeneration policy (persistent or regenerable?)

2. **Create OpenSpec Proposal:**
   - Author `add-multi-scale-maps` proposal
   - Include design doc with architecture decisions
   - Define specs for WorldMap, TacticalMap, MapCoordinator
   - Create tasks breakdown

3. **Update Roadmap:**
   - Insert Phase 2.5 for multi-scale implementation
   - Adjust Phase 3/4 to integrate with multi-scale
   - Update timeline estimates

### Future

4. **Prototype Multi-Scale:**
   - Build minimal proof-of-concept
   - Test world→tactical generation flow
   - Validate coordinate mapping approach

5. **Integrate with Existing Proposals:**
   - Ensure map-serialization works with TacticalMap
   - Ensure map-persistence supports multi-map structure
   - Ensure plugin architecture supports scale-specific generators

---

## Conclusion

**The current project proposals do NOT fully support the multi-scale (world/tactical) architecture described.**

While the foundational capabilities (generation, modification tracking, persistence) are solid, **critical architectural components are missing:**
- Multi-scale map structure
- Coordinate mapping
- Tactical instantiation
- Generation inheritance
- Multi-map persistence management

**Recommendation:** Create a new OpenSpec proposal (`add-multi-scale-maps`) to explicitly address these gaps. This should be inserted as Phase 2.5 in the roadmap, between biome generation and chunk/plugin architecture.

This is a **significant architectural decision** that should be designed early, as it will influence how persistence, chunks, and plugins are implemented in later phases.
