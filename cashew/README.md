# Cashew

A helper library for `fen_gen` for dataset-related functions.

```bash
EXLA_FLAGS=--config=cuda EXLA_TARGET=cuda mix do deps.get, deps.compile
```

# File dump

`cashew` provides functions to dump data into a simple gzipped binary file.

The binary file format is as follows (respectively):

## Images dump

1. 32 bits - number of tiles
2. 32 bits - Tile width
3. 32 bits - Tile height
4. Rest of the bits - Binary data of the images

## Labels dump

1. 32 bits - number of labels
2. Rest of the bits - Binary data of the tiles
