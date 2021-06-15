program sac2efs_hvoaqms

! Program to convert HVO SAC data to EFS format
! Written by R.S. Matoza December 2017
!
! Custom written for post-2009 AQMS data sent by Paul Okubo in September 2017
! This is a major reboot of the original sac2efs_hvo routine by Peter Shearer (this code written from scratch)
! These codes use the SAC libraries for SAC file I/O (original sac2efs routines do not)

use EFS_MODULE
implicit none
include "sacf.h"

! NOTES ON SACIO:
! GETFHV gets float or REAL header variables
! GETIHV gets character strings enumerated as int or INTEGER header variables
! GETKHV gets character string header variables
! GETLHV gets LOGICAL header variables (declared as long in C)
! GETNHV gets int or INTEGER header variables.

! General variable
integer :: i, j, k
character*300 :: sacfname, lsname, sacpath, outfiledir, stfname
!character*1 :: stcomp
character*4 :: stcomp4
integer :: wmax
parameter (wmax=5000000)
real, dimension(wmax) :: w=0, w_res=0, w_flt=0
real :: fs
integer :: nfiles
integer :: fid_lsname=11, fid_evf=12, fid_evlist=13, fid_outfdir=14
integer :: fid_stfile=15
integer :: ios
real :: del_res
integer :: n_res
integer :: iresampcount=0
character*300, dimension(1000) :: resamplist
integer :: nsta = 0

! event file
character*300 :: evfname
character*100 :: linebuf
integer :: qid
integer :: qyr, qmon, qdy, qhr, qmn
real :: qsc, qmag, qlat, qlon, qdep

! SAC Header
character*8 :: sacnsta, sacntyp, sacnchn, sactemp
integer*4 :: iy, id, ih, im, is, ims, imon, iday
real*4 :: ss
integer*4 :: iy2, ih2, im2, imon2, iday2 ! new set to add beg from SAC header
real*4 :: ss2
integer*4 :: iy_ref, id_ref, ih_ref, im_ref, is_ref
integer*4 :: imon_ref, iday_ref
real*4 :: ss_ref
real*4 :: calib
real*4 :: stlon, stlat, stelev
real*4 :: delta
real*4 :: stcmpinc, stcmpaz
integer*4 :: stnevid
real*4 :: sacbstart ! should be same as 'beg' -- see below
real*8 :: sacbstart8

! Define variables used in the filtering routine
real*8 flow, fhigh
real*8 transition_bandwidth, attenuation
real*8 del_r8
integer order, passes

! Declare Variables used in the rsac1() subroutine
real beg, del
integer nlen
integer nerr

! EFS
character*300 efsname, dirname, efsdirname
character (len=10) :: charcusp
integer :: cuspbeg
integer, dimension(500,2) :: keyyr, keymn
integer, dimension(2) :: ndirkey
character (len=300), dimension(500,2) :: dname
type (eheader) :: ehead
type (tsheader) :: tshead
integer :: lun
integer :: maxnumts=1000
integer :: its=0
real :: deldist, deldistkm
real, parameter :: degkm=111.19
real*8 :: tdifr8
integer :: ioutmenu

! evlist file
character*300 :: evlistname
character (len = 300) :: fmt_evlist, fmt_stlist
character (len=19) :: evname
character (len=10) :: cidstr
real rms, herr, deperr, t0err
character (len=1) :: errtype, foctype, magtype
integer npkused, np_pks, ns_pks, istrike, idip, irake, kk, kbeg, kcusp, nchr
integer lenstr
character (len=1) :: locqual
character*2 evtype

! phase pick file
character (len=300) :: phasepickfile
character (len=7) :: stname_sac
real :: pick_p, pick_s
real :: ppick, spick
integer :: qual_p, qual_s


! inputs/filenames:
print *, 'Enter SAC event .evnt file: '
read(5,"(a)") evfname
print *, 'SAC .evnt file: ', trim(evfname)

print *, 'Enter number of SAC waveform files to read: '
read *, nfiles

print *, 'Enter file with list of SAC files to read: '
read (*, '(a)') lsname
print *, trim(lsname)
open(fid_lsname, file=trim(lsname), status = 'old')

print *, 'Enter SAC files path: '
read (*, '(a)') sacpath

print *, 'Enter input phase pick file in .arc format: '
read(5,"(a)") phasepickfile
print *, 'Phase pick file: ', trim(phasepickfile)

print *, 'Enter evlist file name (1-line file to be created): '
read(5,"(a)") evlistname
print *, 'evlist file name: ', trim(evlistname)

