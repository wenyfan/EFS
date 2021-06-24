function iosuc =write_iris2efs(efspath,efsname,irisSTR,itype)
%
% function to write MATLAB structures (from irisFetch) into EFS file format 
% based on variables in PS efs_subs.f90
% MATLAB structures are from the irisFetch structure
%
% Example:
% iosuc=write_iris2efs('filename.efs');
% iosuc is a return message
%
% IMPORTANT: station information and seismograms need to be stored in NESTED DATA
% structure as defined in irisFetch.m

% For example to plot third seismogram in structure:
% figure; plot(efsStruct.waveforms(3).data);
% or to access all station names:
% stname=[efsStruct.data.stat];
%
% 2021/03/02 WF
% 'name' needs to include '.efs'

if itype == 1
    ibytepos_type = 'int32';
    its_type = 'int32';
elseif itype == 2
    ibytepos_type = 'int32';
    its_type = 'single';
elseif itype == 3
    ibytepos_type = 'int64';
    its_type = 'int32';
elseif itype == 4
    ibytepos_type = 'int64';
    its_type = 'single';
else
    disp('Wrong data type specification.');
    disp('itype = 1, byptepos: int32, ts: int32');
    disp('itype = 2, byptepos: int32, ts: single');
    disp('itype = 3, byptepos: int64, ts: int32');
    disp('itype = 4, byptepos: int64, ts: single');
    return;
end

%%
% Data file ID
fid=fopen([efspath  efsname],'w');% fclose(fid); 
% File name (string)


%% write File HEADER INFORMATION
        
fwrite(fid,1,'int32');
fwrite(fid,1,'int32');
fwrite(fid,264,'int32');
fwrite(fid,1,'int32');
fwrite(fid,268,'int32');


%% write Event HEADER INFORMATION
efslabel = pad('MATLAB2EFS',40);
fwrite(fid,unicode2native(efslabel));
datasource = pad('irisFetch',40);
fwrite(fid,unicode2native(datasource));
fwrite(fid,5000,'int32');
fwrite(fid,length(irisSTR),'int32');
fwrite(fid,0,'int32');

% Earthquake Info
qtype = pad(' ',4);
fwrite(fid,unicode2native(qtype));
qmag1type = pad(' ',4);
fwrite(fid,unicode2native(qmag1type));
qmag2type = pad(' ',4);
fwrite(fid,unicode2native(qmag2type));
qmag3type = pad(' ',4);
fwrite(fid,unicode2native(qmag3type));
qmomenttype = pad(' ',4);
fwrite(fid,unicode2native(qmomenttype));
qlocqual = pad(' ',4);
fwrite(fid,unicode2native(qlocqual));
qfocalqual = pad(' ',4);
fwrite(fid,unicode2native(qfocalqual));

qlat = 0;
fwrite(fid,qlat,'single');
qlon = 0;
fwrite(fid,qlon,'single');
qdep = 0;
fwrite(fid,qdep,'single');
qsc = 0;
fwrite(fid,qsc,'single');
qmag1 = 0;
fwrite(fid,qmag1,'single');
qmag2 = 0;
fwrite(fid,qmag2,'single');
qmag3 = 0;
fwrite(fid,qmag3,'single');
qmoment = 0;
fwrite(fid,qmoment,'single');
qstrike = 0;
fwrite(fid,qstrike,'single');
qdip = 0;
fwrite(fid,qdip,'single');
qrake = 0;
fwrite(fid,qrake,'single');

qyr = 99;
fwrite(fid,qyr,'int32');
qmon = -99;
fwrite(fid,int32(qmon),'int32');
qdy = -99;
fwrite(fid,qdy,'int32');
qhr = -99;
fwrite(fid,qhr,'int32');
qmn = -99;
fwrite(fid,qmn,'int32');

