extends RefCounted
class_name WorldConstants

## World Generation Constants
const CHUNK_SIZE: int = 64
const WORLD_WIDTH: int = 1000  # This will be used for initial generation
const WORLD_HEIGHT: int = 1200  # Changed to 1,200 blocks deep
const BLOCK_SIZE: int = 8

## Chunk Generation Constants
const CHUNK_UPDATE_THRESHOLD: int = 5  # Only update chunks every N frames
const CHUNK_UNLOAD_BUFFER: int = 2  # Keep chunks loaded this many chunks beyond generation distance

## Initial Generation Constants
const INITIAL_CHUNKS_RANGE: int = 1  # Generate ±1 chunks around spawn point (3x3 grid)
const INITIAL_SURFACE_GENERATION_DEPTH: int = 20  # Initial depth below surface when first generating chunks
