import obspy
from obspy.clients.fdsn.mass_downloader import CircularDomain, \
    Restrictions, MassDownloader
from obspy.clients.fdsn import Client

domain = CircularDomain(latitude=35.77, longitude=-117.599,
                        minradius=0.0, maxradius=90.0)

# download miniseed data of the 2019 M7.1 Ridgecrest earthquake
# starting time as 1 min before the origin time and 5 mins after the origin time
# BHZ component, Southern California network
# 2019-07-06 03:19:53 (UTC)

origin_time = obspy.UTCDateTime(2019, 7, 6, 3, 19, 53)

restrictions = Restrictions(
    # Get data for a whole year.
    starttime=origin_time - 1 * 60,
    endtime=origin_time + 5*60,
    network="CI", station="*", location="",
    channel_priorities=["HHZ", "BHZ"],
    reject_channels_with_gaps=False,
    minimum_length=0.95,
    minimum_interstation_distance_in_m=100.0)

mdl = MassDownloader()

mdl.download(domain,restrictions, mseed_storage="/Users/wenyuanfan/Research/EFS/miniSEED/CI/waveforms/",
             stationxml_storage="/Users/wenyuanfan/Research/EFS/miniSEED/CI/stations/")

