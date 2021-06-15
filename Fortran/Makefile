OBJS2 = ./disk.o	\
        ./swapsubs.o \
        ./efs_subs.o
		      			 
testefs: Makefile testefs.f90 $(OBJS2)
	 gfortran $(OBJS2) testefs.f90 -o testefs
	 
copyefs: Makefile copyefs.f90 $(OBJS2)
	 gfortran $(OBJS2) copyefs.f90 -o copyefs	 
	 
listefs: Makefile listefs.f90 $(OBJS2)
	gfortran $(OBJS2) listefs.f90 -o listefs
			 	 	 
