
module EFS_MODULE
   implicit none
   
   integer, parameter :: max_bytepos_size=10000       !maximum number of time series per file
   integer, parameter :: max_unitnum=100              !maximum allowed Fortran io unit number                 
   integer, dimension(max_bytepos_size,max_unitnum) :: bytepos
   integer :: nbyte_fhead=20   
   integer :: eheadtype=1, nbyte_ehead=264, tsheadtype=1, nbyte_tshead=268
   integer, dimension(max_unitnum) :: bytepos_size, its_written, lastbyte, numts_total, bytetype
   
   type fheader
      integer :: bytetype, eheadtype, nbyte_ehead, tsheadtype, nbyte_tshead   
   end type fheader
      
   type eheader
      character (len=40) :: efslabel, datasource   
      integer :: maxnumts, numts, cuspid 
      character (len=4) :: qtype,qmag1type,qmag2type,qmag3type,qmomenttype,qlocqual,qfocalqual 
      real :: qlat,qlon,qdep,qsc,qmag1,qmag2,qmag3,qmoment,qstrike,qdip,qrake      
      integer :: qyr,qmon,qdy,qhr,qmn      
      integer, dimension(20) :: dummy             !for future expansion       
   end type eheader
   
   type tsheader
      character (len=8) :: stname,loccode,datasource,sensor,units
      character (len=4) :: chnm,stype,dva, &
                           pick1q,pick2q,pick3q,pick4q,&
                           pick1name,pick2name,pick3name,pick4name, &
                           ppolarity,problem 
      integer :: npts,syr,smon,sdy,shr,smn
      real :: compazi,compang,gain,f1,f2,dt,ssc,tdif,slat,slon,selev,del,sazi,qazi, &
              pick1,pick2,pick3,pick4
      integer, dimension(20) :: dummy      
   end type tsheader 
      
end module EFS_MODULE

 

!EFS_OPEN_NEW creates and opens new EFS file
!   Inputs: name -- filename (a100)
!   Returns: lun -- unit number (i4)
!
subroutine EFS_OPEN_NEW(lun,name)
   use EFS_MODULE
   implicit none
   integer :: lun, mode, istat, nbyte  
   character (len = 100) :: name
   type(fheader) :: fhead  
   mode = 3                                     !to create file
   call GGETFIL(mode, lun, name, istat)         !creates and opens file, assigns lun as file number
   if (istat /= 0) then
      print *,'**Error in EFS_OPEN_NEW, istat = ',istat
      stop
   else if (lun < 1 .or. lun > max_unitnum) then
      print *,'**Error in EFS_OPEN_NEW, lun = ', lun
      stop
   endif
    
   fhead%bytetype = 1
   fhead%eheadtype = eheadtype
   fhead%nbyte_ehead = nbyte_ehead
   fhead%tsheadtype = tsheadtype
   fhead%nbyte_tshead = nbyte_tshead
   
   nbyte = nbyte_fhead
   call GWRDISCB(lun, fhead, nbyte, istat)    
   if (istat /= nbyte) then
      print *,'**Error2 in EFS_OPEN_NEW, istat,nbyte = ',istat,nbyte
      stop
   endif

   bytetype(lun) = 1
   its_written(lun) = 0
   lastbyte(lun) = nbyte_fhead
   
end subroutine EFS_OPEN_NEW




