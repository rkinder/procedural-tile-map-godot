# Specification: Coordinate Mapping

Translates coordinates between world space (strategic cells) and tactical space (detailed tiles).

## ADDED Requirements

### Requirement: Coordinate mapper must convert world cell to tactical region

Given a world cell coordinate, system SHALL return the corresponding tactical tile region bounds.

#### Scenario: Map world cell to tactical region

```gdscript
var mapper = CoordinateMapper.new()
mapper.tactical_dimensions = Vector2i(64, 64)

var region = mapper.world_to_tactical_region(Vector2i(10, 20))

# World cell (10, 20) maps to tactical region starting at (640, 1280)
assert(region.position == Vector2i(640, 1280))
assert(region.size == Vector2i(64, 64))
assert(region.end == Vector2i(704, 1344))
```

### Requirement: Coordinate mapper must convert tactical tile to world cell

Given a tactical tile coordinate, system SHALL return the containing world cell.

#### Scenario: Map tactical tile to world cell

```gdscript
var mapper = CoordinateMapper.new()
mapper.tactical_dimensions = Vector2i(64, 64)

var world_cell = mapper.tactical_to_world(Vector2i(650, 1290))

# Tactical tile (650, 1290) is within world cell (10, 20)
assert(world_cell == Vector2i(10, 20))
```

### Requirement: Coordinate mapper must handle tactical-local coordinates

System SHALL convert absolute tactical coordinates to relative coordinates within their world cell.

#### Scenario: Convert tactical absolute to local coordinates

```gdscript
var mapper = CoordinateMapper.new()
mapper.tactical_dimensions = Vector2i(64, 64)

var world_cell = Vector2i(10, 20)
var tactical_absolute = Vector2i(650, 1290)

var local = mapper.tactical_absolute_to_local(tactical_absolute, world_cell)

# Tactical (650, 1290) relative to world cell (10, 20) region start (640, 1280)
assert(local == Vector2i(10, 10))
```

### Requirement: Coordinate mapper must convert local tactical to absolute

System SHALL convert relative tactical coordinates (within a world cell) to absolute tactical coordinates.

#### Scenario: Convert local tactical to absolute coordinates

```gdscript
var mapper = CoordinateMapper.new()
mapper.tactical_dimensions = Vector2i(64, 64)

var world_cell = Vector2i(10, 20)
var local = Vector2i(10, 10)

var absolute = mapper.tactical_local_to_absolute(local, world_cell)

# Local (10, 10) within world cell (10, 20) → absolute (650, 1290)
assert(absolute == Vector2i(650, 1290))
```

### Requirement: Coordinate mapper must validate coordinate conversions

Out-of-bounds or negative coordinates SHALL be handled gracefully with errors/warnings.

#### Scenario: Handle negative coordinates

```gdscript
var mapper = CoordinateMapper.new()
mapper.tactical_dimensions = Vector2i(64, 64)

var world_cell = mapper.tactical_to_world(Vector2i(-10, -10))

# Should handle gracefully (return null or clamp to 0,0)
assert(world_cell == Vector2i(0, 0) or world_cell == null)
# Warning logged: "Negative tactical coordinates: (-10, -10)"
```

### Requirement: Coordinate mapper must support configurable tactical dimensions

Tactical dimensions (tiles per world cell) SHALL be configurable via ScaleConfig.

#### Scenario: Configure tactical dimensions

```gdscript
var mapper = CoordinateMapper.new()
mapper.tactical_dimensions = Vector2i(128, 128)  # Larger tactical maps

var region = mapper.world_to_tactical_region(Vector2i(5, 5))

assert(region.position == Vector2i(640, 640))  # 5 * 128 = 640
assert(region.size == Vector2i(128, 128))
```

### Requirement: Coordinate mapper must handle edge cases at boundaries

Boundary coordinates (0,0) and max boundaries SHALL be handled correctly.

#### Scenario: Map boundary world cells

```gdscript
var mapper = CoordinateMapper.new()
mapper.tactical_dimensions = Vector2i(64, 64)

# Origin world cell
var region_origin = mapper.world_to_tactical_region(Vector2i(0, 0))
assert(region_origin.position == Vector2i(0, 0))

# Maximum world cell (255, 255) with 256x256 world
var region_max = mapper.world_to_tactical_region(Vector2i(255, 255))
assert(region_max.position == Vector2i(16320, 16320))  # 255 * 64
```

### Requirement: Coordinate mapper must provide conversion helpers for common cases

System SHALL provide utility methods for frequently used conversions.

#### Scenario: Check if tactical tile is at world cell boundary

```gdscript
var mapper = CoordinateMapper.new()
mapper.tactical_dimensions = Vector2i(64, 64)

var is_boundary = mapper.is_tactical_at_cell_boundary(Vector2i(640, 1280))
assert(is_boundary == true)  # Exactly at world cell (10, 20) start

var is_not_boundary = mapper.is_tactical_at_cell_boundary(Vector2i(645, 1285))
assert(is_not_boundary == false)  # Interior to world cell
```
