import sys
import os
import numpy as np

from skimage.util.shape import view_as_blocks
from skimage import io, transform
from tensorflow import keras

MODEL_PATH = os.path.abspath("./scripts/model.h5")
PIECES = "*rnbqkpRNBQKP"

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

def get_piece(x):
  x_max = np.argmax(x)

  return PIECES[x_max]

model = keras.models.load_model(MODEL_PATH)

for line in sys.stdin:
    line = line.strip()

    if line == "": break

    x_predict = prep_board(line)
    predictions = model.predict(x_predict)
    pieces_predict = list(map(get_piece, predictions))
    prediction = "".join(pieces_predict)

    sys.stdout.write(prediction + "\n")
    sys.stdout.flush()