!EFS_OPEN_OLD opens existing EFS file
!   Inputs: name -- filename (a100)
!   Returns: lun -- unit number (i4)
!
subroutine EFS_OPEN_OLD(lun,name)
   use EFS_MODULE
   implicit none
   integer :: lun, mode, istat, nbyte, swapint
   character (len = 100) :: name
   type(fheader) :: fhead   
   mode = 4                                     !to open existing file
   call GGETFIL(mode, lun, name, istat)         !opens file, assigns lun as file number
   if (istat /= 0) then
      print *,'**Error in EFS_OPEN_OLD, istat = ',istat
      lun = -9
      return 
   else if (lun < 1 .or. lun > max_unitnum) then
      print *,'**Error in EFS_OPEN_OLD, lun = ', lun
      lun = -9
      return
   endif
   
   nbyte = nbyte_fhead 
   call GRDDISCB(lun, fhead, nbyte, istat)
   if (istat /= nbyte) then
      print *,'**Error1 in EFS_OPEN_OLD, istat,nbyte = ',istat,nbyte
      lun = -9
      return
   endif
   
   bytetype(lun) = fhead%bytetype
   
   if (bytetype(lun) /= 1) then
      print *,'**WARNING:  likely byteswapped file, bytetype = ', bytetype(lun)
      print *,'            will try to convert on the fly'
      istat = SWAPINT(fhead%eheadtype)
      istat = SWAPINT(fhead%nbyte_ehead)
      istat = SWAPINT(fhead%tsheadtype)
      istat = SWAPINT(fhead%nbyte_tshead)
   endif
   
   if (fhead%eheadtype /= eheadtype .or. &
            fhead%nbyte_ehead /= nbyte_ehead .or. &
            fhead%tsheadtype /= tsheadtype .or. &
            fhead%nbyte_tshead /= nbyte_tshead) then
      print *,'**ERROR: Mismatch in ehead or tshead type or length'
      print *,fhead%eheadtype,fhead%nbyte_ehead,fhead%tsheadtype,fhead%nbyte_tshead
      print *,eheadtype,nbyte_ehead,tsheadtype,nbyte_tshead
      lun = -9
      return
   endif
            
   lastbyte(lun) = nbyte_fhead
      
end subroutine EFS_OPEN_OLD



! EFS_CLOSE closes EFS file and releases unit number
!    Inputs: lun -- unit number (i4)
!
subroutine EFS_CLOSE(lun)
   implicit none
   integer :: lun
   call GFREFIL(lun)
end subroutine EFS_CLOSE


! EFS_INIT_EHEAD sets event header to default values and user determined max number of times series
!    Inputs:  maxnumts -- maximum number of time series (sets size of bytepos array written in file)
!    Returns: ehead -- event header (see stucture in EFS_MODULE)
!
subroutine EFS_INIT_EHEAD(maxnumts, ehead)
   use EFS_MODULE 
   implicit none
   integer :: i, maxnumts
   type(eheader) :: ehead
   
   ehead%efslabel = ' '
   ehead%datasource = ' '
   ehead%maxnumts = maxnumts
   ehead%numts = 0
   ehead%cuspid = 0
   ehead%qtype = ' '
   ehead%qlat = 0.0
   ehead%qlon = 0.0
   ehead%qdep = 0.0
   ehead%qlocqual = ' '
   ehead%qyr = 0
   ehead%qmon = 0
   ehead%qdy = 0
   ehead%qhr = 0
   ehead%qmn = 0
   ehead%qsc = 0.0
   ehead%qmag1 = 0.0
   ehead%qmag2 = 0.0
   ehead%qmag3 = 0.0
   ehead%qmoment = 0.0
   ehead%qmag1type = ' '
   ehead%qmag2type = ' '      
   ehead%qmag3type = ' '
   ehead%qmomenttype = ' '
   ehead%qstrike = -99.
   ehead%qdip = -99.
   ehead%qrake = -99.
   ehead%qfocalqual = ' '
   do i = 1, 20         
      ehead%dummy(i) = 0
   enddo
   
end subroutine EFS_INIT_EHEAD


