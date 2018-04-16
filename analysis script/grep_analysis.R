# Timestamp formats
powerTimestampFormat <- "%d.%m.%y %H:%M:%S"
markersTimestampFormat <- "%Y-%m-%d %H:%M:%OS"

# Testrun no. 491 was not included in the measurements because it caused the grep script to crash.
omittedNumbers <- c(491) # possibly more in other measurements, therefore this vector can be extended

# Read measurement data
markers_raw <- read.table(file = "./2017-12-20_measurement_pc_grep_spectrum-based/Logs/markers.csv", header = F, sep = ";", quote = "", stringsAsFactors = F, fill=T)
power_raw1 <- read.table(file = "./2017-12-20_measurement_pc_grep_spectrum-based/Power Measurement/grep_part1_2017-12-18.csv", header = T, skip = 1, sep = ";", quote = "", dec = ",", stringsAsFactors = F)
power_raw2 <- read.table(file = "./2017-12-20_measurement_pc_grep_spectrum-based/Power Measurement/grep_part2_2017-12-19.csv", header = T, skip = 1, sep = ";", quote = "", dec = ",", stringsAsFactors = F)
power_raw3 <- read.table(file = "./2017-12-20_measurement_pc_grep_spectrum-based/Power Measurement/grep_part3_2017-12-20.csv", header = T, skip = 1, sep = ";", quote = "", dec = ",", stringsAsFactors = F)
power_raw <- rbind(power_raw1, power_raw2, power_raw3)

# Read in the coverage data
coverage_data_functions <- scan("../grep_v3/coverage/grep-function-new-uc", what="", sep="\n")
coverage_data_branches <- scan("../grep_v3/coverage/grep-branch.txt", what="", sep="\n")
coverage_data_lines <- scan("../grep_v3/coverage/grep-line.txt", what="", sep="\n")
# Separate elements by one or more whitepace
coverage_data_functions <- strsplit(coverage_data_functions, "[[:space:]]+")
coverage_data_branches <- strsplit(coverage_data_branches, "[[:space:]]+")
coverage_data_lines <- strsplit(coverage_data_lines, "[[:space:]]+")
# Remove omittedNumbers
coverage_functions <- coverage_data_functions[-omittedNumber]
coverage_branches <- coverage_data_branches[-omittedNumber]
coverage_lines <- coverage_data_lines[-omittedNumber]

# Rename data.frame columns
names(markers_raw) <- c("Timestamp", "Action", "Call")
names(power_raw) <- c("Number", "Timestamp", "AverageValue", "MinValue", "MaxValue")

# Fix timestamps
power_raw$Timestamp <- as.POSIXct(power_raw$Timestamp, format=powerTimestampFormat, tz = "CET")
markers_raw$Timestamp <- as.POSIXct(markers_raw$Timestamp, format=markersTimestampFormat, tz = "CET")

# Remove markers that are not part of the actual measurements
markers <- markers_raw[-(25883:nrow(markers_raw)),]
markers <- markers[-(1:10),]

# Get the startTestrun Markers
startmarkers <- markers[which(markers$Action == "startTestrun"), ]
startmarkers <- startmarkers[with(startmarkers, order(Timestamp)), ]

# Make a list of all the measurements (that start with "startTestrun")
measurement_list <- list()
for (i in 1:(nrow(startmarkers)-1)) {
  element <- length(measurement_list) + 1
  measurement_list[[element]] <- power_raw[which((power_raw$Timestamp >= startmarkers$Timestamp[i]) & (power_raw$Timestamp <= startmarkers$Timestamp[i+1])), ]
  measurement_list[[element]]$second <- measurement_list[[element]]$Timestamp - measurement_list[[element]]$Timestamp[1]
}

# Make a list of all Actions (that start with "startAction"). In case of SIR this is the call (or rather line) in the test-suite file
# therefore: get all the startmarkers
startactions <- markers[which(markers$Action == "startAction"), ]
startactions <- startactions[with(startactions, order(Timestamp)), ]
stopactions <- markers[which(markers$Action == "stopAction"), ]
stopactions <- stopactions[with(stopactions, order(Timestamp)), ]

# and calculate the duration for each action
duration <- stopactions$Timestamp - startactions$Timestamp

# add the call # from the "Call" column
startactions$CallNo <- lapply(strsplit(startactions$Call, " :"), `[[`, 1)

