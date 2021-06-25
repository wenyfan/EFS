### Example script to interact with EFS files using ObsPy.
#   Here we gather event, station, and waveform data in ObsPy format for the 
#   2019 Ridgecrest earthquake. We then create an EFS file from this information,
#   and test file export and conversion.


# Import statements
import numpy as np
import struct
import obspy
from obspy import UTCDateTime, geodetics
from EFSpy_module import *
from obspy.clients.fdsn import Client
import os

# Specify file paths
EFSPATH = "../EX_DATA/"
miniSEED_PATH = '../EX_DATA/CI/'

# Download event information for Ridgecrest using ObsPy
print("Downloading Ridgecrest event information...")
origin_time = obspy.UTCDateTime(2019, 7, 6, 3, 19, 53)
clntnm = 'IRIS'
client = Client(clntnm)
cat = client.get_events(starttime = origin_time - 20, endtime = origin_time + 20, minmagnitude = 7)
print("Done")

# Read waveforms into obspy Stream and Inventory
iPATH = miniSEED_PATH + 'waveforms/'
iPATH_inv = miniSEED_PATH + 'stations/'
try:
    st1 = obspy.read(iPATH + '*')
    inv1 = obspy.read_inventory(iPATH_inv + '*')
    print("Reading data from:", iPATH)
    print(len(st1), 'records read.')
except:
    print('Oops, no data')

# Initialize an event header for the EFS file
ehead = cat2ehead(st1,cat)
npts_max = 100000
ntr_max = 1000

# Create EFS file from Obspy
print("Creating EFS object.")
efs_data = EFS_i32_i32.from_obspy(st1, ehead, inv1)
efs_data.ehead['bytepos'] = 248 + ntr_max * 4 + 1 + np.arange(0, ntr_max) * npts_max * 4
print("Done.")

# Write EFS to file
print("Testing EFS export.")
filename = 'EFS_Example.efs'
export_efs_i32_f32(EFSPATH, filename, efs_data)
print("Done.")

# Convert EFS to obspy
print("Converting EFS object back to a stream.")
efs_data_2 = EFS_i32_f32(EFSPATH + filename)
st2 = efs_data_2.to_obspy()
print("Done.")