! EFS_TESTINIT_EHEAD sets event header to some arbitary test values and user determined max number of times series
!    Inputs:  maxnumts -- maximum number of time series (sets size of bytepos array written in file)
!    Returns: ehead -- event header (see stucture in EFS_MODULE)
!
subroutine EFS_TESTINIT_EHEAD(maxnumts, ehead)
   use EFS_MODULE 
   implicit none
   integer :: i, maxnumts
   type(eheader) :: ehead
   
   ehead%efslabel = 'efslabel example'
   ehead%datasource = 'datasource example'
   ehead%maxnumts = maxnumts     
   ehead%numts = 0
   ehead%cuspid = 12345678
   ehead%qtype = 'q'
   ehead%qlat = 33.3
   ehead%qlon = -120.3
   ehead%qdep = 8.8
   ehead%qlocqual = 'A'
   ehead%qyr = 2001
   ehead%qmon = 3
   ehead%qdy = 13
   ehead%qhr = 20
   ehead%qmn = 23
   ehead%qsc = 43.14
   ehead%qmag1 = 5.5
   ehead%qmag2 = 5.8
   ehead%qmag3 = 5.9
   ehead%qmoment = 2.3e19
   ehead%qmag1type = 'mb'
   ehead%qmag2type = 'Ms'      
   ehead%qmag3type = 'Mw'
   ehead%qmomenttype = 'momt'
   ehead%qstrike = 47.
   ehead%qdip = 57.
   ehead%qrake = 67.
   ehead%qfocalqual = 'B'   
   do i = 1, 20         
      ehead%dummy(i) = 0
   enddo      
   
end subroutine EFS_TESTINIT_EHEAD



! EFS_WRITE_EHEAD writes event header and dummy bytepos array
!   Inputs: lun -- unit number (i4)
!           ehead -- event header (structure in EFS_MODULE)
!
subroutine EFS_WRITE_EHEAD(lun,ehead)
   use EFS_MODULE
   implicit none
   
   integer :: lun, nbyte, istat, i
 
   type(eheader) :: ehead   

   nbyte = nbyte_ehead
   call GWRDISCB(lun, ehead, nbyte, istat)
   if (istat /= nbyte) then
      print *,'**Error1 in EFS_WRITE_EHEAD, istat,nbyte = ',istat,nbyte
      stop
   endif

   if (lastbyte(lun) > 2147483647 - nbyte) then
      print *, '***Error: EFS file nbytes > 2147483647'
      stop
   endif

   lastbyte(lun) = lastbyte(lun) + nbyte

   
   bytepos_size(lun) = ehead%maxnumts
   
   do i = 1, bytepos_size(lun)
      bytepos(i,lun) = 0                  !to be updated when ts headers are written
   enddo
   
   nbyte = 4 * bytepos_size(lun) 
   call GWRDISCB(lun, bytepos(1,lun), nbyte, istat)    
   if (istat /= nbyte) then
      print *,'**Error2 in EFS_WRITE_EHEAD, istat,nbyte = ',istat,nbyte
      stop
   endif

   if (lastbyte(lun) > 2147483647 - nbyte) then
      print *, '***Error: EFS file nbytes > 2147483647'
      stop
   endif

   lastbyte(lun) = lastbyte(lun) + nbyte 
   
end subroutine EFS_WRITE_EHEAD



! EFS_UPDATE_EHEAD updates event header and bytepos array
!   Inputs: lun -- unit number (i4)
!           ehead -- event header (structure in EFS_MODULE)
!
subroutine EFS_UPDATE_EHEAD(lun, ehead)
   use EFS_MODULE
   implicit none  

   type(eheader) :: ehead   
   
   integer :: lun, nbyte, position, istat
   
   ehead%numts = its_written(lun)
   
   position = nbyte_fhead
   call GPODISCB(lun, position)                   !move to beginning of ehead 
      
   nbyte = nbyte_ehead
   call GWRDISCB(lun, ehead, nbyte, istat)
   if (istat /= nbyte) then
      print *,'**Error1 in EFS_UPDATE_EHEAD, istat,nbyte = ',istat,nbyte
      stop
   endif   
   
   nbyte = 4 * bytepos_size(lun) 
   call GWRDISCB(lun, bytepos(1,lun), nbyte, istat)    
   if (istat /= nbyte) then
      print *,'**Error2 in EFS_UPDATE_EHEAD, istat,nbyte = ',istat,nbyte
      stop
   endif
   
   position = lastbyte(lun)
   call GPODISCB(lun, position)                   !return to end of file                   