print *, 'Enter station list file name to create: '
read(5,"(a)") stfname
print *, 'Station file name to write: ', trim(stfname)
open(fid_stfile,file=trim(stfname),status='new')

print *, 'Enter directory to write EFS file: '
read(5,"(a)") efsdirname

! Read the event file:
print *, 'Reading event file: ', trim(evfname)
open(fid_evf,file=trim(evfname),status='old')
read (fid_evf,'(a)') linebuf
close(fid_evf)
print *, 'Event file contents: '
print *, linebuf

read(linebuf(1:8),*) qid
print *, 'Event number: ', qid
read(linebuf(13:16),*) qyr
print *, 'Event year: ', qyr
read(linebuf(18:19),*) qmon
print *, 'Event month: ', qmon
read(linebuf(21:22),*) qdy
print *, 'Event day: ', qdy
read(linebuf(24:25),*) qhr
print *, 'Event hour: ', qhr
read(linebuf(27:28),*) qmn
print *, 'Event minute: ', qmn
read(linebuf(30:35),*) qsc
print *, 'Event second: ', qsc
read(linebuf(37:45),*) qlat
print *, 'Event lat: ', qlat
read(linebuf(47:56),*) qlon
print *, 'Event lon: ', qlon
read(linebuf(58:63),*) qdep
print *, 'Event dep: ', qdep
read(linebuf(67:70),*) qmag
print *, 'Event mag: ', qmag

! Create the new EFS file and write the event header ehead:
write(charcusp,"(i10)") qid
cuspbeg=1
do k = 10, 1, -1
    if (charcusp(k:k).eq.' ') then
        cuspbeg = k + 1
        exit
    endif
enddo

efsname = trim(efsdirname) // charcusp(cuspbeg:10) // '.efs'
print *, 'Writing EFS file name: ', efsname

call EFS_OPEN_NEW(lun,trim(efsname))
call EFS_INIT_EHEAD(maxnumts, ehead)
ehead%cuspid = qid
ehead%qlat = qlat
ehead%qlon = qlon
ehead%qdep = qdep
ehead%qyr = qyr
ehead%qmon = qmon
ehead%qdy = qdy
ehead%qhr = qhr
ehead%qmn = qmn
ehead%qsc = qsc
ehead%qmag1 = qmag
call EFS_LIST_EHEAD(ehead)
call EFS_WRITE_EHEAD(lun,ehead)

! write evlist file:
open (fid_evlist, file = evlistname,status='new')

evname='                '
write(cidstr,"(i10)") qid

nchr = 10
do i=1,nchr
    if (cidstr(i:i) .ne. ' ') exit
enddo
kcusp = i - 1
kbeg = 19-(nchr-kcusp)
evname(kbeg:19)=cidstr(kcusp:nchr)

rms=999.
herr=999.
deperr=999.
t0err=999.
errtype='x'
foctype='x'
npkused=0
np_pks=999
ns_pks=999
istrike=999
idip=999
irake=999
evtype = '  '                 !not in current event file (?)
magtype = ' '
locqual = 'T'

fmt_evlist = "(a19,x,i4,x,i2,x,i2,x,i2,x,i2,x,&
               f6.3,x,a2,x,f5.3,x,a1,x,&
               f9.5,x,f10.5,x,f7.3,x,a1,x,&
               f7.3,x,f7.3,x,f7.3,x,f7.3,x,a1,&
               x,i4,x,i4,x,i4,x,i4,x,i3,x,i4,x,a1)"
!print *, trim(fmt_evlist)
write (fid_evlist,trim(fmt_evlist)) evname,qyr,qmon,qdy,qhr,qmn,  &
               qsc,evtype,qmag,magtype,       &
               qlat,qlon,qdep,locqual,        &
               rms,herr,deperr,t0err,errtype, &
               npkused,np_pks,ns_pks,istrike,idip,irake,foctype

close(fid_evlist)


