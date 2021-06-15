#! /usr/bin/env python3.6

# R.S. Matoza December 2017
# This script demos how to use the efspy routine to read then convert to ObsPy Stream
# Finishes by exporting the stream to a series of SAC format files

import numpy as np
import efspy

file = '363496.efs'
efs = efspy.readefs(file)
st = efspy.efs2stream(efs)

for i in range(0,len(st)):
    fname = "HVO." + st[i].stats.station + "." + st[i].stats.channel + ".SAC"
    st[i].write(fname,format="SAC")