end subroutine EFS_UPDATE_EHEAD



! EFS READ_EHEAD reads event header and bytepos array
!   Inputs: lun -- unit number (i4)
!   Returns: ehead -- event header (structure in EFS_MODULE)
!
subroutine EFS_READ_EHEAD(lun,ehead)
   use EFS_MODULE
   implicit none   
   integer :: lun, nbyte, istat, i, SWAPINT, SWAPREAL
   type(eheader) :: ehead   

   nbyte = nbyte_ehead 
   call GRDDISCB(lun, ehead, nbyte, istat)
   if (istat /= nbyte) then
      print *,'**Error1 in EFS_READ_EHEAD, istat,nbyte = ',istat,nbyte
      stop
   endif
   
   if (bytetype(lun) /= 1) then
      istat = SWAPINT(ehead%maxnumts)     
      istat = SWAPINT(ehead%numts)
      istat = SWAPINT(ehead%cuspid)
      istat = SWAPREAL(ehead%qlat)
      istat = SWAPREAL(ehead%qlon)
      istat = SWAPREAL(ehead%qdep)
      istat = SWAPINT(ehead%qyr)
      istat = SWAPINT(ehead%qmon)
      istat = SWAPINT(ehead%qdy)
      istat = SWAPINT(ehead%qhr)
      istat = SWAPINT(ehead%qmn)
      istat = SWAPREAL(ehead%qsc)
      istat = SWAPREAL(ehead%qmag1)
      istat = SWAPREAL(ehead%qmag2)
      istat = SWAPREAL(ehead%qmag3)
      istat = SWAPREAL(ehead%qmoment)
      istat = SWAPREAL(ehead%qstrike)
      istat = SWAPREAL(ehead%qdip)
      istat = SWAPREAL(ehead%qrake)
      do i = 1, 20         
         istat = SWAPINT(ehead%dummy(i))
      enddo      
   endif
   
   if (ehead%maxnumts > max_bytepos_size) then
      print *,'**Error in EFS_READ_EHEAD, maxnumts too big'
      print *, ehead%maxnumts, max_bytepos_size 
      stop
   endif
   
   numts_total(lun) = ehead%numts 
   
   bytepos_size(lun) = ehead%maxnumts
   nbyte = 4 * bytepos_size(lun) 
   call GRDDISCB(lun, bytepos(1,lun), nbyte, istat)
   if (istat /= nbyte) then
      print *,'**Error2 in EFS_READ_EHEAD, istat,nbyte = ',istat,nbyte
      stop
   endif
   
   if (bytetype(lun) /= 1) then
      do i = 1, bytepos_size(lun)
         istat = SWAPINT(bytepos(i,lun))         
      enddo
   endif
   
end subroutine EFS_READ_EHEAD



! EFS LIST_EHEAD lists contents of event header
!   Inputs: ehead -- event header (structure in EFS_MODULE)
!
subroutine EFS_LIST_EHEAD(ehead)
   use EFS_MODULE
   implicit none

   type(eheader) :: ehead
       
   print *,'efslabel = ', ehead%efslabel
   print *,'datasource = ', ehead%datasource
   print *,'maxnumts = ', ehead%maxnumts
   print *,'numts = ', ehead%numts 
   print *,'cuspid = ',ehead%cuspid
   print *,'qtype = ', ehead%qtype 
   print *,'qlat = ', ehead%qlat 
   print *,'qlon = ', ehead%qlon
   print *,'qdep = ', ehead%qdep 
   print *,'qlocqual = ',ehead%qlocqual
   print *,'qhr = ', ehead%qyr 
   print *,'qmon = ', ehead%qmon 
   print *,'qdy = ', ehead%qdy 
   print *,'qhr = ', ehead%qhr 
   print *,'qmn = ', ehead%qmn 
   print *,'qsc = ', ehead%qsc 
   print *,'qmag1 = ', ehead%qmag1
   print *,'qmag1type = ', ehead%qmag1type    
   print *,'qmag2 = ', ehead%qmag2 
   print *,'qmag2type = ', ehead%qmag2type   
   print *,'qmag3 = ', ehead%qmag3        
   print *,'qmag3type = ', ehead%qmag3type
   print *,'qmoment = ',ehead%qmoment
   print *,'qmomenttype = ',ehead%qmomenttype
   print *,'qstrike = ',ehead%qstrike
   print *,'qdip = ',ehead%qdip
   print *,'qrake = ',ehead%qrake
   print *,'qfocalqual = ',ehead%qfocalqual
     
