/* this is a simplified version of Paul Henkarts diskio which allows C disk calls from fortran
 *    The following entry points are in this c program.
 * ggetfil(mode, lun, name, istat)   assigns disk files and unit numbers
 * gfrefil(lun)    releases unit
 * gpodiscb(lun, nbyte)    positions lun to byte nbyte
 * grddiscb(lun, buffer, nbytes, istat)   reads nbytes bytes from disk unit lun
 * gwrdiscb(lun, buffer, nbytes,  istat)    writes nbytes bytes to disk unit lun
 *
****   NOTE  ****   lun is an index to an array of file descriptors within this
                   subroutine, thus any I/O must be done through this subroutine
                   (since the other I/O doesn't have the file descriptor!) */

#include<stdio.h>
#include<stdlib.h>
#include <sys/stat.h>
#define   MAXFDS    40  /* the most files allowed in UNIX */
#define   PMODE     0775 /* read, write, execute for owner, read and exec for group */

void mknamc(char *nam )
/* make sure every name is followed by a null character */
{
        while( *nam != ' ' && *nam != '\0' ) nam++;
        *nam = '\0';
}

/* 0 is stdin 1 is stdout 2 is stderr 5 is fortran reader 6 is fortran printer */
static    int       fd[MAXFDS] = {0, 1, 2, -1, -1, 5, 6, -1, -1, -1,
                               -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                               -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                               -1, -1, -1, -1, -1, -1, -1, -1, -1, -1};
          off_t    offset;  /* the number of bytes to move relative to the origin */
          int       origin;
          int       nbytes;
          int       status;
          int       i;
          int creat(const char *pathname, mode_t mode);
          int close(int socket);
          int open(const char *pathname, int options, ...);
          off_t lseek(int fildes,off_t offset,int pos);
          ssize_t read(int fs, void *buf, size_t N);
          ssize_t write(int fs, const void *buf, size_t N);

void ggetfil_(int *mode, int *lun, char *name, int *istat)
/*  ggetfil keeps track of, and assigns, disk file unit numbers.  Most fortrans also have a limit as to the
largest unit number allowed. ggetfil will find an unused unit number abd return its number, as
well as assigning a disk file to the unit number
   ARGUMENTS:
    MODE   - THE TYPE OF DISK ASSIGNMENT TO MAKE. INTEGER*4
           =3,  FINDS A FREE UNIT NUMBER AND CREATES THE FILE GIVEN IN NAME TO
                THE UNIT.  NAME MUST BE GIVEN.
           =4,  Finds a free unit number and opens the existing file name. NAME
                must be given.  The file is opened for reading and writing
                unless permission is denied, in which case the file is opened
                for reading only.
    LUN     - THE FILE UNIT NUMBER. INTEGER*4, lun is set by ggetfil
    NAME    - A CHARACTER FILE NAME
    ISTAT   - The return status of the file assignment.
            =0, File opened properly.
            =-1, TOO MANY FILES ALREADY EXIST, or some problem opening file */
{
      *istat = 0;
      if(*mode > 2 ) { 
          /* find a free unit by searching fd for a -1 */
           *lun = -1;
           for (i = MAXFDS-1; fd[i] == -1 && i > 0; i--)  *lun = i;
           if ( *lun == -1 ){
               if( fd[3] == -1 ) *lun = 3;
                   else if( fd[4] == -1 ) *lun = 4 ;
               if(  *lun == -1) {
                   printf(" ***  ERROR  ***  Too many units for UNIX (%d max).\n",MAXFDS);
                   *istat = -1;
                   exit(0) ; }
                }
           mknamc( name );   /* make sure the name terminates with a NULL */
           if( *mode == 3 ) {
                status = creat( name, PMODE );   /* open with read and write privileges */
                close(status);
                status = open(name,2);  }
           if( *mode == 4 ) { status = open( name, 2);
                if( status == -1 )  status = open( name, 0);  /* open it for read only if read and write fails */
                if( status == -1 ) status = open( name, 1); }  /* open for write only if read only failed */
           if( status != -1 ) {  /* if it created successfully, then carry on */
                fd[*lun] = status ;  /* create returns the file desriptor  */
                *istat = 0;  /* tell the caller that everything is ok */
                return ;  }
           else  {   /* create didn't create! */
                    perror("getfil");
                    perror(name);
                    *istat = status ;
                    return ;  }
           }
}

void gfrefil_(int *lun )
/*  gfrefil releases and closes  the file associated with lun.  The file must have been assigned via ggetfil */
{
            status = close( fd[*lun] );
            fd[*lun] = -1;
            return;
}


void gfilsiz_(char *name, int *bsize)
{
      struct stat stbuf;
      mknamc( name );   /* make sure the name terminates with a NULL */
      stat(name, &stbuf);
      *bsize = stbuf.st_size;
      return;
}

void gpodiscb_( int *lun,  int *addres)
/*  gpodisc positions and open the disc file associated with lun.  The positioning is  to an
absolute address. The first address is 0, the second adress is 1, etc. */
{
      offset = *addres ;  /* the addres was given in units of bytes */
      origin = 0;  /* preset to origin of the beginning of the file */
      lseek( fd[*lun], offset, origin) ;
      return;
}

void grddiscb_(int *lun, int *buffer, int*n, int*istat)
/*   grddiscb reads n bytes from the disc file associated with the file on unit lun.
    buffer - The array to receive the results of the read.  Buffer must be at
             least n bytes long.
    n - The number of bytes to read into buffer.
    istat  - The return status of the read.
           >0, istat words/bytes were read into buffer (No problems).
           =-1,  An end of file was detected.
           <-1, A problem occurred.  */
{
       nbytes = *n ; 
       status = read( fd[*lun], buffer, nbytes);
       if( status < 0 ) {
              printf(" ***  ERROR  *** disc file read error on unit %d, status = %d\n",*lun,status);
              perror("rddisc"); }
       *istat = status;
       if ( *istat == 0 ) *istat = -1 ;  /* istat=-1 means end of file  */
       return;
}

void gwrdiscb_(int *lun, int *buffer, int *n, int *istat)
/*  gwrdiscb writes n bytes from buffer to the disc file associated with lun.
   buffer - The array in memory to write to disc.
   n  - The number of bytes to write to disc.
   istat  - the number of bytes written */
{
       nbytes = *n ;
       status = write( fd[*lun], buffer, nbytes);
       if( status != nbytes ) {
             printf(" ***  ERROR  ***  disc file write error on unit %d, status = %d\n",*lun,status);
             perror("wrdisc"); }
       *istat = status;
       return;
}
