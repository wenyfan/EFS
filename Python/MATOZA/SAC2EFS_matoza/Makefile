FC = gfortran
FFLAG = -fno-backslash

FFLAGS=-I/Users/rmatoza/bin/sac/include/ -O3
SACLIB=/Users/rmatoza/bin/sac/lib/libsac.a
SACIO=/Users/rmatoza/bin/sac/lib/libsacio.a
LDLIBS+=$(SACIO)

OBJS1=  ../../../PROG/SHEARER_SUBS/sphere_subs.o
OBJS2= ../../../PROG/SHEARER_SUBS/datetime.o

EFS = ../../../PROG/EFS/efs_subs.f90 ../../../PROG/EFS/disk2.o
	
sac2efs_hvoaqms: sac2efs_hvoaqms.f90
	$(FC) $(FFLAG) $(EFS) $(FFLAGS) $(SACLIB) $(SACIO) $(LDLIBS) sac2efs_hvoaqms.f90 $(OBJS1) $(OBJS2) -o sac2efs_hvoaqms
	


