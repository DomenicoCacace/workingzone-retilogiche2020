import sys
import os
import random
import getopt
import math


# main
def main(argv):
    numOfTests = int(getNumOfTests(argv))
    memorySize = int(getMemorySize(argv))
    numOfWorkingZones = int(getWorkingZoneNumber(argv))
    workingZoneSize = int(getWorkingZoneSize(argv))
    maxWorkingZone = int(memorySize - workingZoneSize)
    filePath = getPath(argv)

    ramFile = open(filePath + "RAM_" + str(numOfTests) + "_cases.txt", "w")
    barIsPrintable = True

    if numOfWorkingZones * workingZoneSize > memorySize:
        print("WorkingZones exceeding the memory size. The process will be terminated.")
        input()
        exit(1)

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
        if (barIsPrintable):
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


def getNumOfTests(argv):
    defaultTests = 10

    try:
        opts, args = getopt.getopt(argv, "n:", ["numTests="])
    except getopt.GetoptError:
        return int(defaultTests)

    for opt, arg in opts:
        if opt in ("-n", "--numTests"):

            try:
                if int(arg) > 0:
                    return int(arg)
            except ValueError:
                return int(defaultTests)

    return int(defaultTests)


def getMemorySize(argv):
    defaultMemorySize = 128

    try:
        opts, args = getopt.getopt(argv, "m:", ["memSize="])
    except getopt.GetoptError:
        return int(defaultMemorySize)

    for opt, arg in opts:
        if opt in ("-m", "--memSize"):

            try:
                if int(arg) > 0:
                    return int(arg)
            except ValueError:
                return int(defaultMemorySize)

    return int(defaultMemorySize)


def getWorkingZoneNumber(argv):
    defaultWZNum = 8

    try:
        opts, args = getopt.getopt(argv, "w:", ["wzNum="])
    except getopt.GetoptError:
        return int(defaultWZNum)

    for opt, arg in opts:
        if opt in ("-w", "--wzNum"):

            try:
                if int(arg) > 0:
                    return int(arg)
            except ValueError:
                return int(defaultWZNum)

    return int(defaultWZNum)


def getWorkingZoneSize(argv):
    defaultWZSize = 4

    try:
        opts, args = getopt.getopt(argv, "s:", ["wzSize="])
    except getopt.GetoptError:
        return int(defaultWZSize)

    for opt, arg in opts:
        if opt in ("-s", "--wzSize"):

            try:
                if int(arg) > 0:
                    return int(arg)
            except ValueError:
                return int(defaultWZSize)

    return int(defaultWZSize)


def getPath(argv):
    defaultPath = "../"
    try:
        opts, args = getopt.getopt(argv, "o:", ["outputPath="])
    except getopt.GetoptError:
        return defaultPath

    for opt, arg in opts:
        if opt in ("-o", "--outputPath"):

            if os.path.isdir(str(arg)):
                return str(arg) + "/"

    return defaultPath


def updateProgressBar(done, total):
    barLength, x = os.get_terminal_size()
    barLength = math.floor(barLength / 2)
    block = int(round(barLength * done / total))
    if done < total:
        status = ("Building test " + str(done) + "\r")
    else:
        status = ("Done!" + " " * int(barLength) + "\r")
    text = "\rProgress: [{0}] {1}% {2}".format("#" * block + "-" * (barLength - block), done / total * 100, status)
    sys.stdout.write(text)
    sys.stdout.flush()


# run
if __name__ == '__main__':
    main(sys.argv[1:])