! begin loop over time series
! Read SAC file
do j=1,nfiles
    w = 0.     ! just in case: to avoid bugs with traces of different length
    w_res = 0. ! just in case
    w_flt = 0. ! just in case
    read (fid_lsname, '(a)',iostat=ios) sacfname
    if (ios < 0) then
        print *, '***ERROR, end of file reached in: ', trim(lsname), j
        stop
    else if (ios > 0) then
        print *, '***ERROR, read error on line: ', j, trim(lsname)
        stop
    endif

    sacfname = trim(sacpath) // trim(sacfname)

    print *, 'Reading SAC file: ', trim(sacfname)
    ! READ THE SAC FILE
    call rsac1(sacfname, w, nlen, beg, del, wmax, nerr)
    if(nerr .NE. 0) then
        write(*,*)'Error reading in file: ',sacfname
        call exit(-1)
        stop
    endif

    ! debug lines, check beg
    print *, trim(sacfname)
    print *, 'beg: ', beg
    !stop

    ! Check sample rate and resample or decimate if necessary
    fs = 1/del
    print *, 'Sampling rate: ', floor(fs), ' Hz'
    if ((fs .lt. 99.) .or. (fs .gt. 101.)) then
        print *, '**WARNING: Sample rate not 100 Hz ', fs, j
    endif
    if (fs .lt. 99.) then
        print *, 'Sample rate < 100 Hz. Resampling trace: ', fs, 100.
        del_res = 1./100.
        call RESAMP2(del,w,nlen,del_res,w_res,n_res)
        ! Validate resample: uncomment this section to check if resampling works OK
        ! Checked 12/14/17 RSM
        !open(21, file = 'validate.dat', status='new')
        !do k = 1, wmax
        !    write(21, *) w(k), w_res(k)
        !enddo
        !close(21)
        !print *, 'Wrote resamp validation file: validate.dat',del,del_res,nlen,n_res
        !stop
        w = 0
        nlen = n_res
        del = del_res
        w = w_res
        iresampcount = iresampcount + 1
        resamplist(iresampcount) = trim(sacfname)
    elseif (fs .gt. 101.) then
        print *, 'Sample rate > 100 Hz. Filtering then decimating trace: ', fs, 100.
        ! filter: Use SAC IIR filter routine, see filterf.f example in /sac/doc/examples
        passes = 2                 ! Want a zero-phase filter
        order  = 4
        transition_bandwidth = 0.0 ! Only for Chebyshev Filter
        attenuation = 0.0          ! Only for Chebyshev Filter
        flow =  0.0                ! Ignored on SAC_FILTER_LOWPASS
        fhigh = 45.                ! Chosen to be slightly below 50 Hz Nyquist

        w_flt = w
        del_r8 = del               ! needs to be in double precision, see filterf.f
        call xapiir(w_flt, nlen, SAC_BUTTERWORTH, &
             transition_bandwidth, attenuation, &
             order, SAC_LOWPASS, &
             flow, fhigh, del_r8, passes)
        ! Now resample:
        del_res = 1./100.
        call RESAMP2(del,w_flt,nlen,del_res,w_res,n_res)
        ! Validate resample: uncomment this section to check if resampling works OK
        ! Checked 12/15/17 RSM
        !open(21, file = 'validate.dat', status='new')
        !do k = 1, wmax
        !    write(21, *) w(k), w_flt(k), w_res(k)
        !enddo
        !close(21)
        !print *, 'Wrote resamp validation file: validate.dat',del,del_res,nlen,n_res
        !stop
        w = 0
        nlen = n_res
        del = del_res
        w = w_res
        iresampcount = iresampcount + 1
        resamplist(iresampcount) = trim(sacfname)
    endif

    ! Check time-series length:
    print *, 'Time-series length (nlen):' , nlen
    if (nlen .ge. wmax) then
        print *, 'Error: data file too long. Increase wmax or reduce SAC buffer length'
        stop
    endif

    ! GET SAC HEADER INFO:
    call getnhv('NZYEAR',iy,nerr) ! start time
    call getnhv('NZJDAY',id,nerr)
    call getnhv('NZHOUR',ih,nerr)
    call getnhv('NZMIN',im,nerr)
    call getnhv('NZSEC',is,nerr)
    call getnhv('NZMSEC',ims,nerr)
    ss = float(is)+float(ims)/1000.
    call DT_GET_DAY(iy,id,imon,iday)

    print *, 'SAC header time, raw NZ values: '
    print *, 'Year: ', iy
    print *, 'Month: ', imon
    print *, 'Day: ', iday
    print *, 'JDay: ', id
    print *, 'Hour: ', ih
    print *, 'Min: ', im
    print *, 'Sec: ', ss

    ! Get additional "beginning" value from SAC header:
    ! https://ds.iris.edu/files/sac-manual/manual/file_format.html
    ! Note that the "beginning" time needs to be added to the NZ time to get the true start time of the trace
    ! In these sac files, NZ time is same as KZ time (reference time). But traces do not start at reference time, they are offset by "B" seconds. B must be added to the NZ time to get true start time
    call getfhv('b',sacbstart,nerr) ! Get floating point header value: B Note also this is same as "beg" read with rsac1 above
    sacbstart8 = dble(sacbstart)
    !print *, 'sacbstart: ', sacbstart, sacbstart8
    print *, 'Calling DT_ADDTIME to get true trace starttime', beg, sacbstart, sacbstart8
    CALL DT_ADDTIME(iy,imon,iday,ih,im,ss,  &
                    iy2,imon2,iday2,ih2,im2,ss2,sacbstart8)

    ! replace with shifted values
    iy = iy2
    imon = imon2
    iday = iday2
    ih = ih2
    im = im2
    ss = ss2

    print *, 'Year: ', iy
    print *, 'Month: ', imon
    print *, 'Day: ', iday
    print *, 'JDay: ', id
    print *, 'Hour: ', ih
    print *, 'Min: ', im
    print *, 'Sec: ', ss

    call getkhv('KNETWK',sacntyp,nerr) ! network name
    call getkhv('KSTNM',sacnsta,nerr)  ! station name
    call getkhv('KCMPNM',sacnchn,nerr) ! component name
    print *, sacntyp, sacnsta, sacnchn

    call getfhv('STLA',stlat,nerr)  ! station latitude
    call getfhv('STLO',stlon,nerr)  ! station longitude
    call getfhv('STEL',stelev,nerr) ! station elevation; note: this is in meters; converted to km below
    print *, stlat, stlon, stelev

    !call getfhv('delta',delta,nerr) ! don't do this again in case resampled above
    delta = del
    print *, 'Sample interval: ', delta

    call getfhv('CMPINC',stcmpinc,nerr)
    print *, 'CMPINC: ', stcmpinc

    call getfhv('CMPAZ',stcmpaz,nerr)
    print *, 'CMPAZ: ', stcmpaz

    call getnhv('NEVID',stnevid,nerr)
    print *, 'NEVID: ', stnevid

    ! check that event number matches
    if (stnevid .ne. qid) then
        print *, "***ERROR: station event number does not match event: "
        print *, trim(sacfname), trim(evfname)
        stop
    endif

    stcomp4 = sacnchn(1:4)

    fmt_stlist = "(a2,1x,a4,2x,a4,5x,f10.5,f12.5,f10.1)"
    write(fid_stfile,trim(fmt_stlist)) trim(sacntyp),adjustl(trim(sacnsta)),stcomp4,stlat,stlon,stelev/1000.
    nsta = nsta+1

    ! Get phase pick data
    ! read from yearly phase pick file (has both P and S for larger events) *** modified 12/18/2018 by RSM to improve phase pick read
    sactemp = adjustl(trim(sacnsta))
    stname_sac(1:5) = sactemp(1:5)  ! needed to avoid binary \x00 appearing in station name 08/13/2019
    sactemp = '        '
    ppick = -999.
    spick = -999.
    pick_p = -999.
    pick_s = -999.
    call GET_PHASEPICK_MOD(phasepickfile,qid,stname_sac,pick_p,qual_p,pick_s,qual_s)


    if (pick_p /= -999.) then
        ppick = pick_p
    endif

    if (pick_s /= -999.) then
        spick = pick_s
    endif

    print *, 'Got phase pick data: '
    print *, trim(phasepickfile),qid,stname_sac,pick_p,qual_p,pick_s,qual_s
    print *, ppick, spick


    ! Write time-series to EFS file
    its = its + 1
    print *, 'Time series: ', its
    call EFS_INIT_TSHEAD(tshead)
    !print *, 'tshead initialized: '
    !call EFS_LIST_TSHEAD(tshead)
    !print *, 'Replacing default values with: '
    !print *, sacnsta
    !print *, sacntyp
    !print *, sacnchn
    !print *, stlon
    !print *, stlat
    !print *, stelev/1000.             ! required in km for EFS format
    !print *, 'Year: ', iy
    !print *, 'Month: ', imon
    !print *, 'Day: ', iday
    !print *, 'JDay: ', id
    !print *, 'Hour: ', ih
    !print *, 'Min: ', im
    !print *, 'Sec: ', ss

    sactemp = adjustl(sacnsta)
    tshead%stname = sactemp(1:5)
    sactemp = '        '
    tshead%chnm = stcomp4            ! 4 character channel code 08/2019

    tshead%stype = sacntyp
    tshead%slat = stlat
    tshead%slon = stlon
    tshead%selev = stelev/1000.      ! required in km for EFS format

    tshead%gain = 1.0                ! should be 1.0 I think

    tshead%syr = iy
    tshead%smon = imon
    tshead%sdy = iday

    tshead%shr = ih
    tshead%smn = im
    tshead%ssc = ss


    ! get distance to source:
    call SPH_DISTDP(qlat,qlon,stlat,stlon,deldist)
    deldistkm = degkm*deldist
    tshead%del = deldistkm

    tshead%compang = stcmpinc
    tshead%compazi = stcmpaz

    ! sample rate
    tshead%dt = delta

    ! filter
    !tshead%f1 = flow
    !tshead%f2 = fhigh

    ! number of points in time series
    tshead%npts = nlen ! number of samples

    ! tdif -- first sample time minus event time, seconds (r*4)
    call DT_TIMEDIF(ehead%qyr,ehead%qmon,ehead%qdy,ehead%qhr,ehead%qmn,ehead%qsc, &
                    tshead%syr,tshead%smon,tshead%sdy,tshead%shr,tshead%smn,tshead%ssc,tdifr8)
    print *, "first sample time minus event time", real(tdifr8)
    tshead%tdif = real(tdifr8)

    ! add pick information if we have it:
      if (ppick .ne. -999.) then
         tshead%pick1 = ppick - tshead%tdif
         tshead%pick1name = 'P'
      endif
      if (spick .ne. -999.) then
         tshead%pick2 = spick - tshead%tdif
         tshead%pick2name = 'S'
      endif

    print *, 'New tshead: '
    call EFS_LIST_TSHEAD(tshead)
    call EFS_WRITE_TSHEAD(lun,its,tshead)

    call EFS_WRITE_TS(lun, nlen, w(1:nlen)) ! Write time-series
    call EFS_UPDATE_EHEAD(lun,ehead)        ! Update ehead

