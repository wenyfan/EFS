# Python codes to use EFS files (EFSpy)

This set of codes can read in and save files in the EFS format.

## Citation
If you make use of this code in published work, please cite Fan *et al.* (2021).    

## Installation
The files are in Python script format and are ready for use in any operating system.
### ObsPy
ObsPy is called in the set of codes for certain parts of data processing.
https://docs.obspy.org/

## Bugs
Please report bugs, feature requests, and questions to wenyuanfan@ucsd.edu

## Description
### EFSpy_module.py
Module file for EFSpy. It contains functions for reading/writing EFS files and functions to convert EFS structures from ObsPy streams and convert ObsPy streams to EFS structures.

### P0_download_miniSEED_example_CI.py
An example python script to download seismic data.

### P1_miniSEED2EFS_example.py
An example python script to read in miniSEED data and write (and read) the data as an EFS file.