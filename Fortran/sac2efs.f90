! program to convert SAC files to EFS files 

program sac2efs
   use EFS_MODULE
   implicit none
         
   integer :: lun, mode, lundi, nwrds, istat, maxnumts, i, npts, itrace, its=0, iok, nscan
   real (kind=8) :: sc8
   integer :: iy ,imon ,iday ,ih ,im, iswap, swapint, &
              ihypo, qyr, qmon, qdy, qhr, qmn 
   real :: sec, swapreal, qsc, qlat, qlon, qdep, qmag, hourshift
   character (len = 100) :: dirname, infile, saclistfile, sacfilename, efsname 
   type(eheader) :: ehead
   type(tsheader) :: tshead

   integer, parameter :: nhed1=110, nhed2=192,  maxnpts=1000000
   character (len=4), dimension(nhed1) :: sh1
   character  (len=1), dimension(nhed2) :: sh2
   integer :: jy,jd,jh,jm,js,jms,jpts
   real :: ddt, toffset, qoffset, stla, stlo, stel, dist, evlat, evlon, evdep, evmag
   real, dimension(maxnpts) :: buf
   character (len=4) :: jchn1, knetwk
   character (len=8) :: jsta
   equivalence (sh1(1),ddt),(sh1(6),toffset)    !***note toffset parameter!
   equivalence (sh1(8),qoffset), (sh1(36),evlat), (sh1(37),evlon)
   equivalence (sh1(39),evdep), (sh1(40),evmag)
   equivalence (sh1(71),jy),(sh1(72),jd), (sh1(73),jh)
   equivalence (sh1(74),jm),(sh1(75),js),(sh1(76),jms)
   equivalence (sh1(80),jpts)
   equivalence (sh1(32),stla),(sh1(33),stlo),(sh1(34),stel) !station coord.      
   equivalence (sh1(51),dist)  ! epicentral distance, km 
 !  equivalence (sh2(1),jsta),(sh2(21),jchn1),(sh2(22),knetwk)
   
   real, dimension(5000) :: x
   
   print *,'Enter directory name for SAC files (with / on end)'
   read (*,'(a)') dirname
   
   print *,'Enter file name with list of SAC file names'
   read (*,'(a)') saclistfile
   
   open (11,file=saclistfile,status='old')      
         
   print *,'Enter output EFS file name'
   read (*,'(a)') efsname
   
   print *, 'make hypo/time corrections? 0=no, 1=yes'
   read *, ihypo
   if (ihypo == 1) then
      print *, 'Enter event yr, mon, dy, hr, mn, sc'
      read *, qyr, qmon, qdy, qhr, qmn, qsc
      print *, 'Enter event lat, lon, dep'
      read *, qlat, qlon, qdep
      print *, 'Enter event magnitude'
      read *, qmag
      print *,'Enter hours correction to add to 1st sample time (or zero)'
      read *, hourshift
   endif
   
   
   call EFS_OPEN_NEW(lun, efsname)
   
   print *, 'EFS file opened: ', efsname
   
   maxnumts = 3000                   
   call EFS_INIT_EHEAD(maxnumts, ehead)   
   
!   call EFS_WRITE_EHEAD(lun,ehead)       !don't write until after reading first sac header

   
   
100   read (11,'(a)',end=200) sacfilename
      if (sacfilename(1:2).eq.'  ') go to 100   !sometimes has blank line (why?!)
      infile = trim(dirname) // sacfilename
!      print *,'infile = ',infile(1:100)

      iok=1   
      mode = 4   
      call getfil(mode,lundi,infile,istat)          !open sac file
      if(istat.lt.0) then
          print *,'open sac file error',istat,' ',infile(1:100)
          iok=-1
          go to 165            !skip this file
      end if
!           
! read sac header 
      nwrds=nhed1
      call rddisc(lundi,sh1,nwrds,istat)
!      print *,'istat=',istat
      nwrds=nhed2
      call rddisc_2byte(lundi,sh2,nwrds,istat)
!      print *,'istat=',istat
!      if(istat.lt.nwrds) then
!         print *,'error on sac read',istat,nwrds,' ',infile(1:100)
!         iok=-1
!         go to 165     !***skip this file
!      end if 


       if (ddt > 0.0001 .and. ddt < 2000.) then
          iswap = 0
       else
          iswap = 1
          istat = SWAPREAL(ddt)
          istat = SWAPINT(jpts)
          istat = SWAPREAL(toffset)
          istat = SWAPREAL(qoffset)
          istat = SWAPREAL(evlat)
          istat = SWAPREAL(evlon)
          istat = SWAPREAL(evdep)
          istat = SWAPREAL(evmag)
          istat = SWAPREAL(stla)
          istat = SWAPREAL(stlo)
          istat = SWAPREAL(stel)
          istat = SWAPREAL(dist)
          istat = SWAPINT(jy)
          istat = SWAPINT(jd)
          istat = SWAPINT(jh)
          istat = SWAPINT(jm)
          istat = SWAPINT(js)
          istat = SWAPINT(jms)
       endif
 
        
       jsta = sh2(1)
        i = 2 
20     if ((ichar(sh2(i)).NE.0).AND.(i.LE.8)) then
         jsta = trim(jsta) // sh2(i)
       i = i+1 
       goto 20
       endif
      
       knetwk = sh2(169)
       i = 170
30     if ((ichar(sh2(i)).NE.0).AND.(i.LE.173)) then
         knetwk = trim(knetwk) // sh2(i) 
       i = i+1
       goto 30
       endif

       jchn1 = sh2(163)
       i = 164
