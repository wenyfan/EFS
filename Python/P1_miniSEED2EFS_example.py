import numpy as np
import struct
import obspy

from obspy import UTCDateTime , geodetics
from EFSpy_module import *
from obspy.clients.fdsn import Client
import os

EFSPATH = "/Users/wenyuanfan/Documents/GitHub/EFS/EX_DATA/"
miniSEED_PATH = '/Users/wenyuanfan/Research/EFS/miniSEED/CI/'

origin_time = obspy.UTCDateTime(2019 , 7 , 6 , 3 , 19 , 53)

clntnm = 'IRIS'
client = Client(clntnm)
cat = client.get_events(starttime=origin_time - 20 , endtime=origin_time + 20 , minmagnitude=7)

iPATH = miniSEED_PATH + 'waveforms/'
iPATH_inv = miniSEED_PATH + 'stations/'
try :
    st1 = obspy.read(iPATH + '*')
    inv1 = obspy.read_inventory(iPATH_inv + '*')
    print(iPATH)
    print(len(st1) , 'records')
except :
    print('Oops, no data')

npts_max = 100000
ntr_max = 1000
ehead = { }
ehead[ 'efslabel' ] = "{:<40}".format(' ')
ehead[ 'datasource' ] = "{:<40}".format('miniSEED')
ehead[ 'maxnumts' ] = 1000
ehead[ 'numts' ] = len(st1)
ehead[ 'cuspid' ] = 0
ehead[ 'qtype' ] = "{:<4}".format(' ')
ehead[ 'qmag1type' ] = cat[ 0 ].magnitudes[ 0 ].magnitude_type
ehead[ 'qmag2type' ] = "{:<4}".format(' ')
ehead[ 'qmag3type' ] = "{:<4}".format(' ')
ehead[ 'qmomenttype' ] = "{:<4}".format(' ')
ehead[ 'qlocqual' ] = "{:<4}".format(' ')
ehead[ 'qfocalqual' ] = "{:<4}".format(' ')
ehead[ 'qlat' ] = cat[ 0 ].origins[ 0 ].latitude
ehead[ 'qlon' ] = cat[ 0 ].origins[ 0 ].longitude
ehead[ 'qdep' ] = cat[ 0 ].origins[ 0 ].depth
ehead[ 'qsc' ] = cat[ 0 ].origins[ 0 ].time.second
ehead[ 'qmag1' ] = cat[ 0 ].magnitudes[ 0 ].mag
ehead[ 'qmag2' ] = 0
ehead[ 'qmag3' ] = 0
ehead[ 'qmoment' ] = 0
ehead[ 'qstrike' ] = 0
ehead[ 'qdip' ] = 0
ehead[ 'qrake' ] = 0
ehead[ 'qyr' ] = cat[ 0 ].origins[ 0 ].time.year
ehead[ 'qmon' ] = cat[ 0 ].origins[ 0 ].time.month
ehead[ 'qdy' ] = cat[ 0 ].origins[ 0 ].time.day
ehead[ 'qhr' ] = cat[ 0 ].origins[ 0 ].time.hour
ehead[ 'qmn' ] = cat[ 0 ].origins[ 0 ].time.minute

efs_data = EFS.from_obspy(st1 , ehead , inv1)
efs_data.ehead[ 'bytepos' ] = 248 + ntr_max  * 4 + 1 + np.arange(0 , ntr_max) * npts_max * 4


#
filename = 'EFS_Example.efs'
export_efs ( EFSPATH , filename , efs_data )

efs_data_2 = EFS(EFSPATH+filename)
st2 = efs_data_2.to_obspy()
