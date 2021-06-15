#! /usr/bin/env python3.6

# R.S. Matoza December 2017
# This script demos how to use the efspy routine to read then plots waveforms
# Basically a Python version of use_efs.f90 PGPLOT routine

import numpy as np
import matplotlib.pyplot as plt
import efspy

#file = 'EFSFILT/p232453.efs' # good one
file = '60726756.efs'
myefs = efspy.readefs(file)
scl = 1.
compsel = "V"
# print number of time-series
print('Number of waveforms in EFS file: ', str(len(myefs['efswaveforms'])))

# display the file header:
print(myefs['fhead'])

# display the event header:
print(myefs['ehead'])

for i in range(0, myefs['ehead']['numts']):
    print(myefs['efswaveforms'][i])
    if (myefs['efswaveforms'][i]['chnm'][0:1] == compsel):
        r = myefs['efswaveforms'][i]['deldist']
        tpick1 = myefs['efswaveforms'][i]['pick1']+myefs['efswaveforms'][i]['tdif']
        tpick2 = myefs['efswaveforms'][i]['pick2']+myefs['efswaveforms'][i]['tdif']
        dt = myefs['efswaveforms'][i]['dt']
        npts =  myefs['efswaveforms'][i]['npts']
        t = np.arange(0,npts*dt,dt)+myefs['efswaveforms'][i]['tdif']
        apick_max = np.max(myefs['efswaveforms'][i]['data'])
        apick_min = np.min(myefs['efswaveforms'][i]['data'])
        wrec = scl*(myefs['efswaveforms'][i]['data']/apick_max) + r
        plt.plot(wrec, t, color = 'k', linewidth = 0.1)
        plt.text(r-scl/2, 55+0.1*r, myefs['efswaveforms'][i]['stname'][0:4])
        if (myefs['efswaveforms'][i]['pick1'] != 0):
            plt.plot([r-scl,r+scl],[tpick1,tpick1],'b')
        if (myefs['efswaveforms'][i]['pick2'] != 0):
            plt.plot([r-scl,r+scl],[tpick2,tpick2],'r')



plt.xlabel('Dist [km]', fontsize=14)
plt.ylabel('Time [sec]', fontsize=14)

plt.show()



