EFS (Event Filing System)

This is a binary format designed for the storage and retrieval of seismograms,
which stores multiple records for an event (e.g., earthquake or explosion)
in a single file.  It is written in Fortran 90 but performs the basic I/O operations
in C by calling routines from disk.c, which must be compiled separately.

To compile the routines, enter:

./subs.bld

which will perform:

gcc -c disk.c -o disk.o                      (assuming gcc compiler)
gcc -c swapsubs.c -o swapsubs.o 
gfortran -c efs_subs.f90 -o efs_subs.o       (assuming gfortran compiler)


The following example F90 programs are also provided

testefs.f90 -- creates new EFS file, closes it, then opens it and read from it.
copyefs.f90 -- copies EFS file.
listefs.f90 -- lists EFS header information.

These programs can be compiled using the Makefile, i.e.,

make testefs
make copyefs
make listefs


The header formats take advantage of the 'type' construct in Fortran90, which
provides something similar to structures in C.  These structures are defined
in a module at the beginning of the efs_subs.f90 source code.  Thus the first 
line of any program that uses these routines should be:

   use EFS_MODULE	 

Note that in the Makefile, testefs.f90 is after efs_subs.o in the gfortran line. 
This is necessary so that the compiler can make sense of this line.

WARNING:  It seems that the efs_subs.o file must be actually compiled in the same directory
as the main program that uses its modules.  Simply copying the efs_subs.o file into
the directory is not enough.  This does not seem right, but for now that is how
I have gotten things to work.  

Written January, 2010 by Peter Shearer (pshearer@ucsd.edu)

---------------------------------------------------------------------------------

EFS file structure


Each file will consist of a file header (fhead), an event header (ehead), 
followed by a byte position array (bytepos) that gives the byte locations 
of the time series, a time series header (tshead), a time series (ts), a 
time series header, a time series, etc.

fhead
ehead   
bytepos
tshead1
ts1
tshead2
ts2
tshead3
ts3
.
.
.
etc.

(1) The fhead format is:

bytetype -- flag for byte swapped data (i*4), should equal 1
eheadtype -- flag for ehead type (i*4,currently only type 1 is defined)
nbytes_ehead -- number of bytes in ehead (i*4,currently set to 264)
tsheadtype -- flag for tshead type (i*4,currently only type 1 is defined)
nbytes_tshead -- number of bytes in tshead (i*4, currently set to 180)

(2) The ehead contains:
NOTE:  This is not the actual order the bytes are written.  For that, see
'type eheader' in EFS_MODULE in efs_subs.f90

efslabel -- label for file (a40)
datasource -- label for data source (a40)
maxnumts -- maximum number of time series 
           (i*4,defines length of bytepos array)
numts -- number of time series
cuspid -- id number for event (i*4)
qtype -- event type (a4)
qlat -- event latitude (r*4)
qlon -- event longitude (r*4)
qdep -- event depth, km (r*4)
qlocqual -- location quality (a4)
qyr, qmon, qdy, qhr, qmn -- event year,month,day,hour,minute (i*4)
qsc -- event second (r*4)
qmag1 -- quake mag1 (r*4)
qmag1type -- quake mag1 method, e.g. mb, Ms, etc. (a4)
qmag2 -- quake mag2 (r*4)
qmag2type -- quake mag2 method, e.g. mb, Ms, etc. (a4)
qmag3 -- quake mag3 (r*4)
qmag3type -- quake mag3 method, e.g. mb, Ms, etc. (a4)
qmoment -- quake moment (N-m) (r*4)
qmomenttype -- quake moment method (a4)
qstrike -- quake focal mech strike (deg.) (r*4)
qdip -- quake focal mech dip (deg.) (r*4)
qrake - quake focal mech rake (deg.) (r*4)
qfocalqual -- focal mechanism quality (a4)
dummy(1:20) -- 20 4-byte fields reserved for future uses


(3) The bytepos format is:

bytepos(1) -- byte position in file for time series header #1 (i*4)
bytepos(2) -- byte position in file for time series header #2 (i*4)
bytepos(3) -- byte position in file for time series header #3 (i*4)
.
.
.
bytepos(maxnumts) -- byte position in file for time series #maxnumts (i*4)

Note that maxnumts is defined in ehead.  Once set, this cannot be changed 
because it defines the fixed length of the bytepos array as written.  The actual 
number of time series can be less and is given in ehead as numts.  This number
grows as more files are written.



(4) The tshead contains:
NOTE:  This is not the actual order the bytes are written.  For that, see
'type tsheader' in EFS_MODULE in efs_subs.f90

