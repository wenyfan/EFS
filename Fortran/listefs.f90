! program to list efs headers

program listefs
   use EFS_MODULE
   implicit none
         
   integer :: lun, npts, its, nts
   character (len = 100) :: filename 
   type(eheader) :: ehead  
   type (tsheader) :: tshead
      
   print *,'Enter efs file name'
   read (*,'(a)') filename

   call EFS_OPEN_OLD(lun, filename)
   
   call EFS_READ_EHEAD(lun,ehead)
   print *, ' '
   print *,'File header follows:'
   call EFS_LIST_EHEAD(ehead)

   print *,' '
   
   nts = ehead%numts
   
   do its = 1, nts
   
      call EFS_READ_TSHEAD(lun,its,tshead)
!      print *,' '
!      print *,'tshead follows for its = ',its
!      call EFS_LIST_TSHEAD(tshead)

      print 101, its,tshead%npts,tshead%dt,tshead%stname,tshead%chnm,&
         tshead%stype, tshead%loccode,tshead%datasource,tshead%f1,tshead%f2, &
         tshead%syr,tshead%smon,tshead%sdy,tshead%shr,tshead%smn,tshead%ssc, &
         tshead%tdif,tshead%slat,tshead%slon,tshead%selev, &
         tshead%del,tshead%sazi,tshead%qazi, &
         tshead%pick1,tshead%pick1q,tshead%pick1name, &
         tshead%pick2,tshead%pick2q,tshead%pick2name, &
         tshead%pick3,tshead%pick3q,tshead%pick3name, &
         tshead%pick4,tshead%pick4q,tshead%pick4name, &
         tshead%ppolarity,tshead%problem
101      format (i5,i9,f7.3,1x,a8,1x,a4,1x, &
                 a4,1x,a8,1x,a8,2f7.3, &
                 i5,4i3,f6.2, &
                 f10.1,f9.1,f9.1,f8.3, &
                 f8.1,2f6.1, &
                 4(f6.2,1x,a4,1x,a4), &
                 a4,1x,a4)
   enddo      
   
   call EFS_CLOSE(lun)                   
           
end program listefs

