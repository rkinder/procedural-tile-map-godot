# Testing Guide - Noise-Based Terrain Generation

This guide helps you test the procedural terrain generation implementation.

## Quick Start

1. **Open the project in Godot 4.x**
   - Launch Godot Engine
   - Click "Import" and select this project folder
   - Open `project.godot`

2. **Open the demo scene**
   - Navigate to `scenes/terrain_demo.tscn`
   - Double-click to open it

3. **Run the scene**
   - Press F5 or click the "Play Scene" button
   - The map should generate automatically!

## What You Should See

- A 512×512 tile map should appear
- Console output showing:
  ```
  MapGenerator: Starting generation with seed [number] (512 x 512)
  MapGenerator: Generation completed in [time] ms
  MapGenerator: Tile Distribution:
    Water: [percent]%
    Sand:  [percent]%
    Grass: [percent]%
    Stone: [percent]%
    Snow:  [percent]%
  ```

## Testing Checklist

### ✅ Basic Functionality Tests

- [ ] Map generates when scene is run
- [ ] Generation completes in < 1000ms (should be ~300-600ms)
- [ ] All 5 tile types are visible (blue water, yellow sand, green grass, gray stone, white snow)
- [ ] No errors in the console
- [ ] Camera is properly positioned to view the map

### ✅ Seed Testing (Reproducibility)

1. Note the seed from console output
2. In Inspector, set MapGenerator's `random_seed` to that number
3. Run the scene again
4. **Expected**: Identical map generation
5. Change seed to a different number
6. Run the scene again
7. **Expected**: Different map generation

### ✅ Parameter Testing

Test different noise configurations:

#### Test 1: Different Noise Types
- [ ] Set `noise_type_name` to "Simplex" - smooth terrain
- [ ] Set `noise_type_name` to "Perlin" - classic smooth terrain
- [ ] Set `noise_type_name` to "Cellular" - cell-like patterns

#### Test 2: Frequency Variations
- [ ] `noise_frequency = 0.005` - large continents
- [ ] `noise_frequency = 0.01` - balanced (default)
- [ ] `noise_frequency = 0.05` - small islands

#### Test 3: Octave Variations
- [ ] `noise_octaves = 1` - very smooth
- [ ] `noise_octaves = 3` - balanced (default)
- [ ] `noise_octaves = 6` - detailed/rough

#### Test 4: Threshold Adjustments
- [ ] `water_threshold = 0.0` - more ocean
- [ ] `water_threshold = -0.5` - less ocean
- [ ] `stone_threshold = 0.5` - more mountains
- [ ] `stone_threshold = 0.9` - only peaks have snow

### ✅ Different Map Sizes

- [ ] 64×64 - very fast generation
- [ ] 128×128 - fast generation
- [ ] 256×256 - moderate generation
- [ ] 512×512 - target size (should be < 1 second)

### ✅ Statistics Validation

With `show_statistics = true`:
1. Check that percentages add up to ~100%
2. Verify tile distribution makes sense
   - Water should be 20-40% typically
   - Grass should be largest land type
   - Snow should be smallest (high peaks only)

### ✅ Manual Generation Test

1. Set `auto_generate = false` in Inspector
2. Run the scene
3. **Expected**: Blank TileMap (no generation)
4. In the Godot debugger/console, call:
   ```gdscript
   $MapGenerator.generate_map()
   ```
5. **Expected**: Map generates

## Performance Benchmarks

Expected generation times on modern hardware (2020+ CPU):

| Map Size | Octaves | Expected Time |
|----------|---------|---------------|
| 64×64    | 3       | ~20-40ms      |
| 128×128  | 3       | ~80-120ms     |
| 256×256  | 3       | ~250-400ms    |
| 512×512  | 3       | ~600-900ms    |
| 512×512  | 6       | ~1000-1500ms  |

**If generation is slower**:
- Reduce octaves
- Reduce map size
- Check if debug mode is enabled

## Debugging Common Issues

### Issue: "TileMap not assigned" error

**Cause**: The MapGenerator's `tile_map_path` is not set

**Fix**:
1. Select the MapGenerator node
2. In Inspector, find "Node References" → "Tile Map Path"
3. Click the icon and select `../TileMap`

### Issue: All tiles are one color / missing tiles

**Cause**: TileSet not properly configured or tile graphics missing

**Fix**:
1. Check that SVG files exist in `assets/tiles/`
2. Select the TileMap node
3. In Inspector, verify "Tile Set" is assigned
4. Open the TileSet editor and verify all 5 tile sources exist