40     if ((ichar(sh2(i)).NE.0).AND.(i.LE.168)) then
         jchn1 = trim(jchn1) // sh2(i)
       i = i+1
       goto 40
       endif
       
!       jchn1 = sh2(185)
!       i = 186
!40     if ((ichar(sh2(i)).NE.0).AND.(i.LE.189)) then
!         jchn1 = trim(jchn1) // sh2(i)
!       i = i+1
!       goto 40
!       endif       
       
  
 
!      print *,'jsta=, knetwk=,jchn1=',jsta,',', knetwk,',',jchn1
! clear the '-12345' reminds
     if (jsta(4:6).eq.'345') jsta(4:6) = '   '
     if (jsta(5:6).eq.'45') jsta(5:6) = '  '
     if (jsta(6:6).eq. '5') jsta(6:6) = ' '
     if (knetwk(4:4).eq.'3') knetwk(4:4) = ' '
!      print *,' '
!      print *,'sac file name: ',sacfilename(1:50)   
!      print *,'jsta = ',jsta
!      print *,'jchn1 = ',jchn1
!      print *,'knetwk = ',knetwk
!      print *,'jpts = ',jpts
!      print *,'ddt = ',ddt
!      print *,'toffset = ',toffset
!      print *,'qoffset = ',qoffset
!      print *,'jy,jd,jh,jm,js,jms = ',jy,jd,jh,jm,js,jms
!      print *,'stla,stlo,stel,dist = ',stla,stlo,stel,dist
      
      if (jy < 1900 .or. jy > 2100) then
         print *, '***Warning: SAC file problem, skipped' 
         print *, 'sacfilename = ', infile(1:100)
         iok = -1
         go to 165
      endif
            
! read in sac data
      nscan= jpts         
      nwrds=nscan
      if (nwrds > maxnpts) then
         print *,'**Warning, time series too long, npts = ',nwrds
         print *,'  truncated to ',maxnpts
         print *, 'sacfilename = ', infile(1:100)         
         nwrds = maxnpts          
      endif

!      print *,'Reading data, nwrds = ', nwrds      
      call rddisc(lundi,buf,nwrds,istat)
!      print *,'istat = ',istat      
      if(istat.lt.nwrds) then
         print *,'error reading data ',istat,' ',sacfilename
         print *, 'sacfilename = ', infile(1:100)
         iok=-1
!         go to 165     !***skip this file    (****COMMENTED OUT BECAUSE THIS DOES NOT SEEM TO WORK)
         go to 100
      end if
      
      if (iswap == 1) then
         do i = 1, nwrds
            istat = SWAPREAL(buf(i))
         enddo
      endif
      
      
! close sac file
! mode=2 releases the unit and close the file
165   mode=2
      call frefil(mode,lundi,istat)
      if(istat.lt.0) then
         print *,'close sac file error',istat,' ',sacfilename
!         iok=-1
      end if
      if (iok.eq.-1) go to 100      !bad, read next sac file name
      
! now transfer to EFS variables
   call EFS_INIT_TSHEAD(tshead) 
   tshead%npts = jpts     
   tshead%stname = jsta
   tshead%chnm = jchn1
   tshead%stype = knetwk
   tshead%dt = ddt   
   
!   tshead%tdif = toffset                    !**change when implement event timing
   tshead%slat = stla
   tshead%slon = stlo
   tshead%selev = stel/1000            ! div by 1000 to be km unit
   if (dist.lt.0) then
    tshead%del = 0.0
   else
    tshead%del = dist
   end if

   iy = jy
   call DT_GET_DAY(jy,jd,imon,iday)
   ih = jh
   im = jm
   sec = real(js) + real(jms)/1000.   

   if (ihypo == 0) then    
      sc8 = dble(toffset)
      call DT_ADDTIME(iy, imon, iday, ih, im, sec,   &
         tshead%syr,tshead%smon,tshead%sdy,tshead%shr,tshead%smn,tshead%ssc,sc8)
   else
      sc8 = dble(toffset + hourshift*3600.)
      call DT_ADDTIME(iy, imon, iday, ih, im, sec,   &
         tshead%syr,tshead%smon,tshead%sdy,tshead%shr,tshead%smn,tshead%ssc,sc8)   
   endif
      
   if (its == 0) then
      if (ihypo == 0) then
         sc8 = dble(qoffset)
         call DT_ADDTIME(iy, imon, iday, ih, im, sec,   &
          ehead%qyr,ehead%qmon,ehead%qdy,ehead%qhr,ehead%qmn,ehead%qsc,sc8)      
         ehead%qlat = evlat
         ehead%qlon = evlon
         ehead%qdep = evdep/1000.
         ehead%qmag1 = evmag
      else
         ehead%qyr = qyr
         ehead%qmon = qmon
         ehead%qdy = qdy
         ehead%qhr = qhr
         ehead%qmn = qmn
         ehead%qsc = qsc
         ehead%qlat = qlat
         ehead%qlon = qlon
         ehead%qdep = qdep
         ehead%qmag1 = qmag       
      endif
      call EFS_WRITE_EHEAD(lun,ehead)
   endif
   
   tshead%tdif = toffset - qoffset
   
   call EFS_WRITE_TSHEAD(lun, its, tshead)
!   print *,'EFS tshead written, its = ',its

      

   npts = nwrds   
   call EFS_WRITE_TS(lun, npts, buf)
   
   if (its == maxnumts) then
      print *, '***maximum permitted number of time series written: ', maxnumts
      print *, '   skipping any remaining SAC files'
      go to 200
   endif
   
   go to 100
      
200   close (11)
   
   
   call EFS_UPDATE_EHEAD(lun,ehead)   
   
   call EFS_CLOSE(lun)   
            
           
end program sac2efs 


