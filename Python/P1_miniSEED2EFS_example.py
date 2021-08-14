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
EFSPATH = "../EX_DATA"
miniSEED_PATH = '../EX_DATA/CI'

# Download event information for Ridgecrest using ObsPy
print("\nDownloading Ridgecrest event information...")
origin_time = obspy.UTCDateTime(2019, 7, 6, 3, 19, 53)
clntnm = 'IRIS'
client = Client(clntnm)
cat = client.get_events(starttime = origin_time - 20, endtime = origin_time + 20, minmagnitude = 7)
print("Done\n")

# Read waveforms into obspy Stream and Inventory
iPATH = os.path.join(miniSEED_PATH, 'waveforms')
iPATH_inv = os.path.join(miniSEED_PATH, 'stations')
try:
    st1 = obspy.read(os.path.join(iPATH, '*'))
    inv1 = obspy.read_inventory(os.path.join(iPATH_inv, '*'))
    print("Reading data from:", iPATH)
    print(st1)
    print("First trace:")
    print(st1[0].data)
except:
    print('Oops, no data')

# Initialize an event header for the EFS file
ehead = cat2ehead(st1,cat)
npts_max = 100000 # set max points per trace in file
ntr_max = 1000 # set max number of traces in file

# Create EFS file from Obspy
print("\nCreating EFS object.")
efs_data = EFS.from_obspy(st1, ehead, inv1)
efs_data.ehead['bytepos'] = 248 + ntr_max * 4 + 1 + np.arange(0, ntr_max) * npts_max * 4
print("Done.")

# Write EFS to file
print("\nTesting EFS export.")
filename = 'EFS_Example.efs'
# save arrays as default f32 precision, bytepos as i32
export_efs(EFSPATH, filename, efs_data,np.float32,"i")
filename2 = 'EFS_Example2.efs'
# save arrays as i32 precision, bytepos as i32
export_efs(EFSPATH, filename2, efs_data,np.int32,"i")
print("Done.")

# Read EFS with customized precision as they were stored
efs_data_2 = EFS(os.path.join(EFSPATH, filename),np.float32,np.int32)
efs_data_3 = EFS(os.path.join(EFSPATH, filename2),np.int32,np.int32)
# Convert EFS to obspy
print("\nConverting EFS object back to a stream.")
st2 = efs_data_2.to_obspy()
st3 = efs_data_3.to_obspy()
