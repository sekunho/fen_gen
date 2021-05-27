import sys
import os
import numpy as np

from skimage.util.shape import view_as_blocks
from skimage import io, transform
from tensorflow import keras

MODEL_PATH = os.path.abspath("./scripts/model.h5")

def process_board(board_path):
    # Dimensions of each tile
    square_size = 25

    board = io.imread(board_path)
    board = transform.resize(
        board, (200, 200), mode='constant')

    tiles = view_as_blocks(board, block_shape=(square_size, square_size, 3))
    tiles = tiles.squeeze(axis=2)
    tiles = tiles.reshape(64, square_size, square_size, 3)

    return tiles

def prep_board(img_path):
  xs = []
  tiles = process_board(img_path)

  for tile in tiles:
    xs.append(tile)

  return np.array(xs)

model = keras.models.load_model(MODEL_PATH)

for line in sys.stdin:
    line = line.strip()

    if line == "": break

    model.predict()
    
    # # strings to ints, and sum
    # values = line.split(",")
    # nums = map(int, values)
    # result = sum(nums)

    # send the result via stdout
    # sys.stdout.write(str(result) + "\n")
    sys.stdout.write(line)
    sys.stdout.flush()
