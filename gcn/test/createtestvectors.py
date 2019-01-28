#! /Users/yuanchihwu/anaconda/bin/python
import random
import sys

_MAX_FEAT_VAL = 10
_BATCH_SIZE = 128

# Per Node Defines
_NUM_FEAT = 256
_NUM_NEIGHBORS = 8

def writeIndividualFiles(file_suffix):
    input_f = "testvectors/input_" + file_suffix + ".txt"
    weight_f = "testvectors/weight_" + file_suffix + ".txt"
    activate_f = "testvectors/activate_" + file_suffix + ".txt"

    with open(input_f, 'w') as f:
        print (input_f)
        for i in range(_NUM_FEAT*2):
            line = ""
            for j in range(_BATCH_SIZE):
                line = line + str(random.randint(0, _MAX_FEAT_VAL)) + " "
            line = line[:-1]
            line = line + "\n"
            f.write(line)

    with open(weight_f, 'w') as f:
        print (weight_f)
        for i in range(_NUM_FEAT*2):
            line = ""
            for j in range(_NUM_FEAT):
                line = line + str(random.randint(0, _MAX_FEAT_VAL)) + " "
            line = line[:-1]
            line = line + "\n"
            f.write(line)

    with open(activate_f, 'w') as f:
        print (activate_f)
        for i in range(_NUM_FEAT):
            line = ""
            for j in range(_NUM_FEAT):
                line = line + str(random.randint(0, _MAX_FEAT_VAL)) + " "
            line = line[:-1]
            line = line + "\n"
            f.write(line)

def writeSingleFile():
    data_f = "testvectors/data.txt"
    print (data_f)

    with open(data_f, 'w') as f:
        for i in range(_NUM_FEAT*2):
            line = ""
            for j in range(_BATCH_SIZE):
                line = line + str(random.randint(0, _MAX_FEAT_VAL)) + " "
            line = line[:-1]
            line = line + "\n"
            f.write(line)

        #f.write("\n") # Remove to simplify test processing
        for i in range(_NUM_FEAT*2):
            line = ""
            for j in range(_NUM_FEAT):
                line = line + str(random.randint(0, _MAX_FEAT_VAL)) + " "
            line = line[:-1]
            line = line + "\n"
            f.write(line)

        #f.write("\n") # Remove to simplify test processing
        for i in range(_NUM_FEAT):
            line = ""
            for j in range(_NUM_FEAT):
                line = line + str(random.randint(0, _MAX_FEAT_VAL)) + " "
            line = line[:-1]
            line = line + "\n"
            f.write(line)


# Create test vectors
# If arg provided, creates 3 separate files
# If arg not provided, creates 1 single file
def main():
    print ("Creating test vectors...")
    try:
        file_suffix = str(sys.argv[1])
        writeIndividualFiles(file_suffix)
    except:
        writeSingleFile()


main()