fwrite(fid,zeros(20,1),'int32'); %dummy
ilen = 100000;
bytepos = 248+5000*4+1+[1:(length(irisSTR))]*ilen;
bytepos = int32(bytepos);
fwrite(fid,bytepos.',ibytepos_type);
% iosuc=fclose(fid); 
% return;
%% write DATA
%Pre-allocate data structure for station information and seismograms
stnum=length(bytepos); % stnum/trace number.
if stnum == length(irisSTR)
else
    disp('error: trace number does not match with station number')
end

fwrite(fid,zeros(stnum*ilen,1),'int32');
%LOOP TO write SEISMOGRAMS, STATION AND PICKING INFORMATION
for ii=1:stnum
    
%     frewind(fid);
    fseek(fid, bytepos(ii), 'bof');
    
    stname = pad(irisSTR(ii).station,8);
    fwrite(fid,unicode2native(stname));
    loccode = pad(irisSTR(ii).location,8);
    fwrite(fid,unicode2native(loccode));
    datasource = pad('',8);
    fwrite(fid,unicode2native(datasource));
    sensor = pad(irisSTR(ii).instrument,8);
    fwrite(fid,unicode2native(sensor));
    units = pad(irisSTR(ii).sensitivityUnits,8);
    fwrite(fid,unicode2native(units));

    chnm = pad(irisSTR(ii).channel,4);
    fwrite(fid,unicode2native(chnm));
    stype = pad(irisSTR(ii).network,4);
    fwrite(fid,unicode2native(stype));
    dva = pad('',4);
    fwrite(fid,unicode2native(dva));
    pick1q = pad('',4);
    fwrite(fid,unicode2native(pick1q));
    pick2q = pad('',4);
    fwrite(fid,unicode2native(pick2q));
    pick3q = pad('',4);
    fwrite(fid,unicode2native(pick3q));
    pick4q = pad('',4);
    fwrite(fid,unicode2native(pick4q));
    pick1name = pad('',4);
    fwrite(fid,unicode2native(pick1name));
    pick2name = pad('',4);
    fwrite(fid,unicode2native(pick2name));
    pick3name = pad('',4);
    fwrite(fid,unicode2native(pick3name));
    pick4name = pad('',4);
    fwrite(fid,unicode2native(pick4name));
    ppolarity = pad('',4);
    fwrite(fid,unicode2native(ppolarity));
    problem = pad('',4);
    fwrite(fid,unicode2native(problem));
    
    
    fwrite(fid,irisSTR(ii).sampleCount,'int32');
    
    tmpdate = datevec(irisSTR(ii).startTime);
    fwrite(fid,tmpdate(1),'int32');
    fwrite(fid,tmpdate(2),'int32');
    fwrite(fid,tmpdate(3),'int32');
    fwrite(fid,tmpdate(4),'int32');
    fwrite(fid,tmpdate(5),'int32');
    
    fwrite(fid,irisSTR(ii).azimuth,'single');
    compang = 0;
    fwrite(fid,compang,'single');
    gain = 0;
    fwrite(fid,gain,'single');
    f1 = 0;
    fwrite(fid,f1,'single');
    f2 = 0;
    fwrite(fid,f2,'single');
    
    fwrite(fid,1/irisSTR(ii).sampleRate,'single');
    fwrite(fid,tmpdate(6),'single');
    tdif = 0;
    fwrite(fid,tdif,'single');
    fwrite(fid,irisSTR(ii).latitude,'single');
    fwrite(fid,irisSTR(ii).longitude,'single');
    fwrite(fid,irisSTR(ii).elevation,'single');
    deldist = 0;
    fwrite(fid,deldist,'single');
    fwrite(fid,irisSTR(ii).azimuth,'single');
    qazi = 0;
    fwrite(fid,qazi,'single');
    pick1 = 0;
    fwrite(fid,pick1,'single');
    pick2 = 0;
    fwrite(fid,pick2,'single');
    pick3 = 0;
    fwrite(fid,pick3,'single');
    pick4 = 0;
    fwrite(fid,pick4,'single');
    
    fwrite(fid,zeros(20,1),'int32'); %dummy
    fwrite(fid,irisSTR(ii).data,its_type); %data

    
end

    
iosuc=fclose(fid);
