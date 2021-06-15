#! /usr/bin/env python3.6

"""
Use EFS data with Python and ObsPy
Written by R.S. Matoza December 2017

readefs began as a Python port of Janine's load_efs.m

see efs.readme for EFS file format description
The EFS file is imported into a length-3 dictionary efsout

The dictionary keys are: fhead, ehead, and efswaveforms

# Example useage:
file = '363496.efs'
myefs = efspy.readefs(file)

# access the file header:
myefs['fhead']

# access the event header:
myefs['ehead']

# access the tsheader for the 1st waveform:
myefs['efswaveforms'][0]

# access waveform data for the 1st waveform:
myefs['efswaveforms'][0]['data']

# access the number of time-series (waveforms):
myefs['ehead']['numts']

# Convert to an ObsPy stream:

st = efspy.efs2stream(myefs)

"""

import numpy as np
import struct
from obspy import UTCDateTime, Trace, Stream

def readefs(efsfname):
    # Read an EFS binary file into a dictionary (see above)
    
    # Open the EFS binary file
    f = open(efsfname, 'rb')
    efswaveforms = [] # list to store seismograms

    # fhead
    bytetype = struct.unpack('i', f.read(4))[0]
    eheadtype = struct.unpack('i', f.read(4))[0]
    nbytes_ehead = struct.unpack('i', f.read(4))[0]
    tsheadtype = struct.unpack('i', f.read(4))[0]
    nbytes_tshead = struct.unpack('i', f.read(4))[0]

    fhead = {'bytetype': bytetype, 'eheadtype': eheadtype, 'nbytes_ehead': nbytes_ehead,
             'tsheadtype': tsheadtype, 'nbytes_tshead': nbytes_tshead}

    # ehead
    efslabel = f.read(40).decode('UTF-8')
    datasource = f.read(40).decode('UTF-8')
    maxnumts = struct.unpack('i', f.read(4))[0]
    numts = struct.unpack('i', f.read(4))[0]
    cuspid = struct.unpack('i', f.read(4))[0]

    qtype = f.read(4).decode('UTF-8')
    qmag1type = f.read(4).decode('UTF-8')
    qmag2type = f.read(4).decode('UTF-8')
    qmag3type = f.read(4).decode('UTF-8')
    qmomenttype = f.read(4).decode('UTF-8')
    qlocqual = f.read(4).decode('UTF-8')
    qfocalqual = f.read(4).decode('UTF-8')

    qlat = struct.unpack('f', f.read(4))[0]
    qlon = struct.unpack('f', f.read(4))[0]
    qdep = struct.unpack('f', f.read(4))[0]
    qsc = struct.unpack('f', f.read(4))[0]
    qmag1 = struct.unpack('f', f.read(4))[0]
    qmag2 = struct.unpack('f', f.read(4))[0]
    qmag3 = struct.unpack('f', f.read(4))[0]
    qmoment = struct.unpack('f', f.read(4))[0]
    qstrike = struct.unpack('f', f.read(4))[0]
    qdip = struct.unpack('f', f.read(4))[0]
    qrake = struct.unpack('f', f.read(4))[0]

    qyr = struct.unpack('i', f.read(4))[0]
    qmon = struct.unpack('i', f.read(4))[0]
    qdy = struct.unpack('i', f.read(4))[0]
    qhr = struct.unpack('i', f.read(4))[0]
    qmn = struct.unpack('i', f.read(4))[0]

    ehead = {'efslabel': efslabel, 'datasource': datasource, 'maxnumts': maxnumts,
        'numts': numts, 'cuspid': cuspid, 'qtype': qtype, 'qmag1type': qmag1type,
        'qmag2type': qmag2type, 'qmag3type': qmag3type, 'qmomenttype': qmomenttype,
        'qlocqual': qlocqual, 'qfocalqual': qfocalqual, 'qlat': qlat, 'qlon': qlon,
        'qdep': qdep, 'qsc': qsc, 'qmag1': qmag1, 'qmag2': qmag2, 'qmag3': qmag3,
        'qmoment': qmoment, 'qstrike': qstrike, 'qdip': qdip, 'qrake': qrake,
        'qyr': qyr, 'qmon': qmon, 'qdy': qdy, 'qhr': qhr, 'qmn': qmn}

    # 20 4-byte fields reserved for future uses - skip
    for idum in range(0,20):
        dummy = struct.unpack('i', f.read(4))[0]

    # append fhead and ehead to efsout
    efsout = {'fhead': fhead, 'ehead': ehead}

    bytepos = np.fromfile(f, dtype=np.int32, count=numts)

    # now loop over all the time-series
    for ii in range(0, len(bytepos)):
        # tshead
        f.seek(bytepos[ii])
        stname = f.read(8).decode('UTF-8')
        loccode = f.read(8).decode('UTF-8')
        datasource = f.read(8).decode('UTF-8')
        sensor = f.read(8).decode('UTF-8')
        units = f.read(8).decode('UTF-8')

        chnm = f.read(4).decode('UTF-8')
        stype = f.read(4).decode('UTF-8')
        dva = f.read(4).decode('UTF-8')
        pick1q = f.read(4).decode('UTF-8')
        pick2q = f.read(4).decode('UTF-8')
        pick3q = f.read(4).decode('UTF-8')
        pick4q = f.read(4).decode('UTF-8')
        pick1name = f.read(4).decode('UTF-8')
        pick2name = f.read(4).decode('UTF-8')
        pick3name = f.read(4).decode('UTF-8')
        pick4name = f.read(4).decode('UTF-8')
        ppolarity = f.read(4).decode('UTF-8')
        problem = f.read(4).decode('UTF-8')

        npts = struct.unpack('i', f.read(4))[0]
        syr = struct.unpack('i', f.read(4))[0]
        smon = struct.unpack('i', f.read(4))[0]
        sdy = struct.unpack('i', f.read(4))[0]
        shr = struct.unpack('i', f.read(4))[0]
        smn = struct.unpack('i', f.read(4))[0]

        compazi = struct.unpack('f', f.read(4))[0]
        compang = struct.unpack('f', f.read(4))[0]
        gain = struct.unpack('f', f.read(4))[0]
        f1 = struct.unpack('f', f.read(4))[0]
        f2 = struct.unpack('f', f.read(4))[0]
        dt = struct.unpack('f', f.read(4))[0]
        ssc = struct.unpack('f', f.read(4))[0]
        tdif = struct.unpack('f', f.read(4))[0]
        slat = struct.unpack('f', f.read(4))[0]
        slon = struct.unpack('f', f.read(4))[0]
        selev = struct.unpack('f', f.read(4))[0]
        deldist = struct.unpack('f', f.read(4))[0]
        sazi = struct.unpack('f', f.read(4))[0]
        qazi = struct.unpack('f', f.read(4))[0]
        pick1 = struct.unpack('f', f.read(4))[0]
        pick2 = struct.unpack('f', f.read(4))[0]
        pick3 = struct.unpack('f', f.read(4))[0]
        pick4 = struct.unpack('f', f.read(4))[0]

        tshead = {'stname': stname, 'loccode': loccode, 'datasource': datasource,
                  'sensor': sensor, 'units': units,
                  'chnm': chnm, 'stype': stype, 'dva': dva, 'pick1q': pick1q,
                  'pick2q': pick2q, 'pick3q': pick3q, 'pick4q': pick4q,
                  'pick1name': pick1name, 'pick2name': pick2name, 'pick3name': pick3name,
                  'pick4name': pick4name, 'ppolarity': ppolarity, 'problem': problem,
                  'npts': npts, 'syr': syr, 'smon': smon, 'sdy': sdy, 'shr': shr, 'smn': smn,
                  'compazi': compazi, 'compang': compang, 'gain': gain, 'f1': f1, 'f2': f2,
                  'dt': dt, 'ssc': ssc, 'tdif': tdif, 'slat': slat, 'slon': slon, 'selev': selev,
                  'deldist': deldist, 'sazi': sazi, 'qazi': qazi,
                  'pick1': pick1, 'pick2': pick2, 'pick3': pick3, 'pick4': pick4}

        # 20 4-byte fields reserved for future uses - skip
        for idum in range(0,20):
            dummy = struct.unpack('i', f.read(4))[0]

        # Read the time-series itself
        data = np.fromfile(f, dtype='<f4', count=npts) # little-endian float32

        # bundle tsheader and time-series for this waveform into efsdata, then append to efswaveforms list
        efsdata = tshead
        efsdata['data'] = data
        efswaveforms.append(efsdata)
    efsout['efswaveforms'] = efswaveforms
    return efsout