end subroutine EFS_LIST_EHEAD




! EFS WRITE_TSHEAD writes time series header
!   Inputs: lun -- unit number (i4)          
!           tshead -- time series header (structure in EFS_MODULE)
!  Returns: its -- time series number (goes up one for each call)
!
subroutine EFS_WRITE_TSHEAD(lun, its, tshead)
   use EFS_MODULE
   implicit none  
      
   integer :: lun, istat, its, nbyte, position
           
   type(tsheader) :: tshead
   
   its_written(lun) = its_written(lun) + 1
   its = its_written(lun)
   
   bytepos(its,lun) = lastbyte(lun)                         !assume is writing to end of file 
   
!   position = bytepos(its,lun)
!   call GPODISCB(lun, position)                   !position to byte number in file      
   
   nbyte = nbyte_tshead                         
   call GWRDISCB(lun, tshead, nbyte, istat)
   if (istat /= nbyte) then
      print *,'**Error in EFS_WRITE_TSHEAD, istat,nbyte = ',istat,nbyte
      stop
   endif

   if (lastbyte(lun) > 2147483647 - nbyte) then
      print *, '***Error: EFS file nbytes > 2147483647'
      stop
   endif

   lastbyte(lun) = lastbyte(lun) + nbyte 

end subroutine EFS_WRITE_TSHEAD



! EFS_READ_TSHEAD reads time series header
!    Inputs: lun -- unit nubmer (i4)
!            its -- time series number (i4)
!    Returns: tshead -- time series header (structure in EFS_MODULE)
!
 subroutine EFS_READ_TSHEAD(lun, its, tshead)
   use EFS_MODULE 
   implicit none
      
   integer :: lun, istat, its, nbyte, position      
   type(tsheader) :: tshead
   
   if (its < 1 .or. its > numts_total(lun)) then
      print *,'**Error in EFS_READ_TSHEAD, its out of bounds'
      print *,its,numts_total(lun)
   endif
   
   position = bytepos(its,lun)
   call GPODISCB(lun, position)                   !position to byte number in file      
   
   nbyte = nbyte_tshead                         
   call GRDDISCB(lun, tshead, nbyte, istat)
   if (istat /= nbyte) then
      print *,'**Error in EFS_READ_TSHEAD, istat,nbyte = ',istat,nbyte
      stop
   endif
   
   if (bytetype(lun) /= 1) call EFS_SWAP_TSHEAD(tshead)

end subroutine EFS_READ_TSHEAD