enddo
! end loop over time series

call EFS_CLOSE(lun) ! close EFS file
close(fid_stfile)   ! close station file

! check that end of file was reached in saclist file:
print *, ""
read (fid_lsname, '(a)', iostat=ios) sacfname
if (ios < 0) then
    print *, 'Success. End of file reached in file: ', lsname
else
    print *, '***Error: End of file NOT reached in file: ', lsname
    print *, '***Check nfiles', nfiles
endif
close(fid_lsname)

print *, "Number of SAC files resampled: ", iresampcount
print *, "List of resampled SAC files follows: "
do j = 1, iresampcount
    print *, trim(resamplist(j))
enddo

print *, "Number of time-series written: ", its
print *, "Expected number of time-series: ", nfiles
print *, "Number of stations written to station file: ", nsta, trim(stfname)

end program sac2efs_hvoaqms



subroutine GETEFSNAME(qyr, qmon, qid, ioutmenu, keyyr, keymn, ndirkey, dname, efsname)
      implicit none
      character*300, intent(out) :: efsname
      integer qid, qyr, qmon, ioutmenu, k
      character (len=10) :: charcusp
      character (len=11) :: chr11, chr11b
      character (len=8) :: chr8
      character (len=5) :: chr5
      integer lenname, cuspbeg
      character (len=300), dimension(500,2) :: dname
      character*300 dirname
      integer, dimension(500,2) :: keyyr, keymn
      integer, dimension(2) :: ndirkey