### Issue: Generation is very slow (> 2 seconds)

**Cause**: Too many octaves or very large map

**Fix**:
1. Reduce `noise_octaves` to 3
2. Reduce map size
3. Verify `debug_timing = true` to see actual time

### Issue: Map looks weird / all one terrain type

**Cause**: Thresholds not properly ordered

**Fix**:
1. Verify thresholds are in ascending order:
   - water_threshold < sand_threshold < grass_threshold < stone_threshold
2. Check console for validation warnings
3. Reset to defaults: -0.3, 0.0, 0.4, 0.7

## Code Validation Tests

### NoiseGenerator Tests

Create a test script to verify NoiseGenerator:

```gdscript
func test_noise_generator():
    var noise = NoiseGenerator.new(12345)

    # Test 1: Same seed produces same values
    var val1 = noise.get_noise_2d(10, 20)
    var val2 = noise.get_noise_2d(10, 20)
    assert(val1 == val2, "Same coordinates should return same value")

    # Test 2: Values are in range
    for x in range(100):
        for y in range(100):
            var val = noise.get_noise_2d(x, y)
            assert(val >= -1.0 and val <= 1.0, "Noise should be in range [-1, 1]")

    # Test 3: Normalized values
    var norm = noise.get_noise_normalized(10, 20)
    assert(norm >= 0.0 and norm <= 1.0, "Normalized noise should be in range [0, 1]")

    print("NoiseGenerator: All tests passed!")
```

### TileMapper Tests

```gdscript
func test_tile_mapper():
    var mapper = TileMapper.new()

    # Test 1: Threshold boundaries
    assert(mapper.map_noise_to_tile(-0.5) == TileMapper.WATER)
    assert(mapper.map_noise_to_tile(-0.1) == TileMapper.SAND)
    assert(mapper.map_noise_to_tile(0.2) == TileMapper.GRASS)
    assert(mapper.map_noise_to_tile(0.5) == TileMapper.STONE)
    assert(mapper.map_noise_to_tile(0.9) == TileMapper.SNOW)

    # Test 2: Statistics
    mapper.enable_statistics()
    mapper.map_noise_to_tile(-0.5)
    mapper.map_noise_to_tile(-0.5)
    mapper.map_noise_to_tile(0.5)
    var dist = mapper.get_tile_distribution()
    assert(dist["Water"] == 2)
    assert(dist["Stone"] == 1)

    print("TileMapper: All tests passed!")
```

## Visual Validation

Expected visual patterns:

1. **Water (blue)**: Should form connected bodies (oceans, lakes)
2. **Sand (yellow)**: Should border water as "beaches"
3. **Grass (green)**: Should be the dominant land type
4. **Stone (gray)**: Should appear as "mountain ranges"
5. **Snow (white)**: Should only appear on the highest peaks

**Good terrain**:
- Natural-looking coastlines (not straight lines)
- Varying landmass sizes
- Clustered features (mountains in ranges, not scattered)

**Bad terrain** (indicates configuration issues):
- Checkerboard patterns (frequency too high)
- Extremely uniform (frequency too low, octaves = 1)
- All one type (thresholds misconfigured)

## Acceptance Criteria

The implementation passes if:

- ✅ Generates 512×512 map in < 1 second
- ✅ Same seed produces identical maps
- ✅ Different seeds produce varied maps
- ✅ All 5 tile types are visible and natural-looking
- ✅ No errors or warnings in console (except validation if thresholds are wrong)
- ✅ Statistics show reasonable distribution (no single type > 70%)
- ✅ Parameters can be changed in Inspector and affect output
- ✅ Code is well-documented with beginner-friendly comments

## Next Steps After Testing

Once tests pass:

1. Experiment with parameters to find interesting configurations
2. Take screenshots of cool generated maps
3. Note down interesting seeds
4. Read `TERRAIN_GENERATION_GUIDE.md` for deeper understanding
5. Try the suggested exercises to extend the system

## Performance Profiling (Advanced)

To profile generation performance:

1. Open Godot Profiler (Debug → Profiler)
2. Run the scene
3. Look at the profiler timeline
4. Identify hotspots:
   - `get_noise_2d()` calls
   - `map_noise_to_tile()` calls
   - `set_cell()` calls

Expected breakdown:
- 40-50%: Noise generation
- 10-20%: Tile mapping
- 30-40%: TileMap updates

If proportions are very different, there may be optimization opportunities.

---

Happy testing! 🎮
