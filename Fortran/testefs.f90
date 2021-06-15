! program to test efs subroutines

program testefs
   use EFS_MODULE
   implicit none
         
   integer :: lun, maxnumts, i, npts, itrace, its
   character (len = 100) :: name 
   
   type(eheader) :: ehead
   
   type(tsheader) :: tshead, tshead0
   
   real, dimension(5000) :: x
   

   maxnumts = 1000                   
   call EFS_TESTINIT_EHEAD(maxnumts, ehead)
   call EFS_TESTINIT_TSHEAD(tshead0)
   npts = tshead0%npts
   print *,'npts = ',npts   
      
   name = 'testfile.efs'
   
   call EFS_OPEN_NEW(lun, name)
   
   call EFS_WRITE_EHEAD(lun,ehead)
   print *,'lastbyte = ',lastbyte(lun)
   
   do itrace = 1, 5

      tshead = tshead0   
      call EFS_WRITE_TSHEAD(lun,its,tshead)
      print *,'Time series written, its = ',its
      
      do i = 1,npts
         x(i) = real(i)+real(its)/10.
      enddo
      
      call EFS_WRITE_TS(lun, npts, x)
            
   enddo
   
   print *,'lastbyte = ',lastbyte(lun)
            
   call EFS_UPDATE_EHEAD(lun,ehead)   
   
   call EFS_CLOSE(lun)
   
   print *,'Closed file.  Now reading file'
   print *, ' '   
   
   call EFS_OPEN_OLD(lun, name)
   
   call EFS_READ_EHEAD(lun,ehead)   
      
   call EFS_LIST_EHEAD(ehead)
   
   
   do its = 5, 1, -1
      print *,' '
      print *,'Now reading its = ',its
      if (its > 3 ) then
         print *,' using EFS_READ_HEADTS'
         call EFS_READ_HEADTS(lun, its, tshead, x)
      else
         print *,' using EFS_READ_TSHEAD and EFS_READ_TS'
         call EFS_READ_TSHEAD(lun, its, tshead)
         npts = tshead%npts
         call EFS_READ_TS(lun, its, npts, x)     
      endif
      
      call EFS_LIST_TSHEAD(tshead)       
      print *,'first 5 data points follow'
      do i=1,5
         print *,x(i)
      enddo
   
   enddo
   
   
   call EFS_CLOSE(lun)       
            
           
end program testefs