! EFS_INIT_TSHEAD sets time series header (tshead) to default values
!   Returns:  tshead (structure in EFS_MODULE)
!
subroutine EFS_INIT_TSHEAD(tshead)
   use EFS_MODULE 
   implicit none
   integer :: i
       
   type(tsheader) :: tshead   

   tshead%npts = 0   
   tshead%stname = ' '
   tshead%chnm = ' '
   tshead%stype = ' '
   tshead%loccode = ' '
   tshead%datasource = ' '   
   tshead%sensor = ' '
   tshead%compazi = -99.
   tshead%compang = -99.
   tshead%dva = ' '
   tshead%gain = 0.
   tshead%units = ' '
   tshead%f1 = -1.
   tshead%f2 = -1.
   tshead%dt = 0.0
   tshead%syr = 0
   tshead%smon = 0
   tshead%sdy = 0
   tshead%shr = 0
   tshead%smn = 0
   tshead%ssc = 0.0
   tshead%tdif = 0.0     
   tshead%slat = 0.0
   tshead%slon = 0.0
   tshead%selev = 0.0
   tshead%del = 0.0
   tshead%sazi = 0.
   tshead%qazi = 0.
   
   tshead%pick1 = 0.0
   tshead%pick1q = ' '
   tshead%pick1name = ' '
   tshead%pick2 = 0.0
   tshead%pick2q = ' '
   tshead%pick2name = ' '
   tshead%pick3 = 0.0
   tshead%pick3q = ' '
   tshead%pick3name = ' '
   tshead%pick4 = 0.0
   tshead%pick4q = ' '
   tshead%pick4name = ' '
   
   tshead%ppolarity = ' '
   tshead%problem = ' '
   
   do i = 1, 20         
      tshead%dummy(i) = 0
   enddo
      
end subroutine EFS_INIT_TSHEAD



! EFS_TESTINIT_TSHEAD sets time series header (tshead) to some arbitrary values
!    Returns: tshead (structure in EFS_MODULE)
!
subroutine EFS_TESTINIT_TSHEAD(tshead)       
   use EFS_MODULE 
   implicit none
   integer :: i
   
   type(tsheader) :: tshead   

   tshead%npts = 2000   
   tshead%stname = 'PAS'
   tshead%chnm = 'chnm'
   tshead%stype = 'styp'
   tshead%loccode = 'loccode'
   tshead%datasource = 'dsource'   
   tshead%sensor = 'sensor'
   tshead%compazi = -42.2
   tshead%compang = 89.3
   tshead%dva = 'V'
   tshead%gain = 1.2e3
   tshead%units = 'cm/s'
   tshead%f1 = -1.
   tshead%f2 = -1.
   tshead%dt = 0.01
   tshead%syr = 2001
   tshead%smon = 3
   tshead%sdy = 13
   tshead%shr = 20
   tshead%smn = 23
   tshead%ssc = 40.14
   tshead%tdif = -3.     
   tshead%slat = 33.5
   tshead%slon = -120.3
   tshead%selev = 0.54
   tshead%del = 55.1
   tshead%sazi = 130.2
   tshead%qazi = 295.3
   
   tshead%pick1 = 5.1
   tshead%pick1q = 'A'
   tshead%pick1name = 'P'
   tshead%pick2 = 8.1
   tshead%pick2q = 'C'
   tshead%pick2name = 'S'
   tshead%pick3 = 12.1
   tshead%pick3q = 'A'
   tshead%pick3name = 'SS?'
   tshead%pick4 = 0.0
   tshead%pick4q = ' '
   tshead%pick4name = ' '   
   
   tshead%ppolarity = 'U'
   tshead%problem = 'prob'
   
   do i = 1, 20         
      tshead%dummy(i) = 0
   enddo
   
!   print *,'TESTINIT_TSHEAD npts = ',tshead%npts
            
end subroutine EFS_TESTINIT_TSHEAD 
 


