! test program to copy efs file

program copyefs
   use EFS_MODULE
   implicit none
         
   integer :: lun1, lun2, its1, its2
   character (len = 100) :: name1, name2 
   
   type(eheader) :: ehead1, ehead2
   
   type(tsheader) :: tshead1, tshead2
   
   real, dimension(500000) :: x
   
   
   print *, 'Enter input EFS file name'
   read (*, '(a)') name1
   
   print *, 'Enter output EFS file name'
   read (*, '(a)') name2
   
   call EFS_OPEN_OLD(lun1, name1)
   
   call EFS_READ_EHEAD(lun1,ehead1)
   
   call EFS_OPEN_NEW(lun2, name2)
   
   ehead2 = ehead1
   
   call EFS_WRITE_EHEAD(lun2,ehead2) 
   
   do its1 = 1, ehead1%numts
   
      call EFS_READ_HEADTS(lun1, its1, tshead1, x)
      
      tshead2 = tshead1
      
      call EFS_WRITE_TSHEAD(lun2, its2, tshead2)
      
      call EFS_WRITE_TS(lun2, tshead2%npts, x)
      
   enddo
   
   call EFS_CLOSE(lun1)
   
   call EFS_UPDATE_EHEAD(lun2, ehead2)
   
   call EFS_CLOSE(lun2)
   
           
end program copyefs