! create a new EFS file:
! output file name
      write (chr5,33) qyr
33    format ('/',i4)
      write (chr8,34) qyr,qmon
34    format ('/',i4,'/',i2.2)
      write (chr11,35) qyr,qmon
35    format ('/',i4,'efs','/',i2.2)
      write (chr11b,3599) qyr,qmon
3599  format ('/',i4,'eff','/',i2.2)
      write(charcusp,3600) qid
3600  format(i10)
      cuspbeg=1
      do k = 10, 1, -1
          if (charcusp(k:k).eq.' ') then
              cuspbeg = k + 1
              go to 36
          end if
      enddo
36    continue


call ASSIGN_DIR(qyr,qmon,keyyr(1,2),keymn(1,2),dname(1,2),ndirkey(2),dirname,lenname)
if (ioutmenu.eq.1) then         !single directory
    efsname=dirname(1:lenname) // '/' // charcusp(cuspbeg:10) // '.efs'
else if (ioutmenu.eq.2) then    !year subdirectory
    efsname=dirname(1:lenname) // chr5 // '/' // charcusp(cuspbeg:10) // '.efs'
else if (ioutmenu.eq.3) then       !year/month subdir
    efsname=dirname(1:lenname) // chr8 // '/' // charcusp(cuspbeg:10) // '.efs'
else if (ioutmenu.eq.4) then
    efsname=dirname(1:lenname) // chr11 // '/' // charcusp(cuspbeg:10) // '.efs'
else
    efsname=dirname(1:lenname) // chr11b // '/' // charcusp(cuspbeg:10) // '.efs'
