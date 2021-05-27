import os
import glob
import re
import numpy as np                   # advanced math library
import matplotlib.pyplot as plt      # MATLAB like plotting routines
import random                        # for generating random numbers
from skimage.util.shape import view_as_blocks
from skimage import io, transform
from tensorflow.keras.models import Sequential  # Model type to be used
from tensorflow.keras import Sequential
from tensorflow.keras import optimizers
from tensorflow.keras.layers import Conv2D, MaxPooling2D, Flatten, Dropout, Dense
from tensorflow.python.keras.utils import np_utils                         # NumPy related tools
from tensorflow.python.client import device_lib
import tensorflow as tf
from tensorflow.keras.callbacks import EarlyStopping

print("Num GPUs Available: ", len(tf.config.list_physical_devices("GPU")))
print(device_lib.list_local_devices())

PIECES = "rnbqkpRNBQKP"
ARCHIVE_PATH = "/home/sekun/Documents/archive"
TRAIN_PATH = os.path.join(ARCHIVE_PATH, "train")
TEST_PATH = os.path.join(ARCHIVE_PATH, "test")
TRAIN_SIZE = 500
TEST_SIZE = 500


def image_path_to_fen(image_path):
    base = os.path.basename(image_path)
    return os.path.splitext(base)[0]


def fen_to_onehot_vector(fen):
    # Empty vectors for the 13 different tile states.
    eye = np.eye(13)

    # Define accumulator dimensions
    acc = np.empty((0, 13))

    # Remove "-"
    fen = fen.replace("-", "")

    for char in fen:
        if(char in '12345678'):
            vector = np.tile(eye[0], (int(char), 1))
            acc = np.append(acc, vector, axis=0)
        else:
            idx = PIECES.index(char) + 1
            vector = eye[idx].reshape((1, 13))
            acc = np.append(acc, vector, axis=0)

    return acc


def get_image_paths(dir_path):
    if(os.path.exists(dir_path)):
        path_wildcard = os.path.join(dir_path, "*.jpeg")

        return glob.glob(path_wildcard)

    return None


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


def gen_model():
    model = Sequential()
    model.add(Conv2D(32, (3, 3), activation='relu', input_shape=(25, 25, 3)))
    model.add(Dropout(0.2))
    model.add(MaxPooling2D(pool_size=(2, 2), padding='same'))
    model.add(Conv2D(32, (3, 3), activation='relu'))
    model.add(Dropout(0.2))
    model.add(Conv2D(32, (3, 3), activation='relu'))
    model.add(Dropout(0.2))
    model.add(Flatten())
    model.add(Dense(128, activation='relu'))
    model.add(Dropout(0.2))
    model.add(Dense(13, activation='softmax'))

    model.summary()

    return model

def prep(dataset):
  xs = []
  ys = []

  for img_path in dataset:
    tiles = process_board(img_path)

    for tile in tiles:
      xs.append(tile)

    fen = image_path_to_fen(img_path)
    y = fen_to_onehot_vector(fen)
    ys = ys + y.tolist()

  return (np.array(xs), np.array(ys))


# THINGY
train_image_paths = get_image_paths(TRAIN_PATH)
test_image_paths = get_image_paths(TRAIN_PATH)

random.shuffle(train_image_paths)
random.shuffle(test_image_paths)

train = train_image_paths[:TRAIN_SIZE]
test = test_image_paths[:TEST_SIZE]

## Model & training
model = gen_model()
model.compile(loss='categorical_crossentropy',
              optimizer='adam', metrics=['accuracy'])

(x_train, y_train) = prep(train)
(x_test, y_test) = prep(test)

print(len(x_train))
print(len(y_train))

print(x_train[0])
print(y_train[0])

model.fit(x_train,
          y_train,
          epochs=5,
          batch_size=100,
          validation_split=0.20,
          shuffle=True,
          verbose=1)

score = model.evaluate(x_test, y_test)
print('Test score:', score[0])
print('Test accuracy:', score[1])

model.save("model.h5")

print(y_test[300])
predictions = model.predict(x_test)

print(np.argmax(predictions[300]))