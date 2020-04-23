import sys
import os
import random
import getopt
import math


# main
def main(argv):
    (numOfTests, memorySize, numOfWorkingZones, workingZoneSize, filePath) = parseCmdLineArgs(argv)
    maxWorkingZone = int(memorySize - workingZoneSize)

    ramFile = open(filePath, "w")
    barIsPrintable = True

    for tests in range(1, numOfTests + 1):
        coverableAddresses = []
        coveredAddresses = []
        wzAddrList = []

        # in the beginning all addresses are coverable
        for memAddr in range(0, maxWorkingZone):
            coverableAddresses.append(memAddr)

        # extract a list of WZ base addresses
        for numWZ in range(0, numOfWorkingZones):
            wzAddr = coverableAddresses.pop(random.randint(0, len(coverableAddresses) - 1))

            # remove covered addresses and addresses that cannot be a working zone base address
            # because WZs cannot overlap
            for addr in range(wzAddr - workingZoneSize + 1, wzAddr + workingZoneSize):
                try:
                    coverableAddresses.remove(int(addr))
                except ValueError:
                    pass

            # add covered addresses to the list
            for addr in range(wzAddr, wzAddr + workingZoneSize):
                coveredAddresses.append(addr)

            # add the base address to the list
            wzAddrList.append(wzAddr)

        # first test, address in a WZ, first start signal
        ramFile.write(genTest_addressInWZ(numOfWorkingZones, tests + .1, workingZoneSize, wzAddrList, coveredAddresses))
        # second test, address in a WZ, second start signal
        ramFile.write(genTest_addressInWZ(numOfWorkingZones, tests + .2, workingZoneSize, wzAddrList, coveredAddresses))
        # third test, address in a wz, asynchronous reset
        ramFile.write(genTest_addressInWZ(numOfWorkingZones, tests + .3, workingZoneSize, wzAddrList, coveredAddresses))
        # fourth test, address not in a WZ, first start signal
        ramFile.write(
            genTest_addressOutOfWZ(numOfWorkingZones, tests + .4, workingZoneSize, wzAddrList, coverableAddresses))
        # fifth test, address not in a WZ, second start signal
        ramFile.write(
            genTest_addressOutOfWZ(numOfWorkingZones, tests + .5, workingZoneSize, wzAddrList, coverableAddresses))
        # sixth test, address not in a WZ, asynchronous reset
        ramFile.write(
            genTest_addressOutOfWZ(numOfWorkingZones, tests + .6, workingZoneSize, wzAddrList, coverableAddresses))
        if barIsPrintable:
            try:
                if barIsPrintable:
                    updateProgressBar(tests, numOfTests)
            except OSError:
                barIsPrintable = False


def genTest_addressInWZ(numOfWorkingZones, tests, workingZoneSize, wzAddrList, coveredAddresses):
    # extract a random address from the covered ones
    randomCoveredAddress = int(
        random.sample(coveredAddresses, len(coveredAddresses))[random.randint(0, len(coveredAddresses) - 1)])
    # calculate the expected output
    WZ_NUM, WZ_OFFSET = calculateWZParameters(numOfWorkingZones, randomCoveredAddress, workingZoneSize, wzAddrList)
    # convert the address following the specs
    inWZ = "1" + toBinary(WZ_NUM, numOfWorkingZones) + toOneHot(WZ_OFFSET, workingZoneSize)
    return str(tests) + ") wz: " + str(wzAddrList) + "; addr: " + str(randomCoveredAddress) + "; output: " \
           + str(str2int(inWZ)) + "\n"


def genTest_addressOutOfWZ(numOfWorkingZones, tests, workingZoneSize, wzAddrList, uncoveredAddress):
    # extract a random address from the uncovered ones
    randomUncoveredAddress = int(
        random.sample(uncoveredAddress, len(uncoveredAddress))[random.randint(0, len(uncoveredAddress) - 1)])

    return str(tests) + ") wz: " + str(wzAddrList) + "; addr: " + str(randomUncoveredAddress) + "; output: " \
           + str(randomUncoveredAddress) + "\n"


def calculateWZParameters(numOfWorkingZones, randomCoveredAddress, workingZoneSize, wzAddrList):
    found = False
    WZ_NUM = 0
    WZ_OFFSET = 0
    for WZ_NUM in range(0, numOfWorkingZones):
        for WZ_OFFSET in range(0, workingZoneSize):
            if wzAddrList[WZ_NUM] + WZ_OFFSET == randomCoveredAddress:
                found = True
                break
        if found:
            break
    return WZ_NUM, WZ_OFFSET


def str2int(binaryString):
    num = 0
    for i in range(0, len(binaryString)):
        if binaryString[i] == '1':
            num += pow(2, len(binaryString) - 1 - i)
    return num


def toOneHot(num, maxSize):
    oneHot = [0] * maxSize
    oneHot[num] = 1
    oneHot.reverse()
    retString = ""
    for i in range(0, len(oneHot)):
        retString += str(oneHot[i])
    return retString


def toBinary(num, maxSize):
    getBin = lambda x, n: format(x, 'b').zfill(n)
    return getBin(num, int(math.ceil(math.log2(maxSize))))


def parseCmdLineArgs(argv):
    testNum = 10
    memSize = 128
    wzNum = 8
    wzSize = 4
    outputFile = "../RAM_" + str(testNum) + "_tests.txt"

    try:
        opts, args = getopt.getopt(argv, "hn:m:w:s:o:",
                                   ["help", "numTests=", "memSize=", "wzNum=", "wzSize=", "outputFile"])
    except getopt.GetoptError:
        sys.exit(2)

    for opt, arg in opts:
        if opt == '-h':
            print("WorkingZone Test Generator Options")
            print("\t-n\t--numTests\tnumber of complete tests to generate (default: " + str(testNum) + ")")
            print("\t-m\t--memSize\tmaximum size of the memory (default: " + str(memSize) + ")")
            print("\t-w\t--wzNum\tnumber of working zones (default: " + str(wzNum) + ")")
            print("\t-s\t--wzSize\tnumber of addresses per working zone (default: " + str(wzSize) + ")")
            print("\t-o\t--outputFile\toutput file (default: " + outputFile + ")")
            sys.exit(0)
        elif opt in ("-n", "--numTests"):
            if int(arg) > 0:
                testNum = arg
                outputFile = "./RAM_" + str(testNum) + "_tests.txt"
        elif opt in ("-m", "--memSize"):
            if int(arg) > 0:
                memSize = arg
        elif opt in ("-w", "--wzNum"):
            if int(arg) > 0:
                wzNum = arg
        elif opt in ("-s", "--wzSize"):
            if int(arg) > 0:
                wzSize = arg
        elif opt in ("-o", "--outputFile"):
            outputFile = arg
        else:
            continue

        if int(memSize) < int(wzSize) * int(wzNum):
            print("Invalid parameters. Exiting...")
            sys.exit(1)

    return int(testNum), int(memSize), int(wzNum), int(wzSize), str(outputFile)


def updateProgressBar(done, total):
    barLength, x = os.get_terminal_size()
    barLength = math.floor(barLength / 2)
    block = int(round(barLength * done / total))
    if done < total:
        status = ("Building test " + str(done) + "\r")
    else:
        status = ("Done!" + " " * int(barLength) + "\r")
    percentage = "%.3f" % round(done / total * 100, 3)
    text = "\rProgress: [{0}] {1}% {2}".format("#" * block + "-" * (barLength - block), percentage, status)
    sys.stdout.write(text)
    sys.stdout.flush()


# run
if __name__ == '__main__':
    main(sys.argv[1:])
