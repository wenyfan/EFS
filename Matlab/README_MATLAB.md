# MATLAB codes to use EFS files (EFSmat)

This set of codes can read in and save files in the EFS format.

## Citation
If you make use of this code in published work, please cite Fan *et al.* (2021).    

## Installation
The files are in Matlab script format and are ready for use in any operating system.
### irisFetch.m 
irisFetch allows seamless access to data stored within the IRIS-DMC via FDSN services. It can be downloaded from https://ds.iris.edu/ds/nodes/dmc/software/downloads/irisfetch.m/

## Bugs
Please report bugs, feature requests, and questions to wenyuanfan@ucsd.edu

## Description
### scratch_test.m
An example toy code to call EFSmat functions to work with the EFS format.

### load_efs.m
A Matlab function to read in an EFS file as a nested Matlab structure.

### write_structure2efs.m
A Matlab function to write a nested Matlab structure into an EFS file.

### write_iris2efs.m
A Matlab function to write a Matlab structure as defined in irisFetch.m into a EFS file.