'''
A Python script to check if the data conversion (original <--> EFS) is OK
usage: (do not forget quotation marks!)
python checktraces.py '../EX_DATA/EFS_Example.efs' '../EX_DATA/CI/waveforms/*'
'''

import os
import sys
import numpy as np
import obspy
from EFSpy_module import EFS
import matplotlib.pyplot as plt

def main():

    # pass arguments
    args = sys.argv
    efsname = args[1]
    original = args[2]

    # load EFS file
    efs_data = EFS(efsname)

    # load original original files
    st = obspy.read(original)

    # randomly select one station to check identity
    j = np.random.randint(0,len(st)) # random station ID
    originalTrace = st[j].copy()
    wf = efs_data.waveforms[j]

    # display station code, location, and channel
    print('EFS     :', efs_data.waveforms[j]['stname'].strip(), efs_data.waveforms[j]['loccode'].strip(), efs_data.waveforms[j]['chnm'].strip())
    print('original:', st[j].stats.station, st[j].stats.location, st[j].stats.channel)

    # judge if the two traces are identical
    if (wf['data'] == originalTrace.data).all():
        print('two traces are identical!')
    else:
        print('something wrong...')

    # plot traces
    fig, (ax1, ax2) = plt.subplots(2, 1)

    ax1.plot(wf['data'], color='k', label='EFS: '+st[j].stats.station+' station')
    ax1.plot(originalTrace.data, color='r', label='original: '+efs_data.waveforms[j]['stname'].strip()+' station')
    ax1.legend()

    ax2.plot(wf['data'] - originalTrace.data, color='C7', label='diff')
    ax2.legend()
    plt.show()

if __name__ == '__main__':
    main()
