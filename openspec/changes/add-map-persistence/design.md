## Context
Map persistence enables saving and loading procedurally generated maps, which is essential for preserving user-modified maps and avoiding regeneration costs. This introduces data model, serialization, and security considerations.

## Goals / Non-Goals
**Goals:**
- Fast save/load for maps up to 512x512
- Preserve all generation metadata for reproducibility
- Compact file sizes through compression
- Robust validation to prevent crashes from invalid data
- Version compatibility for future format evolution

**Non-Goals:**
- Cloud storage or networked saves (local filesystem only)
- Incremental/differential saves (save full map each time)
- Automatic autosave system (manual save/load only for now)
- Undo/redo history (separate capability)

## Decisions

### Decision: Support Three Serialization Formats
Provide JSON (human-readable), binary (compact), and Godot Resource (.tres) formats, with binary as default.

**Rationale:**
- JSON: Debugging, version control friendliness, human inspection
- Binary: Production use, minimal file size, fast parsing
- Resource: Native Godot workflow, inspector integration

**Alternatives considered:**
- Single format (binary only): Less flexible, harder to debug
- Custom text format: Reinventing the wheel, JSON sufficient

### Decision: Run-Length Encoding (RLE) for Tile Data
Use RLE compression for tile arrays before serialization, as procedural maps often have contiguous regions of identical tiles.

**Rationale:**
- Excellent compression for homogeneous regions (e.g., oceans, deserts)
- Simple algorithm, fast encode/decode
- Effective for 512x512 = 262,144 tiles

**Alternatives considered:**
- No compression: File sizes too large (512x512 = ~1MB+ uncompressed)
- GZip only: Good but doesn't exploit tile pattern structure
- Delta encoding: More complex, RLE likely sufficient

### Decision: Embed GenerationConfig in Saved Maps
Store complete generation configuration (seed, parameters) as metadata in every saved map.

**Rationale:**
- Enables regeneration from seed if needed
- Documents map provenance (how it was created)
- Supports "remix" workflows (modify params and regenerate)

**Alternatives considered:**
- Store seed only: Insufficient if config system changes
- Don't store metadata: Loses reproducibility

### Decision: Semantic Versioning for Save Format
Use semver-style version numbers (e.g., v1.0.0) for save format, embedded in file header.

**Rationale:**
- Standard practice for data formats
- Enables backward compatibility checks
- Clear migration path for breaking changes

**Alternatives considered:**
- No versioning: Impossible to evolve format safely
- Timestamp-based: Less semantic, harder to reason about compatibility

### Decision: Fail-Safe Validation on Load
Validate all loaded data strictly; use fallback tiles for invalid tile IDs rather than crashing.

**Rationale:**
- Prevents crashes from corrupted files or malicious input
- Graceful degradation better than total failure
- Security: untrusted files can't exploit parser vulnerabilities

## Risks / Trade-offs

**Risk:** RLE may not compress well for noisy/varied maps
- **Mitigation:** Test with real map data; add GZip as second compression layer if needed

**Risk:** Format versioning adds complexity
- **Mitigation:** Start with v1, only add migration when breaking changes needed

**Risk:** Large maps (512x512) may still have large file sizes even compressed
- **Mitigation:** Benchmark and optimize; document expected file sizes; consider chunk-based loading in future

**Trade-off:** Three formats vs. single format
- **Impact:** More code to maintain, but better flexibility
- **Decision:** Worth it for debugging (JSON) and Godot integration (Resource)

## Migration Plan
This is a new capability. Integration steps:
1. Implement MapSerializer class independently
2. Test serialization with generated maps
3. Add save/load UI/methods to map manager
4. Document file format for users
5. Provide example save files

No migration of existing data (no saves exist yet).

## Open Questions
- Should we support partial map loading (load only visible area)? → No, defer to chunk-based loading capability if needed
- Should saves include undo history? → No, keep saves simple; undo is separate capability
- What file extension to use? → .procmap for custom binary, .json/.tres for respective formats
- Should we support exporting to image formats (PNG)? → Out of scope; separate export capability