def efs2stream(efsin):
    # Convert the EFS dictionary format to an ObsPy stream format
    # Return the stream
    for i in range(0, efsin['ehead']['numts']):
        # grab the header values from the EFS tsheader
        dt = efsin['efswaveforms'][i]['dt']
        fs = 1./dt
        delta = efsin['efswaveforms'][i]['dt']
        sampling_rate = fs
        calib = 1.0  # often set to zero in HVO waveforms
        npts = efsin['efswaveforms'][i]['npts']
        network = efsin['efswaveforms'][i]['stype'].strip()
        location = efsin['efswaveforms'][i]['loccode'].strip()
        station = efsin['efswaveforms'][i]['stname'].strip()
        channel = efsin['efswaveforms'][i]['chnm'].strip()
        yyyy = efsin['efswaveforms'][i]['syr']
        mon = efsin['efswaveforms'][i]['smon']
        day = efsin['efswaveforms'][i]['sdy']
        hr = efsin['efswaveforms'][i]['shr']
        mn = efsin['efswaveforms'][i]['smn']
        ssc = efsin['efswaveforms'][i]['ssc']
        starttime = UTCDateTime(yyyy,mon,day,hr,mn,ssc)
        
        # form the stats dictionary with default attributes
        stats = {'sampling_rate': sampling_rate, 'delta': delta, 'calib': calib,
            'npts': npts, 'network': network, 'location': location, 'station': station,
            'channel': channel, 'starttime': starttime}
        
        if (i == 0): # create the stream
            st = Stream([Trace(data=efsin['efswaveforms'][i]['data'], header=stats)])
        else:        # add to the stream
            st += Stream([Trace(data=efsin['efswaveforms'][i]['data'], header=stats)])

    return st