# calculate the mean duration and standard deviation of the duration for each SIR call/action
sumOfAllActionDurations <- rep(0, 808)
sdOfAllActionDurations <- rep(0, 808)
for(i in 1:808){
  sumOfAllActionDurations[i] <- sum(stopactions$Timestamp[which(startactions$CallNo == i)] - startactions$Timestamp[which(startactions$CallNo == i)])
}
for(i in 1:808){
  sdOfAllActionDurations[i] <- sd(stopactions$Timestamp[which(startactions$CallNo == i)] - startactions$Timestamp[which(startactions$CallNo == i)])
}
meanOfAllActionDurations <- sumOfAllActionDurations / 16

# mean runtime of all calls:
mean(meanOfAllActionDurations) # approx. 11.37999 seconds

# make a list of all actions (i. e. SIR calls)
actions_list <- list()
for (callNumber in 1:808) {
  cat("Creating table ", callNumber, "\n", sep="")
  actions_list_element <- length(actions_list) + 1
  allStartmarkersForCurrentCallNumer <- startactions[which(startactions$CallNo == callNumber),]
  allStopmarkersForCurrentCallNumber <- stopactions[which(startactions$CallNo == callNumber),]
  measurementNumber <- 1
  powerOfCurrentMeasurement <- power_raw[which((power_raw$Timestamp >= allStartmarkersForCurrentCallNumer$Timestamp[measurementNumber]) & (power_raw$Timestamp <= allStopmarkersForCurrentCallNumber$Timestamp[measurementNumber])), ]
  powerOfCurrentMeasurement$second <- powerOfCurrentMeasurement$Timestamp - powerOfCurrentMeasurement$Timestamp[1]
  for (measurementNumber in 2:16){
    newRows <- power_raw[which((power_raw$Timestamp >= allStartmarkersForCurrentCallNumer$Timestamp[measurementNumber]) & (power_raw$Timestamp <= allStopmarkersForCurrentCallNumber$Timestamp[measurementNumber])), ]
    newRows$second <- newRows$Timestamp - newRows$Timestamp[1]
    powerOfCurrentMeasurement <- rbind(powerOfCurrentMeasurement, newRows)
  }
  actions_list[[actions_list_element]] <- powerOfCurrentMeasurement
}

# calculate the average power consumption (and standard deviation of the power consumption) of each action (i. e. SIR call)
meanpowers <- rep(0, 808)
sdpower <- rep(0, 808)
for(i in 1:808){
  meanpowers[i] <- mean(actions_list[[i]]$AverageValue)
  sdpower[i] <- sd(actions_list[[i]]$AverageValue)
}

# As there are 16 measurements, the average power needs to be divided by 16, resulting the average power of 5000 (real) calls performed during each action in Watts (i. e. because the measurement script ran each call 5000 times to achieve a reasonable runtime (of approx. 11.37999 seconds)).
# If we then further divide the result by 5, we receive the average power consumption of each call in milliwatts.
# another way to calculate it would be
#   meanPowerInWattsOf5000Calls/5000 = meanPowerInWattsOf1Call
#   meanPowerInWattsOf1Call * 1000 = meanPowerInMilliwattsOf1Call
# But this is shorter:
meanPowerInMilliwattsPerSingleCall <- meanpowers/16/5

# calculate the energy from the wattage in Milliwattseconds [mWs]
energyPerSingleCall <- meanPowerInMilliwattsPerSingleCall * meanOfAllActionDurations

# Distribute energy consumption over coverage information:
# setup all necessary variables
# Functions
maximum_function_coverage_numer <- max(as.numeric(names(table(unlist(coverage_functions)))))
energyDistributionVector_functions <- rep(0, maximum_function_coverage_numer)
numberOfFunctionCallsVecor <- rep(0, maximum_function_coverage_numer)
names(energyDistributionVector_functions) <- seq(1:maximum_function_coverage_numer)
names(numberOfFunctionCallsVecor) <- seq(1:maximum_function_coverage_numer)
# Branches
branch_coverage_numer_names <- unique(names(table(unlist(coverage_branches))))
energyDistributionVector_branches <- rep(0, length(branch_coverage_numer_names))
numberOfBranchCallsVecor <- rep(0, length(branch_coverage_numer_names))
names(energyDistributionVector_branches) <- branch_coverage_numer_names
names(numberOfBranchCallsVecor) <- branch_coverage_numer_names
# Lines
maximum_line_coverage_numer <- max(as.numeric(names(table(unlist(coverage_lines)))))
energyDistributionVector_lines <- rep(0, maximum_line_coverage_numer)
numberOfLineCallsVecor <- rep(0, maximum_line_coverage_numer)
names(energyDistributionVector_lines) <- seq(1:maximum_line_coverage_numer)
names(numberOfLineCallsVecor) <- seq(1:maximum_line_coverage_numer)