end if
print *, 'GETEFSNAME assigning EFS file name: ', trim(efsname)

end subroutine GETEFSNAME


subroutine ASSIGN_DIR(iyr, imon, keyyr, keymn, dname, nkey, dirname, lenname)
    implicit none
    integer, parameter :: nmax = 500
    integer :: iyr, imon, lenname, nkey, i, ioff
    integer, dimension(nmax) :: keyyr, keymn
    character (len=300) :: dirname
    character (len=300), dimension(nmax) :: dname

    if (nkey > nmax) then
        print *,'***Error in ASSIGN_DIR, nkey = ', nkey
        stop
    end if

    do i = 1,nkey
        !      print *,i,keyyr(i),keymn(i),dname(i)(1:40)
        if (keyyr(i) == 0) go to 20
        if (keyyr(i) == iyr .and. keymn(i) == 0) go to 20
        if (keyyr(i) == iyr .and. keymn(i) == imon) go to 20
    enddo
    print *,'***Error in ASSIGN_DIR, year/month not in directory file'
    print *,'   iyr,imon = ', iyr, imon
    stop

20  dirname = dname(i)
    do i = 1, 300
        if (dirname(i:i) == ' ') go to 30
    enddo
    i = 301
30  lenname = i - 1

end subroutine ASSIGN_DIR






subroutine RESAMP2(dt1,a1,n1,dt2,a2,n2)
parameter (nmax=5000000)
real a1(nmax),t1(nmax),a2(nmax),t2,y2(nmax)

n2=int(float(n1-1)*dt1/dt2)
if (n1.gt.nmax.or.n2.gt.nmax) then
    print *,'***Array limits exceeded in RESAMP'
    print *,'dt1,dt2,n1,n2 = ',dt1,dt2,n1,n2
    return
end if

do i=1,n1
    t1(i)=float(i-1)*dt1
enddo

call SPLINE2(dt1,a1,n1,9.e30,9.e30,y2)

do i=1,n2
    t2=float(i-1)*dt2
    call SPLINT2(dt1,t1,a1,y2,n1,t2,a2(i))
enddo

return
end subroutine RESAMP2


SUBROUTINE SPLINE2(DX,Y,N,YP1,YPN,Y2)
PARAMETER (NMAX=5000000)
DIMENSION Y(N),Y2(N),U(NMAX)
IF (YP1.GT..99E30) THEN
    Y2(1)=0.
    U(1)=0.
ELSE
    Y2(1)=-0.5
    U(1)=(3./(DX))*((Y(2)-Y(1))/(DX)-YP1)
ENDIF
DO 11 I=2,N-1
    SIG=0.5
    P=SIG*Y2(I-1)+2.
    Y2(I)=(SIG-1.)/P
    U(I)=(6.*((Y(I+1)-Y(I))/(DX)-(Y(I)-Y(I-1))/(DX))/(2.*DX)-SIG*U(I-1))/P
11  CONTINUE
IF (YPN.GT..99E30) THEN
    QN=0.
    UN=0.
ELSE
    QN=0.5
    UN=(3./(DX))*(YPN-(Y(N)-Y(N-1))/(DX))
ENDIF
Y2(N)=(UN-QN*U(N-1))/(QN*Y2(N-1)+1.)
DO 12 K=N-1,1,-1
    Y2(K)=Y2(K)*Y2(K+1)+U(K)
12  CONTINUE
RETURN
END


SUBROUTINE SPLINT2(DX,XA,YA,Y2A,N,X,Y)
DIMENSION XA(N),YA(N),Y2A(N)
eps=dx/100.
klo=1+int(x/dx)
khi=klo+1
if (khi.gt.n.or.x.lt.xa(klo)-eps.or.x.gt.xa(khi)+eps) then
    print *,'***Problem in SPLINT2: ',dx,x,n,klo,khi
    print *,'  ',xa(klo),xa(khi),x-xa(klo),xa(khi)-x,eps
    stop
end if
H=XA(KHI)-XA(KLO)
IF (H.EQ.0.) then
    print *, '****Bad XA input in SPLINT2'
    stop
end if
A=(XA(KHI)-X)/H
B=(X-XA(KLO))/H
Y=A*YA(KLO)+B*YA(KHI)+((A**3-A)*Y2A(KLO)+(B**3-B)*Y2A(KHI))*(H**2)/6.
RETURN
END

