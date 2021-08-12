# EFS
EFS (Event Filing System) format

The Event Filing System (EFS) is a seismic data format, which groups seismograms for common events or times into a single binary file. EFS files also include the file, event and trace header information (metadata).  The format is designed for fast input/output (I/O) operations with efficient access to individual traces. The data format is highly scalable and in principle can store traces for an arbitrarily large number of stations. 

The core EFS subroutines are written in C and Fortran 90. We also provide Python and MATLAB codes to work with the EFS files, including subroutines to convert common seismic data formats into EFS files. The Python and MATLAB codes follow the same data structure as defined in the Fortran codes but they can be used independently without the Fortran subroutines. 

# Citation
Fan et al., 2021, Event Filing System (EFS): A binary seismic data format for fast IO on demand on multiple platforms, submitted to SRL