# Run over each measurement and distribute the measured power to each of the covered units (functions, lines, branches) 
# Also: Count how many times each unit was covered.
# Functions
for(callNumber in 1:length(meanOfAllActionDurations)){
  energyConsumptionOfCall <- energyPerSingleCall[callNumber]
  coverageInformationOfCall <- unlist(coverage_functions[callNumber])
  numberOfItemsInCall <- length(coverageInformationOfCall)
  energyDistributionVector_functions[coverageInformationOfCall] <- energyDistributionVector_functions[coverageInformationOfCall] + (energyConsumptionOfCall/numberOfItemsInCall)
  numberOfFunctionCallsVecor[coverageInformationOfCall] <- numberOfFunctionCallsVecor[coverageInformationOfCall] + 1
}
# divide the energyDistributionVector_functions by the number of calls to get the average
resultVector_functions <- energyDistributionVector_functions/numberOfFunctionCallsVecor
# Branches
for(callNumber in 1:length(meanOfAllActionDurations)){
  energyConsumptionOfCall <- energyPerSingleCall[callNumber]
  coverageInformationOfCall <- unlist(coverage_branches[callNumber])
  numberOfItemsInCall <- length(coverageInformationOfCall)
  energyDistributionVector_branches[coverageInformationOfCall] <- energyDistributionVector_branches[coverageInformationOfCall] + (energyConsumptionOfCall/numberOfItemsInCall)
  numberOfBranchCallsVecor[coverageInformationOfCall] <- numberOfBranchCallsVecor[coverageInformationOfCall] + 1
}
# divide the energyDistributionVector_branches by the number of calls to get the average
resultVector_branches <- energyDistributionVector_branches/numberOfBranchCallsVecor
# Lines
for(callNumber in 1:length(meanOfAllActionDurations)){
  energyConsumptionOfCall <- energyPerSingleCall[callNumber]
  coverageInformationOfCall <- unlist(coverage_lines[callNumber])
  numberOfItemsInCall <- length(coverageInformationOfCall)
  energyDistributionVector_lines[coverageInformationOfCall] <- energyDistributionVector_lines[coverageInformationOfCall] + (energyConsumptionOfCall/numberOfItemsInCall)
  numberOfLineCallsVecor[coverageInformationOfCall] <- numberOfLineCallsVecor[coverageInformationOfCall] + 1
}
# divide the energyDistributionVector_lines by the number of calls to get the average
resultVector_lines <- energyDistributionVector_lines/numberOfLineCallsVecor
# there are lines that are never called. Thus, all generated NaN must be replaced with 0 energy consumption.
resultVector_lines[which(numberOfLineCallsVecor == 0)] <- 0

#PLOTS:
#1 just plot the power consumption over the whole measurement period
plot(power_raw$Timestamp, power_raw$AverageValue, type = "S", main = "Whole measurement", xlab = "Timestamp", ylab = "Electrical power [W]")

#2 plot all 16 testruns and the mean value per second
plot(as.numeric(measurement_list[[10]]$AverageValue), type = "S", col="dimgray", main = "All 16 Testruns", xlab = "Time [s]", ylab = "Electrical power [W]", ylim=c(62, 66))
for(i in c(1:length(measurement_list))[-10]){
  points(as.numeric(measurement_list[[i]]$AverageValue), type = "S", col="dimgray")
}
sumOfAllMeasurementValues <- rep(0, nrow(measurement_list[[1]]))
for(i in 1:length(measurement_list)){
  sumOfAllMeasurementValues <- sumOfAllMeasurementValues + as.numeric(measurement_list[[i]]$AverageValue)[1:nrow(measurement_list[[1]])]
}
meanOfAllMeasurementValues <- sumOfAllMeasurementValues / length(measurement_list)
points(meanOfAllMeasurementValues[1:nrow(measurement_list[[1]])], type = "S", col="red", lwd=2)