! Guoqing subroutine to read in phase picks from the archive phase date files
!
      subroutine GET_PHASEPICK_MOD(infile,cuspid,sname,pick_p,qual_p,pick_s,qual_s)
      ! _MOD refers to modification by RSM 12/18/2018; to read pick times in sec relative to quake time.
      implicit none
      integer nq0                !maximum number of events
      parameter (nq0=300000)
      integer npick0             !maximum number of picks
      parameter (npick0=2500000)

      integer cuspid
      character*7 sname
      real pick_p,pick_s
      integer qual_p,qual_s

      integer iq,ipick
      integer i1,i2,i3,i4,i5,i6
      integer iflag
      integer evid,eyr,emon,edy,ehr,emn,isc
      integer iyr,imon,idy,ihr,imn,isec_p,isec_s
      integer idelkm
      integer pweig,sweig
      integer nqtot           !total number of events (output)
      integer*4 idcusp(nq0)  !array with event identification number (output)
      integer ipick1(nq0)     !array with first pick index for each event (output)
      integer ipick2(nq0)     !array with last pick index for each event (output)
      integer phweig(npick0,2)
      integer nq

      real elat,elon,edep,emag,esc
      real qlat(nq0)    !array with evetn latitude (output)
      real qlon(nq0)    !array with event longitude (output)
      real qdep(nq0)    !array with event depth (output)
      real qmag(nq0)    !array with event magnitude (output)
      real*8 t0
      real*8 tsec(nq0)  !event time (seconds since 1600) (output)
      real sec_p,sec_s
      real*8 tt_p,tt_s
      real pick(npick0,2)  !array with travel time pick for each pick (output)
      real arriv(npick0,2)
      real delkm
      real delta(npick0)
!
      character*1 chr1,chr2
      character onset,pol,comp*3
      character pha
      character*3 phinfo0
      character*100 infile         !input phase data file name (input)
      character*150 linebuf
      character*12 stname1
      character*12 stname2
      character*12 stname(npick0)   !array with station id (12 characters)
      character*3 phinfo(npick0)
!
      logical firstcall
      save firstcall,nqtot,idcusp,ipick1,ipick2,stname,arriv,phweig
      data firstcall/.true./
!
!-----------------------------------------------------------------------
!
      if (firstcall) then
         firstcall=.false.
         print *, 'GET_PHASEPICK reading phase pick file: ', trim(infile)
         open(21,file=infile,status='old')

         iq=0
         ipick=0
401      read(21,'(a)',end=101) linebuf

         if (linebuf(1:2) .eq. '19' .or. linebuf(1:2) .eq. '20') then   !Quake Line
             iflag=1
             if (iq .ne. 0) ipick2(iq)=ipick

             read (linebuf,201,err=177) eyr,emon,edy,ehr,emn,isc, &
                  i1,chr1,i2,i3,chr2,i4,i5,evid,i6
!             print 201, eyr,emon,edy,ehr,emn,isc,
!     &             i1,chr1,i2,i3,chr2,i4,i5,evid,i6
201          format (i4,4i2,i4,i2,a1,i4,i3,a1,i4,i5,100x,i10,1x,i3)

             esc=real(isc)/100.
             elat=real(i1)+real(i2)/6000.
             if (chr1.eq.'s'.or.chr1.eq.'S') elat=-elat
             elon=-(real(i3)+real(i4)/6000.)
             if (chr2.eq.'w'.or.chr2.eq.'W') elon=-elon
             edep=real(i5)/100.
             emag=real(i6)/100.

             iq=iq+1

!             print *,iq,eyr,emon,edy,ehr,emn,esc,
!     &               elat,elon,edep,emag
             if (iq.gt.nq0) then
                 print *, '***Too many events for HYPOINVERSE'
                 print *, '***Truncated at nq = ',nq0
                 stop
             end if

             qlat(iq)=elat
             qlon(iq)=elon
             qdep(iq)=edep
             qmag(iq)=emag
             call DT_TIMEDIF(1600,1,0,0,0,0., eyr,emon,edy,ehr,emn,esc,t0)
             tsec(iq)=t0

         else if (linebuf(1:4) .ne. '    ') then  !Phase Line

             if (iq.eq.0 .or. &
                linebuf(6:7).eq.'  ' .or. &
                linebuf(31:31).eq.'.' .or. &
                linebuf(32:32).eq.'.' .or. &
                linebuf(33:33).eq.'.' .or. &
                linebuf(34:34).eq.'.') go to 401

             if (iflag.eq.0) goto 401

             read (linebuf,301,err=177) stname1,phinfo0(1:3), &
                  pweig,iyr,imon,idy,ihr,imn, &
                  isec_p,isec_s,pha,sweig,idelkm
