## MODIFIED Requirements

### Requirement: Chunk-Based Map Generation
The system SHALL generate maps in discrete chunks rather than as a single monolithic operation, enabling progressive loading and viewport-based generation.

**This modifies the original terrain generation requirement to use chunk-based architecture.**

#### Scenario: Chunk generation
- **WHEN** a map is generated with chunk size 32x32
- **THEN** map is divided into chunks (e.g., 512x512 map = 16x16 chunks)
- **AND** each chunk can be generated independently
- **AND** chunks can be generated progressively across multiple frames

#### Scenario: Independent chunk generation
- **WHEN** chunk at coordinates (2, 3) is generated
- **THEN** only tiles in that chunk region are generated
- **AND** generation does not depend on other chunks being generated
- **AND** noise values are consistent with global seed

#### Scenario: Seamless chunk boundaries
- **WHEN** adjacent chunks are generated
- **THEN** noise values are continuous across boundaries
- **AND** no visual seams or artifacts appear at chunk edges
- **AND** terrain transitions are natural

### Requirement: Progressive Generation
The system SHALL support progressive chunk generation spread across multiple frames to prevent UI freezing.

#### Scenario: Non-blocking generation
- **WHEN** a large map (512x512) is generated progressively
- **THEN** generation occurs across multiple frames
- **AND** UI remains responsive during generation
- **AND** framerate stays above 30 FPS during generation

#### Scenario: Generation progress tracking
- **WHEN** progressive generation is active
- **THEN** progress percentage is available (e.g., 45 of 256 chunks)
- **AND** progress signals are emitted for UI updates
- **AND** estimated completion time is available (optional)

#### Scenario: Cancellable generation
- **WHEN** user cancels generation mid-process
- **THEN** generation stops immediately
- **AND** already-generated chunks remain valid
- **AND** partial map can be used or discarded

### Requirement: Viewport-Based Chunk Loading
The system SHALL support loading and unloading chunks based on viewport/camera position.

#### Scenario: Chunks load near viewport
- **WHEN** viewport is at world position (256, 256)
- **THEN** chunks within load_radius are generated/loaded
- **AND** distant chunks beyond unload_radius are unloaded
- **AND** player sees seamless terrain as they move

#### Scenario: Hysteresis prevents thrashing
- **WHEN** viewport moves near chunk boundary
- **THEN** chunk loading uses load_radius (e.g., 3 chunks)
- **AND** chunk unloading uses unload_radius (e.g., 5 chunks)
- **AND** chunks don't rapidly load/unload during small movements

#### Scenario: Dynamic loading as player moves
- **WHEN** viewport moves to new area
- **THEN** new chunks ahead are generated/loaded
- **AND** old chunks behind are unloaded after exceeding unload_radius
- **AND** memory usage stays within configured limits

### Requirement: Chunk Caching
The system SHALL cache generated chunks in memory to avoid regeneration when revisiting areas.

#### Scenario: Chunk cache hit
- **WHEN** a previously generated chunk is needed again
- **THEN** cached chunk data is used
- **AND** regeneration is avoided
- **AND** retrieval is near-instantaneous

#### Scenario: LRU cache eviction
- **WHEN** cache reaches maximum size (e.g., 200 chunks)
- **THEN** least recently used chunk is evicted
- **AND** new chunk can be cached
- **AND** memory usage stays within limit

#### Scenario: Configurable cache limit
- **WHEN** user sets max cached chunks to 100
- **THEN** cache never exceeds 100 chunks
- **AND** memory usage is predictable
- **AND** user can tune for their platform

### Requirement: Configurable Chunk Size
The system SHALL support configurable chunk sizes (16x16, 32x32, 64x64 tiles) to balance granularity and performance.

#### Scenario: 32x32 chunk size (default)
- **WHEN** chunk size is set to 32x32
- **THEN** each chunk contains 1024 tiles
- **AND** 512x512 map is divided into 256 chunks (16x16 grid)

#### Scenario: Chunk size affects loading granularity
- **WHEN** chunk size is 16x16 (smaller)
- **THEN** more chunks are created
- **AND** loading is more granular but with more overhead
- **WHEN** chunk size is 64x64 (larger)
- **THEN** fewer chunks are created
- **AND** loading is coarser but with less overhead

### Requirement: Generation Modes
The system SHALL support multiple chunk generation modes: on-demand, pre-generation, and hybrid.

#### Scenario: On-demand mode
- **WHEN** on-demand mode is enabled
- **THEN** chunks are generated only when viewport approaches
- **AND** distant chunks remain ungenerated
- **AND** memory usage is minimized

#### Scenario: Pre-generation mode
- **WHEN** pre-generation mode is enabled
- **THEN** all chunks are generated upfront progressively
- **AND** entire map is available immediately after completion
- **AND** no further generation occurs during gameplay

#### Scenario: Hybrid mode
- **WHEN** hybrid mode is enabled
- **THEN** center region is pre-generated
- **AND** edge regions use on-demand generation
- **AND** balance between instant availability and memory usage

### Requirement: Deterministic Chunk Generation
The system SHALL ensure chunk generation is deterministic given the same seed and configuration, regardless of generation order.

#### Scenario: Order-independent determinism
- **WHEN** chunks are generated in order (0,0), (0,1), (1,0)
- **AND** same chunks are generated in order (1,0), (0,0), (0,1)
- **THEN** tile values in each chunk are identical
- **AND** noise patterns are consistent

#### Scenario: Seed-based reproducibility
- **WHEN** map is generated with seed 42 in chunks
- **THEN** each chunk's content matches single-pass generation with seed 42
- **AND** chunk boundaries don't affect determinism
