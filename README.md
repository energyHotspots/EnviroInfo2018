# Code-level Energy Hotspot Localization via Naive Spectrum Based Testing, replication Package (EnviroInfo 2018)

This repository is a companion page for the paper _"Code-level Energy Hotspot Localization via Naive Spectrum Based Testing"_ submitted to [EnviroInfo 2018](http://www.enviroinfo2018.eu/).

It contains all the material required to replicate our experiment, including (i) the software artifacts utilized as subjects (ii) the scripts utilized for data processing and statistical analysis, and (iii) the entirety of the raw and processed data gathered for the experiment.


Content
---------------
The entirety of the experiment data required for the replication and analysis of the experiment are provided in three separate folders, namely:

* [analysis_scripts](https://github.com/energyHotspots/EnviroInfo2018/tree/master/analysis%20script) - Script utilized for data processing and analysis.
* [results](https://github.com/energyHotspots/EnviroInfo2018/tree/master/results) - Raw and processed results of the experiment
* [software_artifact_(grep_v3)](https://github.com/energyHotspots/EnviroInfo2018/tree/master/software_artifact_(grep_v3)) - Software artifacts adopted for the experiment.


For furtehr information on the content of the folder see the following Directory Structure Overview.

Directory Structure Overview
---------------
This reposisory is structured as follows:

    EnviroInfo2018
     .
     |     
     |--- analysis_script/                  Analysis scirpt and formatted input data
     |      |
     |      |--- grep_analysis.r            Analysis script utilize to process and analyze the experiment data
     |      |
     |      |--- environment.RData          Analysis script utilize to process and analyze the experiment data 
     |
     |
     |--- results/                          Totaliti of the results gathered in form of raw and processed data
     |      |
     |      |--- graphs/                    Graphs generated from the data analysis processes
     |      |
     |      |--- measurement_baseline/      Raw data of the experiment baseline measurements
     |      |
     |      |--- measurement_grep/          Raw data of the experiment subject measurements
     |      |
     |      |--- energyResults_*.csv        Processed data per line, function, and branch coverage
     |      |
     |      |--- number_of_calls_*.csv      Number of calls per line, function, and branch
     |
     |
     |--- software_artifact_(grep_v3)/      Source code of the subject and related artifacts 
            |
            |
            |--- coverage/                  Coverage information of the utilized test suite
            |
            |--- source_code/               Source code of the experimental subject (grep v3)
            |
            |--- source_code_coverage/      Source code instrumented for test cases coverage information storage
            |
            |--- inputs/                    Input files required by test cases
            |
            |--- grep-test-suite.txt        Test suite utilized for the experiment
     
  