!             print 301, stname1,phinfo0(1:3),
!     &             pweig,iyr,imon,idy,ihr,imn,
!     &             isec_p,isec_s,pha,sweig,idelkm
301          format (a12,1x,a3,i1,i4,4i2,i5,7x,i5,1x,a1,1x,i1,24x,i4)

             tt_p=-999.
             tt_s=-999.
             if(isec_p.eq.9999.or.isec_p.eq.15999) then
                sec_p=-999.
             else if(phinfo0(2:2).eq.'P') then
                sec_p=real(isec_p)/100.

                call DT_TIMEDIF(eyr,emon,edy,ehr,emn,esc, &
                               iyr,imon,idy,ihr,imn,sec_p,tt_p)
                if (abs(tt_p).gt.1000.) then
                    print *,'P Timing problem, tt = ',tt_p
                    print *,eyr,emon,edy,ehr,emn,esc
                    print *,iyr,imon,idy,ihr,imn,sec_p
                    print *,linebuf
                    !stop
                endif

             endif

             if(pha.eq.'S') then
                sec_s=real(isec_s)/100.

                call DT_TIMEDIF(eyr,emon,edy,ehr,emn,esc, &
                               iyr,imon,idy,ihr,imn,sec_s,tt_s)
                if (abs(tt_s).gt.1000.) then
                    print *,'S Timing problem, tt = ',tt_s
                    print *,eyr,emon,edy,ehr,emn,esc
                    print *,iyr,imon,idy,ihr,imn,sec_s
                    print *,linebuf
                    !stop
                endif

             else
                sec_s=-999.
             endif

             delkm=real(idelkm)/10.

             stname2='            '
             stname2(1:2)=stname1(6:7)
             stname2(4:7)=stname1(1:4)
             stname2(9:12)=stname1(9:12)

             comp=stname2(7:7)
!             onset=phinfo0(1:1)          !e.g., I or E
!             pol=phinfo0(3:3)            !e.g., U or D

             if (delkm.le.0.0) goto 401

             if (phinfo0(2:2).ne.'P'.and.phinfo0(2:2).ne.'p'.and. &
                pha.ne.'S'.and.pha.ne.'s') goto 401

             ipick=ipick+1
             if(ipick.ge.npick0) then
                print *,'Increase npick0!',npick0
                stop
             endif

             delta(ipick)=delkm
             phweig(ipick,1)=pweig
             phweig(ipick,2)=sweig
             stname(ipick)=stname2
             phinfo(ipick)=phinfo0(1:3)
             pick(ipick,1)=real(tt_p)
             pick(ipick,2)=real(tt_s)
             arriv(ipick,1)=sec_p
             arriv(ipick,2)=sec_s

!             print *,iq,ipick,stname(ipick),
!     &               1,pick(ipick,1),phweig(ipick,1),arriv(ipick,1),
!     &               2,pick(ipick,2),phweig(ipick,2),arriv(ipick,2)

            else if (linebuf(1:5) .eq. '     ') then  !End of file
                 read (linebuf,'(62x,i10)') idcusp(iq)
!                 print *,idcusp(iq)
            endif

         go to 401

177      print *,linebuf
         stop
101      close(21)

         nqtot=iq
         ipick2(nqtot)=ipick
         ipick1(1)=1
         do iq=2,nqtot
            ipick1(iq)=ipick2(iq-1)+1
!            print *,iq,ipick1(iq),ipick2(iq)
         end do

      print *,'Read from pick file, nqtot= ', nqtot
      end if

      pick_p=-999.
      qual_p=-9
      pick_s=-999.
      qual_s=-9
      do 122 iq=1,nqtot
         if(cuspid.eq.idcusp(iq)) go to 222
122   continue
      print *,'phaselist CUSPID ',cuspid,' NOT FOUND !!!'
      return

222   nq=iq
      do 322 ipick=ipick1(iq),ipick2(iq)
!         print *,stname(ipick)(4:6),'**vs**',sname(1:3)
         if(stname(ipick)(4:6).eq.sname(1:3)) then

            if(pick(ipick,1).ne.-999..and. &  ! *** modified RSM 12/18/2018; changed this to pick from arriv. Think this is correct for pick time in sec relative to quake time
              pick_p.eq.-999.) then
               pick_p=pick(ipick,1)
               qual_p=phweig(ipick,1)
            endif

            if(pick(ipick,2).ne.-999..and.  &
              pick_s.eq.-999.) then
               pick_s=pick(ipick,2)
               qual_s=phweig(ipick,2)
            endif
         endif

322   continue

      return
      end


