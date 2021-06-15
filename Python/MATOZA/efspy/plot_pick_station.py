#! /usr/bin/env python3.6

# R.S. Matoza December 2017
# This script demos how to use the efspy routine to read then plots waveforms
# Basically a Python version of use_efs.f90 PGPLOT routine


       
import numpy as np
import matplotlib.pyplot as plt
import sys
sys.path.append('/Users/rmatoza/Repos/efspy')
import efspy

evfile = "evlist.2016.200t"
efspath = "/Volumes/YASUR_EXT2/HVO_EFS/EFSFILT/"

stasel = "AHUD"
compsel = "V"
scl = 0.5
vred = 6.5 # reduction velocity [km/s]

itrace = 0
with open(evfile, 'r') as filein:
    for line in filein:
        columns = line.split()
        cuspid = int(columns[0])
        year = int(columns[1])
        mon = int(columns[2])
        file = efspath + str(year) + "/" + str(mon).zfill(2) + "/p" + str(cuspid) + ".efs"
        print(file)

        myefs = efspy.readefs(file)
        distmax = 100. # max dist [km]
        # print number of time-series
        #print('Number of waveforms in EFS file: ', str(len(myefs['efswaveforms'])))

        # display the file header:
        #print(myefs['fhead'])

        # display the event header:
        #print(myefs['ehead'])
 
        # find the desired station and channel
        ksta = -99
        for i in range(0, myefs['ehead']['numts']):
            if(myefs['efswaveforms'][i]['stname'][0:4] == stasel[0:4]):
                if (myefs['efswaveforms'][i]['chnm'][0:1] == compsel):
                    ksta = i

        if (ksta==-99):
            print("Station and component not found")
            continue
    
        itrace += 1

        print(myefs['efswaveforms'][ksta])
            
        r = myefs['efswaveforms'][ksta]['deldist']
        if (r > distmax): continue

        tpick1 = myefs['efswaveforms'][ksta]['pick1']+myefs['efswaveforms'][ksta]['tdif']
        tpick2 = myefs['efswaveforms'][ksta]['pick2']+myefs['efswaveforms'][ksta]['tdif']
        dt = myefs['efswaveforms'][ksta]['dt']
        npts =  myefs['efswaveforms'][ksta]['npts']
        t = np.arange(0,npts*dt,dt)+myefs['efswaveforms'][ksta]['tdif']
        apick_max = np.max(myefs['efswaveforms'][ksta]['data'])
        apick_min = np.min(myefs['efswaveforms'][ksta]['data'])
        wplot = scl*(myefs['efswaveforms'][ksta]['data']/apick_max)
        plt.plot(wplot+itrace, t-(r/vred), color = 'k', linewidth = 1)
        if (myefs['efswaveforms'][ksta]['pick1'] != 0):
            plt.plot([itrace-scl,scl+itrace],[tpick1-(r/vred),tpick1-(r/vred)],'b')
        if (myefs['efswaveforms'][ksta]['pick2'] != 0):
            plt.plot([itrace-scl,scl+itrace],[tpick2-(r/vred),tpick2-(r/vred)],'r')



plt.xlabel('Trace number', fontsize=14)
plt.ylabel('Time [sec]', fontsize=14)

plt.show()



