/* The following wapping routines may have come from Kris Walker */
int swapint_(int *n)
{
   unsigned char *cptr,tmp;
   cptr = (unsigned char *)n;
   tmp = cptr[0];
   cptr[0] = cptr[3];
   cptr[3] = tmp;
   tmp = cptr[1];
   cptr[1] = cptr[2];
   cptr[2] = tmp;
   return 0;
}

int swapreal_(float *n)
{
   unsigned char *cptr,tmp;
   cptr = (unsigned char *)n;
   tmp = cptr[0];
   cptr[0] = cptr[3];
   cptr[3] =tmp;
   tmp = cptr[1];
   cptr[1] = cptr[2];
   cptr[2] = tmp;
   return 0;
}