! EFS_LIST_TSHEAD lists contents of time series header (tshead)
!   Inputs: tshead -- time series header (structure from EFS_MODULE)
!           
subroutine EFS_LIST_TSHEAD(tshead)
   use EFS_MODULE                
   implicit none
   integer :: i    
   type(tsheader) :: tshead  
      
   print *,'stname = ', tshead%stname
   print *,'chnm = ', tshead%chnm
   print *,'stype = ', tshead%stype
   print *,'loccode = ', tshead%loccode
   print *,'datasource = ', tshead%datasource
   print *,'sensor = ',tshead%sensor
   print *,'compazi = ',tshead%compazi
   print *,'compang = ',tshead%compang
   print *,'dva = ',tshead%dva
   print *,'gain = ',tshead%gain
   print *,'units = ',tshead%units
   print *,'f1 = ', tshead%f1
   print *,'f2 = ', tshead%f2      
   print *,'npts = ', tshead%npts
   print *,'dt = ', tshead%dt
   print *,'syr = ', tshead%syr
   print *,'smon = ', tshead%smon 
   print *,'sdy = ', tshead%sdy
   print *,'shr = ', tshead%shr
   print *,'smn = ', tshead%smn
   print *,'ssc = ', tshead%ssc 
   print *,'tdif = ', tshead%tdif    
   print *,'slat = ', tshead%slat
   print *,'slon = ', tshead%slon
   print *,'selev = ', tshead%selev
   print *,'del = ',tshead%del
   print *,'sazi = ',tshead%sazi
   print *,'qazi = ',tshead%qazi    
   print *,'pick1 = ', tshead%pick1
   print *,'pick1q = ', tshead%pick1q
   print *,'pick1name = ', tshead%pick1name
   print *,'pick2 = ', tshead%pick2
   print *,'pick2q = ', tshead%pick2q
   print *,'pick2name = ', tshead%pick2name 
   print *,'pick3 = ', tshead%pick3 
   print *,'pick3q = ', tshead%pick3q
   print *,'pick3name = ', tshead%pick3name
   print *,'pick4 = ', tshead%pick4
   print *,'pick4q = ', tshead%pick4q
   print *,'pick4name = ', tshead%pick4name
   print *,'ppolarity = ', tshead%ppolarity
   print *,'problem = ', tshead%problem

end subroutine EFS_LIST_TSHEAD 
      
                          
! EFS_WRITE_TS write times series to EFS file.  This should be done immediately after writing
!       time series header using EFS_WRITE_TSHEAD
!   Inputs:  lun -- unit number (i4)
!            npts -- number of points to write (should match tshead%nputs) (i4)
!            x -- array with points (r*4)
!
subroutine EFS_WRITE_TS(lun, npts, x)
   use EFS_MODULE
   implicit none
   integer :: lun,istat,npts,nbyte
   real :: x(npts)
   
   nbyte = 4*npts                                   !hardwired to this header type
   call GWRDISCB(lun, x, nbyte, istat)
   if (istat /= nbyte) then
      print *,'**Error in EFS_WRITE_TS, istat,nbyte = ',istat,nbyte
      stop
   endif

   if (lastbyte(lun) > 2147483647 - nbyte) then
      print *, '***Error: EFS file nbytes > 2147483647'
      stop
   endif
   
   lastbyte(lun) = lastbyte(lun) + nbyte

end subroutine EFS_WRITE_TS


! EFS_READ_HEADTS reads time series header AND time series
!   This does same thing as calling EFS_READ_TSHEAD and then EFS_READTS 
!    Inputs:  lun -- unit number (i4)
!             its -- time series number (i4)
!    Returns: tshead -- time series header (structure in EFS_MODULE)
!
subroutine EFS_READ_HEADTS(lun, its, tshead, x)
   use EFS_MODULE
   implicit none
   integer, parameter :: maxnpts=100000000          !maximum number of points in time series
   real :: x(maxnpts)
   type(tsheader) :: tshead           
   
   integer :: lun, istat, its, npts, nbyte, position
   
   if (its < 1 .or. its > numts_total(lun)) then
      print *,'**Error in EFS_READ_HEADTS, its out of bounds'
      print *, its, numts_total(lun)
   endif
   
   position = bytepos(its,lun)
   call GPODISCB(lun, position)                   !position to byte number in file
      
   nbyte = nbyte_tshead                         
   call GRDDISCB(lun, tshead, nbyte, istat)          !read tshead
   if (istat /= nbyte) then
      print *,'**Error1 in EFS_READ_HEADTS, istat,nbyte = ',istat,nbyte
      stop
   endif
   
   if (bytetype(lun) /= 1) call EFS_SWAP_TSHEAD(tshead)   
   
   npts = tshead%npts
   if (npts > maxnpts) then
      print *,'Error2 in EFS_READ_HEADTS, too many points ',npts,maxnpts
      stop
   endif
         
   nbyte = 4*tshead%npts                        
   call GRDDISCB(lun, x, nbyte, istat)
   if (istat /= nbyte) then
      print *,'**Error3 in EFS_READ_HEADTS, istat,nbyte = ',istat,nbyte
      stop
   endif
   
   if (bytetype(lun) /= 1) call EFS_SWAP_TS(x, npts)

