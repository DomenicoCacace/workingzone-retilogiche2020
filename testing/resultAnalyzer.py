import getopt
import math
import sys
import numpy as np


def main(argv):
    (inputFile, outputFile, failedFile) = parseCmdLineArgs(argv)
    totalTests = 0
    totalPassed = 0
    timings = [[] for _ in range(6)]
    asyncResetClocks = []

    testDesc = ["First start signal, address in a WZ",
                "Second start signal, address in a WZ",
                "Asynchronous reset, address in a WZ",
                "First start signal, address in no WZ",
                "Second start signal, address in no WZ",
                "Asynchronous reset, address in no WZ"]

    try:
        results = open(outputFile, "w")
        failed = open(failedFile, "w")
        with open(str(inputFile)) as fileobject:

            for testOutcome in fileobject:
                parsedLine = readline(testOutcome)

                if parsedLine[0] != "TOTAL TIME":
                    totalTests += 1
                    if parsedLine[2] == "PASSED":
                        timings[int(parsedLine[1]) - 1].append(float(parsedLine[3]))
                        totalPassed += 1
                    else:
                        failed.write(testOutcome + "\n")
                        continue
                    if parsedLine[4] != "NA":
                        asyncResetClocks.append(int(parsedLine[4]))
                else:
                    results.write("\tGENERAL RESULTS\n")
                    results.write("Total Time: " + str(parsedLine[1]) + "h " + str(parsedLine[2]) +
                                  "m " + str(parsedLine[3]) + "s " + str(parsedLine[4]) + "ms\n")
                    results.write("Total tests run: " + str(totalTests) + "; Success ratio: " + str(
                        totalPassed / totalTests) + "\n")
                    results.write("Tests passed: " + str(totalPassed) + "; Tests Failed: " + str(
                        totalTests - totalPassed) + "\n\n")
                    results.write("\tPER-TYPE RESULTS\n\n")

                    for i in range(6):
                        results.write(str(i+1) + ". " + testDesc[i].upper() + "\n")
                        results.write("Total tests: " + str(totalTests/6) + "; Success ratio: " +
                                      str(np.size(timings[i])/(totalTests/6)) + "\n")
                        results.write("Min time: " + str(np.min(timings[i])) + " μs; \n")
                        results.write("Max time: " + str(np.max(timings[i])) + " μs; \n")
                        results.write("Avg time: " + str(np.average(timings[i])) + " μs; \n")
                        results.write("Std deviation: " + str(round(float(np.std(timings[i])), 5)) + " μs; \n\n")
                    results.write("ASYNCHRONOUS RESET SIGNAL: CYCLES BETWEEN START AND RESET\n\n")
                    results.write("Min time: " + str(np.min(asyncResetClocks)) + " cycles (" + str(
                        np.min(asyncResetClocks) * 100) + " ns);\n")
                    results.write("Max time: " + str(np.max(asyncResetClocks)) + " cycles (" + str(
                        np.max(asyncResetClocks) * 100) + " ns);\n")
                    results.write("Avg time: " + str(np.average(asyncResetClocks)) + " cycles (" + str(
                        np.average(asyncResetClocks)*100) + " ns);\n")
                    results.write("Std deviation: " + str(round(float(np.std(asyncResetClocks)), 5)) + " cycles (" + str(
                        round(float(np.std(asyncResetClocks)), 5) * 100) + " ns);\n")
                    fileobject.close()

                    break

    except FileNotFoundError:
        print("An error has occurred. Exiting.")
        fileobject.close()
        results.close()
        sys.exit(1)


def parseCmdLineArgs(argv):
    inputFile = "../OUTCOME.txt"
    outputFile = "../STATS.txt"
    failedFile = "../FAILED.txt"

    try:
        opts, args = getopt.getopt(argv, "hi:o:f:", ["help", "inputFile=", "outputFile=", "failedFile="])
    except getopt.GetoptError:
        sys.exit(2)

    for opt, arg in opts:
        if opt == '-h':
            print("\nWorkingZone Test Analyzer Options\n")
            print("\t-i\t--inputFile\toutput file from Vivado simulation (default: " + inputFile + ")")
            print("\t-o\t--outputFile\trefined data (default: " + outputFile + ")")
            print("\t-f\t--failedFile\tfailed tests (default: " + failedFile + ")")
            sys.exit(0)
        elif opt in ("-i", "--inputFile"):
            outputFile = arg
        elif opt in ("-o", "--outputFile"):
            outputFile = arg
        elif opt in ("-f", "--failedFile"):
            outputFile = arg

    return str(inputFile), str(outputFile), str(failedFile)


def readline(fileline):
    row = [""] * 5
    column = 0
    for char in fileline:
        if char in ('.', ')', '(', ';', '\n', ':'):
            column += 1
            continue
        row[column] += char

    return clean(row)


def clean(row):
    if row[0] != "TOTAL TIME":
        row[2] = row[2][1:-1]
        row[3] = float(row[3][:-3]) / 1e6
        row[4] = row[4][1:].replace("no reset", "NA")
        if row[4] != "NA":
            row[4] = row[4].replace(" CLKs", "")
    else:
        # converting time from ps to hh:mm:ss:ms
        row[4] = float(row[1][:-3]) / 1e9
        row[1] = math.floor(row[4] / (1000 * 60 * 60))
        row[2] = math.floor((row[4] / (1000 * 60)) - (row[1] * 60))
        row[3] = math.floor((row[4] / 1000) - (row[1] * 60 * 60) - (row[2] * 60))
        row[4] = row[4] - (row[3] * 1000) - (row[2] * 1000 * 60) - (row[1] * 1000 * 60 * 60)

    return row


if __name__ == '__main__':
    main(sys.argv[1:])
