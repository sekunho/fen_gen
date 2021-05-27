import sys
from tensorflow import keras

for line in sys.stdin:
    line = line.strip()
    # EOF
    if line == "": break
    
    # # strings to ints, and sum
    # values = line.split(",")
    # nums = map(int, values)
    # result = sum(nums)

    # send the result via stdout
    # sys.stdout.write(str(result) + "\n")
    sys.stdout.write(line)
    sys.stdout.flush()

# model = keras.models.load_model('model.h5')
# model.predict()