#3 plot the duration of each action
boxplot(as.numeric(durations), ylab= "Duration of each action [s]")
#4 plot the mean duration of each of the 808 calls
plot(meanOfAllActionDurations, ylab= "Mean duration [s]", type = "h", main = "Mean duration of each of the 808 calls", xlab = "call #")
boxplot(meanOfAllActionDurations, ylab= "Mean duration of each of the 808 calls [s]")
#5 plot the standard deviation of the duration of each of the 808 calls
plot(sdOfAllActionDurations, ylab= "Standard deviation of the duration [s]", type = "h", main = "Standard deviation of the duration of each of the 808 calls", xlab = "call #")
boxplot(sdOfAllActionDurations, ylab= "Standard deviation of the duration of each of the 808 calls [s]")

#6 plot the mean power consumption of each call
plot(meanPowerInMilliwattsPerSingleCall, main="Mean power consumption of each call", xlab="call #", ylab = "Mean power [mW]", type="h")
library(vioplot)
vioplot(meanPowerInMilliwattsPerSingleCall, horizontal = T, col = "green", names="")
title(main="Mean power consumption of each call", xlab="Mean power [mW]", ylab = "")

#7 plot the mean power consumption vs. mean duration of each call
plot(x=meanPowerInMilliwattsPerSingleCall, y=meanOfAllActionDurations, main="Mean power consumption vs. mean duration of each call", xlab="Mean power [mW]", ylab = "Mean duration [s]")

# RESULTS
#   Functions
#8 plot the average energy consumption per covered function, sorted in ascending order
plot(sort(resultVector_functions), type="h", main = "Average energy consumption per covered function", xlab = "sorted in ascending order", ylab = "Average energy [mWs]", xaxt="n")
vioplot(resultVector_functions, horizontal = T, col = "green", names="")
title(main="Average energy consumption per covered function", xlab="Average energy [mWs]", ylab = "")

#9 plot the average energy consumption vs the number of calls for each function
plot(numberOfFunctionCallsVecor, resultVector_functions, main="Number of function calls vs. energy consumed by this function", xlab="Number of (UNIQUE!) calls", ylab = "Energy consumption [mWs]")
#9a Boxplot of the same as in #8
boxplot(resultVector_functions, main = "Average energy consumption per covered function", ylab = "Average energy [mWs]", xaxt="n", horizontal = T, notch=TRUE)
vioplot(resultVector_functions, col="green", names="", horizontal = T); title("Average energy consumption per covered function", ylab="Average energy [mWs]"); 

#10 "Heatmap" or rather levelplot of the energy consumption per function
# Necessary packages:
# install.packages("rasterVis"); install.packages("lattice"); install.packages("latticeExtra")
library(rasterVis)
library(lattice)
library(latticeExtra)
resultVector_functions[108] <- mean(resultVector_functions) 
resultVector_functions_safe <- resultVector_functions

plotData <- data.frame(expand.grid(x=1:9, y=1:12), value = resultVector_functions, source = names(resultVector_functions))
theme <- BuRdTheme()
theme$fontsize$text <- 10
colfunc <- colorRampPalette(c("white","red"))
theme$regions$col <- colfunc(100)
labs <- as.character(plotData$source)
labs[3] <- "at_begline_\nloc_p"
labs[4] <- "at_endline_\nloc_p"
labs[81] <- "prepend_default_\noptions"
labs[86] <- "re_compile_\npattern"

Obj <- 
  levelplot(value ~ x+y, data = plotData, xlab = "", ylab = "", main = "Energy consumption per function", par.settings=theme) + 
  xyplot(y ~ x, data = plotData, panel = function(y, x, ...) {
    ltext(x = x, y = y, labels = labs, cex = 1, font = 2)
  })
print(Obj)

resultVector_functions <- resultVector_functions_safe

write.table(resultVector_functions, file = "energyResults.csv", quote = F, sep = ";")
write.table(numberOfFunctionCallsVecor, file = "number of calls.csv", quote = F, sep = ";")

