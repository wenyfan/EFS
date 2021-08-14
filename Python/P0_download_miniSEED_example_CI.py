### Example using ObsPy download miniseed data of the 2019 M7.1 Ridgecrest earthquake
# starting time as 1 min before the origin time and 5 mins after the origin time
# BHZ component, Southern California network
# 2019-07-06 03:19:53 (UTC)

# import statements
import obspy
from obspy.clients.fdsn.mass_downloader import CircularDomain, \
    Restrictions, MassDownloader
from obspy.clients.fdsn import Client
import os

# define search domain
domain = CircularDomain(latitude=35.77, longitude=-117.599,
                        minradius=0.0, maxradius=90.0)

# specify origin time
origin_time = obspy.UTCDateTime(2019, 7, 6, 3, 19, 53)

# specify download parameters
restrictions = Restrictions(
    starttime=origin_time - 1 * 60,
    endtime=origin_time + 5*60,
    network="CI", station="*", location="",
    channel_priorities=["HHZ", "BHZ"],
    reject_channels_with_gaps=False,
    minimum_length=0.95,
    minimum_interstation_distance_in_m=100.0)

# instantiate mass downloader
mdl = MassDownloader()

# prepare storages
mseed_storage = '../EX_DATA/CI/waveforms'
stationxml_storage = '../EX_DATA/CI/stations'
os.makedirs(mseed_storage, exist_ok=True)
os.makedirs(stationxml_storage, exist_ok=True)

# download data
print("Downloading data, please wait...")
print("(Note, no changes will be made if data does not need to be updated).")
mdl.download(domain,restrictions, mseed_storage=mseed_storage,
             stationxml_storage=stationxml_storage)
print("\nDONE")
