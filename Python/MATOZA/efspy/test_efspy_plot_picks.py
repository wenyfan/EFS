#! /usr/bin/env python3.6

# R.S. Matoza December 2017
# This script demos how to use the efspy routine to read then plots waveforms
# Basically a Python version of use_efs.f90 PGPLOT routine

import numpy as np
import matplotlib.pyplot as plt
import efspy

file = 'p60825101.efs'
myefs = efspy.readefs(file)

# print number of time-series
print('Number of waveforms in EFS file: ', str(len(myefs['efswaveforms'])))

# display the file header:
print(myefs['fhead'])

# display the event header:
print(myefs['ehead'])

for i in range(0, myefs['ehead']['numts']):
    print(myefs['efswaveforms'][i])
    dt = myefs['efswaveforms'][i]['dt']
    npts =  myefs['efswaveforms'][i]['npts']
    t = np.arange(0,npts*dt,dt)
    tpick =  myefs['efswaveforms'][i]['pick1']
    apick_max = np.max(myefs['efswaveforms'][i]['data'])
    apick_min = np.min(myefs['efswaveforms'][i]['data'])
    plt.plot(t, myefs['efswaveforms'][i]['data'], color = 'k', linewidth = 0.5)
    plt.plot([tpick,tpick], [apick_min, apick_max], 'b--', linewidth = 0.5)
    titlestr =  "cuspid: " + str(myefs['ehead']['cuspid']) + "    " \
                + myefs['efswaveforms'][i]['stname'].strip() + " " + \
                myefs['efswaveforms'][i]['chnm'].strip()
    plt.title(titlestr, fontsize=16)
    plt.ylabel('amp (counts)', fontsize=14)
    plt.xlabel('Time [sec]', fontsize=14)
    plt.show()
    strin = input('Hit enter to continue; enter 0 to quit: ')
    if not strin:
        continue
    elif(int(strin) == 0):
        print('Quitting')
        break