npts -- number of points in time series (i*4)
stname -- station name or code (a8)
chnm -- channel name (a4)
stype -- station type or network id (a4)
loccode -- location code field (a8)
datasource -- data source field (a8)
sensor -- sensor type (a8) 
compazi -- sensor orientation azimuth (deg.) (r*4)
compang -- sensor orientation from vertical (deg.) (r*4)
dva -- sensor type (D=displacement, V=velocity, A=accel) (a4)
gain -- sensor gain (r*4)
units -- units for gain (a8)
f1 -- low frequency limit of any passband filter applied (Hz) (r*4)
f2 -- high frequency limit of any passband applied (Hz) (r*4)
dt -- sample interval, s (r*4)
syr, smon, sdy, shr, smn -- first point year,month,day,hour,minute (i*4)
ssc -- first point seconds (r*4)
tdif -- first sample time minus event time, seconds (r*4)
slat -- station latitude (r*4)
slon -- station longitude (r*4)
selev -- station elevation, km (r*4)s
del -- event-station distance, km (r*4)
sazi -- azimuth (degrees) at station to event (r*4)
qazi -- azimuth (degrees) at event to station (r*4)
pick1 -- pick 1, seconds from first sample (r*4)
pick1q -- pick 1 quality (a4)
pick1name -- pick 1 phase name (a4)
pick2 -- pick 2, seconds from first sample (r*4)
pick2q -- pick 2 quality (a4)
pick2name -- pick 2 phase name (a4) 
pick3 -- pick 3, seconds from first sample (r*4)
pick3q -- pick 3 quality (a4)
pick3name -- pick 3 phase name (a4)
pick4 -- pick 4, seconds from first sample (r*4)
pick4q -- pick 4 quality (a4)
pick4name -- pick 4 phase name (a4)
ppolarity -- P wave polarity, e.g., U or D (a4)
problem -- data problem flag (e.g., clipping, noise spikes, etc. (a4)
dummy(1:20) -- 20 4-byte fields reserved for future use, e.g., poles and zeros



(5) The ts format is just a string of 4-byte binary numbers (i.e., npts points)


------------------------------------------------------------------------------------------

EFS subroutines



EFS_OPEN_NEW(lun,name) creates new EFS file
   Inputs: name -- filename (a100)
   Returns: lun -- unit number (i4)
   
   
EFS_OPEN_OLD(lun,name) opens existing EFS file
   Inputs: name -- filename (a100)
   Returns: lun -- unit number (i4) 


EFS_CLOSE closes EFS file and releases unit number
   Inputs: lun -- unit number (i4)
   
   
EFS_INIT_EHEAD sets event header to default values and user determined max number of times series
   Inputs:  maxnumts -- maximum number of time series (sets size of bytepos array written in file)
   Returns: ehead -- event header (see stucture in EFS_MODULE)
 
   
EFS_TESTINIT_EHEAD sets event header to some arbitary test values and user determined max number of times series
   Inputs:  maxnumts -- maximum number of time series (sets size of bytepos array written in file)
   Returns: ehead -- event header (see stucture in EFS_MODULE)
           

EFS_WRITE_EHEAD writes event header and dummy bytepos array
   Inputs: lun -- unit number (i4)
           ehead -- event header (structure in EFS_MODULE)
	   

EFS_UPDATE_EHEAD updates event header and bytepos array
   Inputs: lun -- unit number (i4)
           ehead -- event header (structure in EFS_MODULE)


EFS READ_EHEAD reads event header and bytepos array
   Inputs: lun -- unit number (i4)
   Returns: ehead -- event header (structure in EFS_MODULE)


EFS LIST_EHEAD lists contents of event header
   Inputs: ehead -- event header (structure in EFS_MODULE)


EFS WRITE_TSHEAD writes time series header
   Inputs: lun -- unit number (i4)           
           tshead -- time series header (structure in EFS_MODULE)
  Returns: its -- time series number (goes up one for each call)


EFS_READ_TSHEAD reads time series header
    Inputs: lun -- unit nubmer (i4)
            its -- time series number (i4)
    Returns: tshead -- time series header (structure in EFS_MODULE)


EFS_INIT_TSHEAD sets time series header (tshead) to default values
   Returns:  tshead (structure in EFS_MODULE)


EFS_TESTINIT_TSHEAD sets time series header (tshead) to some arbitrary values
    Returns: tshead (structure in EFS_MODULE)


EFS_WRITE_TS write times series to EFS file.  This should be done immediately after writing
       time series header using EFS_WRITE_TSHEAD
   Inputs:  lun -- unit number (i4)
            npts -- number of points to write (should match tshead%nputs) (i4)
            x -- array with points (r*4)
	    

EFS_READ_HEADTS reads time series header AND time series
   This does same thing as calling EFS_READ_TSHEAD and then EFS_READTS 
    Inputs:  lun -- unit number (i4)
             its -- time series number (i4)
    Returns: tshead -- time series header (structure in EFS_MODULE)


EFS_READ_TS reads time series
    Inputs:  lun -- unit number (i4)
             its -- time series number (i4)
             npts -- number of points, normally should match tshead%npts (i4)
    Returns: ts -- time series array (r*4)


In principle, the EFS file can contain as many records 
as desired and the records can have arbitrary lengths. In the Fortran package, the default values 
are set as:

maxnpts=100000000          !maximum number of points in time series
max_bytepos_size=10000       !maximum number of time series per file

which can be adjusted if needed.