#   Branches
#11 plot the average energy consumption per covered branch, sorted in ascending order
plot(sort(resultVector_branches), type="h", main = "Average energy consumption per covered branch", xlab = "sorted in ascending order", ylab = "Average energy [mWs]", xaxt="n")
#12 plot the average energy consumption vs the number of calls for each branch
plot(numberOfBranchCallsVecor, resultVector_branches, main="Number of branch calls vs. energy consumed by this branch", xlab="Number of (UNIQUE!) calls", ylab = "Energy consumption [mWs]")

#13 "Heatmap" or rather levelplot of the energy consumption per branch
# Necessary packages:
# install.packages("rasterVis"); install.packages("lattice"); install.packages("latticeExtra")
library(rasterVis)
library(lattice)
library(latticeExtra)
resultVector_branches[1802] <- mean(resultVector_branches) # Fill the last remaining tile with the average of the energy consumption (there are 1801 branches which is a prime -.-)
plotData<-data.frame(expand.grid(x=1:53, y=1:34), value = resultVector_branches, source = names(resultVector_branches))
Obj <- 
  levelplot(value ~ x+y, data = plotData, xlab = "", ylab = "", main = "Energy consumption per branch", par.settings=BuRdTheme())# + 
  #xyplot(y ~ x, data = plotData, panel = function(y, x, ...) {
  #  ltext(x = x, y = y, labels = plotData$source, cex = 1, font = 2)
  #})
print(Obj)

write.table(resultVector_branches[1:1801], file = "energyResults_branches.csv", quote = F, sep = ";")
write.table(numberOfBranchCallsVecor, file = "number of calls_branches.csv", quote = F, sep = ";")

#   Lines
resultVector_lines_wo_zero <- resultVector_lines[which(resultVector_lines != 0)] # For clarity remove all lines which are never called.
#14 plot the average energy consumption per covered line, sorted in ascending order
plot(sort(resultVector_lines), type="h", main = "Average energy consumption per covered line", xlab = "sorted in ascending order", ylab = "Average energy [mWs]", xaxt="n")
#15 same, but without the 0s
plot(sort(resultVector_lines_wo_zero), type="h", main = "Average energy consumption per covered line", xlab = "sorted in ascending order", ylab = "Average energy [mWs]", xaxt="n")
#16 plot the average energy consumption vs the number of calls for each line
plot(numberOfLineCallsVecor, resultVector_lines, main="Number of lines calls vs. energy consumed by this line", xlab="Number of (UNIQUE!) calls", ylab = "Energy consumption [mWs]")
#17 same, but without the 0s
plot(numberOfLineCallsVecor[which(numberOfLineCallsVecor != 0)], resultVector_lines_wo_zero, main="Number of lines calls vs. energy consumed by this line", xlab="Number of (UNIQUE!) calls", ylab = "Energy consumption [mWs]")

#18 "Heatmap" or rather levelplot of the energy consumption per line
# Necessary packages:
# install.packages("rasterVis"); install.packages("lattice"); install.packages("latticeExtra")
library(rasterVis)
library(lattice)
library(latticeExtra)
plotData<-data.frame(expand.grid(x=1:186, y=1:71), value = resultVector_lines, source = names(resultVector_lines))
Obj <- 
  levelplot(value ~ x+y, data = plotData, xlab = "", ylab = "", main = "Energy consumption per line", par.settings=BuRdTheme())# + 
#  xyplot(y ~ x, data = plotData, panel = function(y, x, ...) {
#  ltext(x = x, y = y, labels = plotData$source, cex = 1, font = 2)
#})
print(Obj)
#19 same, but removed zeros 
resultVector_lines_wo_zero[2192:2196] <- mean(resultVector_lines_wo_zero) # Fill the last remaining tiles with the average of the energy consumption (there are 2191 lines which are really called)
plotData<-data.frame(expand.grid(x=1:61, y=1:36), value = resultVector_lines_wo_zero, source = names(resultVector_lines_wo_zero))
Obj <- 
  levelplot(value ~ x+y, data = plotData, xlab = "", ylab = "", main = "Energy consumption per line", par.settings=BuRdTheme()) #+ 
  #xyplot(y ~ x, data = plotData, panel = function(y, x, ...) {
  #ltext(x = x, y = y, labels = plotData$source, cex = 1, font = 2)
#})
print(Obj)

write.table(resultVector_lines, file = "energyResults_lines.csv", quote = F, sep = ";")
write.table(numberOfLineCallsVecor, file = "number of calls_lines.csv", quote = F, sep = ";")
