'''
fetchFnet: Request, dwnload, and pre-process F-net data
author: Ryo Okuwaki (rokuwaki@geol.tsukuba.ac.jp)
date: Fri Aug 13 11:55:46 BST 2021
usage:

from fetchFnet import fetchFnet
fetch = fetchFnet(username='USERNAME', # use your own
                  passwd='PASSEWORD',  # use your own
                  iyear=2011,
                  imonth=3,
                  iday=11,
                  ihour=5,
                  iminute=46,
                  isecond=24,
                  before_origin_sec=1*60,
                  after_origin_sec=5*60,
                  component='LHZ',
                  path='../EX_DATA/Fnet')
fetch.fetch()


You need to register at https://hinetwww11.bosai.go.jp/auth/?LANG=en to get username and password
- username, passwd = 'USERNAME', 'PASSEWORD'

Origin time is defined as:
- datetime(iyear, imonth, iday, ihour, iminute, isecond)

Duration of data stream (sec)
- {origin time - before_origin_sec} : {origin time + after_origin_sec}

You can specify any chennels you want; e.g., 'LHN', 'BHZ', but only one component at once
- component = 'LHZ'

A path for storing SAC files
- path = '../EX_DATA/Fnet'

'''

import io
import os
import re
import sys
import glob
import obspy
import zipfile
import requests
import calendar
import numpy as np
from datetime import datetime, date, timedelta
from obspy.core.utcdatetime import UTCDateTime

class fetchFnet():
    def __init__(
        self,
        username,
        passwd,
        iyear,
        imonth,
        iday,
        ihour,
        iminute,
        isecond,
        component,
        before_origin_sec,
        after_origin_sec,
        path
        ):

        self.username = username
        self.passwd = passwd
        self.iyear = iyear
        self.imonth = imonth
        self.iday = iday
        self.ihour = ihour
        self.iminute = iminute
        self.isecond = isecond
        self.component = component
        self.before_origin_sec = before_origin_sec
        self.after_origin_sec = after_origin_sec
        self.path = path


    def fetch(self):

        year  = self.iyear
        month = self.imonth
        day = self.iday
        hour = self.ihour
        minute = self.iminute
        second = self.isecond
        starttime = datetime(year, month, day, hour, minute, second) - timedelta(seconds=self.before_origin_sec)

        outdir = os.path.join(self.path)
        os.makedirs(outdir, exist_ok=True)

        print(datetime.now().strftime("%Y-%m-%d %H:%M:%S"), '1/5 Downloading raw SAC... ', outdir)

        duration_in_seconds = int(self.before_origin_sec + self.after_origin_sec)
        fetchandprocess(starttime, duration_in_seconds, outdir, self.component, self.username, self.passwd)

        print(datetime.now().strftime("%Y-%m-%d %H:%M:%S"), '5/5 Removing instrumental response to nm/s... ')
        st = obspy.read(outdir+'/*_LH?') # if you want to convert only vertical comp., then specify outdir+'/*_LHZ'

        for i in range(len(st)):
            station_name = st[i].stats['station']
            channel = st[i].stats['channel']
            location = st[i].stats['location']
            npts = st[i].stats['npts']
            if npts != duration_in_seconds:
                print('              ', station_name, 'is lacking data, npts is', npts)
            else:
                trace = st[i].copy()
                #print(trace.stats['station'], trace.stats['channel'], trace.stats['location'])
                pazfile = outdir+'/'+station_name+'_'+channel+'.zp'
                obspy.io.sac.attach_paz(trace, pazfile)
                pazinfo=trace.stats.paz

                # Default paz is velocity (m/s) responce for F-net data (STS-1 seismometer).
                # This is different from what is written in SAC's manual for `transfer`;
                #      "... as dafult setting, `to NONE` recognizes response as `displacement (nm)`".
                trace.simulate(paz_remove=pazinfo)
                trace.data *= 1e9 # from "meter per second" to "nano meter per second"
                trace.write(outdir+'/F.'+station_name+'.'+location +'.'+channel+'.SAC', format='SAC')

        print(datetime.now().strftime("%Y-%m-%d %H:%M:%S"), 'All done!', len(glob.glob(outdir+'/*.SAC')), 'SAC files are processed.')
        print('#############################################################################')


def fetchandprocess(starttime, duration_in_seconds, outdir, component, username, passwd):

    FNET = 'https://www.fnet.bosai.go.jp/auth/dataget/'
    DATAGET = FNET + 'cgi-bin/dataget.cgi'
    DATADOWN = FNET + 'dlDialogue.php'
    session = requests.Session()
    session.auth = (username, passwd)
    timeout = 120
    format = 'SAC'
    station = 'ALL'
    component = component
    time = 'UT'

    starttime = starttime
    duration_in_seconds = duration_in_seconds
    outdir = outdir

    data = {
        's_year': starttime.strftime('%Y'),
        's_month': starttime.strftime('%m'),
        's_day': starttime.strftime('%d'),
        's_hour': starttime.strftime('%H'),
        's_min': starttime.strftime('%M'),
        's_sec': starttime.strftime('%S'),
        'end': 'duration',
        'sec': duration_in_seconds,
        'format': format,
        'archive': 'zip',  # alawys use ZIP format (to get response file `*.zp`)
        'station': station,
        'component': component,
        'time': time,
    }

    print(datetime.now().strftime("%Y-%m-%d %H:%M:%S"), '2/5 Checking request status...')
    r = session.post(DATAGET, auth=session.auth, data=data)
    if r.status_code == 401:  # username is OK, password is wrong
        sys.exit('Unauthorized! Please check your username and password!')
    elif r.status_code == 500:  # internal server error, or username is wrong
        sys.exit('Internal server error! Or you are using the wrong username!')
    elif r.status_code != 200:
        sys.exit('Something wrong happened! Status code = %d' % (r.status_code))

    m = re.search(r'dataget\.cgi\?data=(NIED_\d+\.zip)&', r.text)
    if m:
        data_id = m.group(1)
    else:
        sys.stderr.write(r.text)
        sys.exit('Error in parsing HTML!')

    print(datetime.now().strftime("%Y-%m-%d %H:%M:%S"), '3/5 Requesting data (this may take some time) ...')
    try:
        r = session.get(DATAGET + "?data=" + data_id, auth=session.auth, timeout=timeout)
        if 'Our data server is very busy now.' in r.text:
            print(r.text)
            sys.exit()
    except requests.exceptions.Timeout as e:
        print(e)
        print('Try changing parameter: timeout')
        sys.exit()


    print(datetime.now().strftime("%Y-%m-%d %H:%M:%S"), '4/5 Downloading data (zip file)...')
    try:
        r = session.get(DATADOWN + '?_f=' + data_id, auth=session.auth, stream=True, timeout=timeout)
        if r.text == 'Could not open your requested file.':
            print(r.text)
            sys.exit()
    except requests.exceptions.Timeout as e:
        print(e)
        print('Try changing parameter: timeout')
        sys.exit()

    z = zipfile.ZipFile(io.BytesIO(r.content))
    for f in z.filelist:
        if f.file_size == 0:
            print('Caution!! ', f.filename, ' has no data.')
        else:
            z.extract(f.filename, outdir)