end subroutine EFS_READ_HEADTS



! EFS_READ_TS reads time series
!    Inputs:  lun -- unit number (i4)
!             its -- time series number (i4)
!             npts -- number of points, normally should match tshead%npts (i4)
!    Returns: ts -- time series array (r*4)
!
subroutine EFS_READ_TS(lun, its, npts, x)
   use EFS_MODULE
   implicit none
   integer, parameter :: maxnpts=100000000          !maximum number of points in time series
   real :: x(maxnpts)      
   
   integer :: lun, istat, its, npts, nbyte, position
   
   if (its < 1 .or. its > numts_total(lun)) then
      print *,'**Error in EFS_READ_TS, its out of bounds'
      print *,its,numts_total(lun)
   endif   
   
   position = bytepos(its,lun) + nbyte_tshead
   call GPODISCB(lun, position)                   !position to byte number in file
   
!   print *,'EFS_READ_TS position = ',position 

   if (npts > maxnpts) then
      print *,'Error in EFS_READ_TS, too many points ',npts,maxnpts
      stop
   endif
         
   nbyte = 4*npts                        
   call GRDDISCB(lun, x, nbyte, istat)
   if (istat /= nbyte) then
      print *,'**Error2 in EFS_READ_TS, istat,nbyte = ',istat,nbyte
      stop
   endif
   
   if (bytetype(lun) /= 1) call EFS_SWAP_TS(x, npts)   

end subroutine EFS_READ_TS



subroutine EFS_SWAP_TSHEAD(tshead)
   use EFS_MODULE
   implicit none
   integer :: istat, i, SWAPINT, SWAPREAL
   type(tsheader) :: tshead
   
      istat = SWAPINT(tshead%npts)   
      istat = SWAPREAL(tshead%compazi)
      istat = SWAPREAL(tshead%compang)
      istat = SWAPREAL(tshead%gain)
      istat = SWAPREAL(tshead%f1)
      istat = SWAPREAL(tshead%f2)
      istat = SWAPREAL(tshead%dt)
      istat = SWAPINT(tshead%syr)
      istat = SWAPINT(tshead%smon)
      istat = SWAPINT(tshead%sdy)
      istat = SWAPINT(tshead%shr)
      istat = SWAPINT(tshead%smn)
      istat = SWAPREAL(tshead%ssc)
      istat = SWAPREAL(tshead%tdif)   
      istat = SWAPREAL(tshead%slat)
      istat = SWAPREAL(tshead%slon)
      istat = SWAPREAL(tshead%selev)
      istat = SWAPREAL(tshead%del)
      istat = SWAPREAL(tshead%sazi)
      istat = SWAPREAL(tshead%qazi)   
      istat = SWAPREAL(tshead%pick1)
      istat = SWAPREAL(tshead%pick2)
      istat = SWAPREAL(tshead%pick3)
      istat = SWAPREAL(tshead%pick4)   
      do i = 1, 20         
         istat = SWAPINT(tshead%dummy(i))
      enddo
   
end subroutine EFS_SWAP_TSHEAD 


subroutine EFS_SWAP_TS(x, npts)
   use EFS_MODULE
   implicit none
   integer :: npts, istat, i, SWAPREAL
   real, dimension(npts) :: x
   
   do i = 1, npts
      istat = SWAPREAL(x(i))
   enddo
   
end subroutine EFS_SWAP_TS
  


