function iosuc =write_structure2efs(efspath,efsname,efsStruct)
%
% function to write MATLAB structures into EFS file format 
% based on variables in PS efs_subs.f90
% MATLAB structures are from the load_efs structure
%
% Example:
% iosuc=write_structure2efs('filename.efs');
% iosuc is a return message
%
% IMPORTANT: station information and seismograms are stored in NESTED DATA
% structure.
% For example to plot third seismogram in structure:
% figure; plot(efsStruct.waveforms(3).data);
% or to access all station names:
% stname=[efsStruct.data.stat];
%
% 2021/03/03 WF
% 'name' needs to include '.efs'
%%
% Data file ID
fid=fopen([efspath  efsname],'w');% fclose(fid); 
% File name (string)


%% write File HEADER INFORMATION
        
fwrite(fid,efsStruct.fhead.byteype,'int32');
fwrite(fid,efsStruct.fhead.eheadtype,'int32');
fwrite(fid,efsStruct.fhead.nbytes_ehead,'int32');
fwrite(fid,efsStruct.fhead.tsheadtype,'int32');
fwrite(fid,efsStruct.fhead.nbytes_tshead,'int32');


%% write Event HEADER INFORMATION
efslabel = pad(efsStruct.ehead.efslabel,40);
fwrite(fid,unicode2native(efslabel));
datasource = pad('efsStructure',40);
fwrite(fid,unicode2native(datasource));
fwrite(fid,efsStruct.ehead.maxnumts,'int32');
fwrite(fid,efsStruct.ehead.numts,'int32');
fwrite(fid,efsStruct.ehead.cuspid,'int32');

% Earthquake Info
qtype = pad(efsStruct.ehead.qtype,4);
fwrite(fid,unicode2native(qtype));
qmag1type = pad(efsStruct.ehead.qmag1type,4);
fwrite(fid,unicode2native(qmag1type));
qmag2type = pad(efsStruct.ehead.qmag2type,4);
fwrite(fid,unicode2native(qmag2type));
qmag3type = pad(efsStruct.ehead.qmag3type,4);
fwrite(fid,unicode2native(qmag3type));
qmomenttype = pad(efsStruct.ehead.qmomenttype,4);
fwrite(fid,unicode2native(qmomenttype));
qlocqual = pad(efsStruct.ehead.qlocqual,4);
fwrite(fid,unicode2native(qlocqual));
qfocalqual = pad(efsStruct.ehead.qfocalqual,4);
fwrite(fid,unicode2native(qfocalqual));

qlat = efsStruct.ehead.qlat;
fwrite(fid,qlat,'single');
qlon = efsStruct.ehead.qlon;
fwrite(fid,qlon,'single');
qdep = efsStruct.ehead.qdep;
fwrite(fid,qdep,'single');
qsc = efsStruct.ehead.qsc;
fwrite(fid,qsc,'single');
qmag1 = efsStruct.ehead.qmag1;
fwrite(fid,qmag1,'single');
qmag2 = efsStruct.ehead.qmag2;
fwrite(fid,qmag2,'single');
qmag3 = efsStruct.ehead.qmag3;
fwrite(fid,qmag3,'single');
qmoment = efsStruct.ehead.qmoment;
fwrite(fid,qmoment,'single');
qstrike = efsStruct.ehead.qstrike;
fwrite(fid,qstrike,'single');
qdip = efsStruct.ehead.qdip;
fwrite(fid,qdip,'single');
qrake = efsStruct.ehead.qrake;
fwrite(fid,qrake,'single');

qyr = efsStruct.ehead.qyr;
fwrite(fid,qyr,'int32');
qmon = efsStruct.ehead.qmon;
fwrite(fid,qmon,'int32');
qdy = efsStruct.ehead.qdy;
fwrite(fid,qdy,'int32');
qhr = efsStruct.ehead.qhr;
fwrite(fid,qhr,'int32');
qmn = efsStruct.ehead.qmn;
fwrite(fid,qmn,'int32');

fwrite(fid,zeros(20,1),'int32'); %dummy
ilen = 100000;
bytepos = efsStruct.ehead.bytepos;
fwrite(fid,bytepos,'int32');
% iosuc=fclose(fid); 
% return;
%% write DATA
%Pre-allocate data structure for station information and seismograms
stnum=length(bytepos); % stnum/trace number.
if stnum == (efsStruct.ehead.numts)
else
    disp('error: trace number does not match with station number')
end

fwrite(fid,zeros(stnum*ilen,1),'int32');
%LOOP TO write SEISMOGRAMS, STATION AND PICKING INFORMATION
for ii=1:stnum
    
%     frewind(fid);
    fseek(fid, bytepos(ii), 'bof');
    
    stname = pad(efsStruct.waveforms(ii).stname,8);
    fwrite(fid,unicode2native(stname));
    loccode = pad(efsStruct.waveforms(ii).loccode,8);
    fwrite(fid,unicode2native(loccode));
    datasource = pad(efsStruct.waveforms(ii).datasource,8);
    fwrite(fid,unicode2native(datasource));
    sensor = pad(efsStruct.waveforms(ii).sensor,8);
    fwrite(fid,unicode2native(sensor));
    units = pad(efsStruct.waveforms(ii).units,8);
    fwrite(fid,unicode2native(units));

    chnm = pad(efsStruct.waveforms(ii).chnm,4);
    fwrite(fid,unicode2native(chnm));
    stype = pad(efsStruct.waveforms(ii).stype,4);
    fwrite(fid,unicode2native(stype));
    dva = pad(efsStruct.waveforms(ii).dva,4);
    fwrite(fid,unicode2native(dva));
    pick1q = pad(efsStruct.waveforms(ii).pick1q,4);
    fwrite(fid,unicode2native(pick1q));
    pick2q = pad(efsStruct.waveforms(ii).pick2q,4);
    fwrite(fid,unicode2native(pick2q));
    pick3q = pad(efsStruct.waveforms(ii).pick3q,4);
    fwrite(fid,unicode2native(pick3q));
    pick4q = pad(efsStruct.waveforms(ii).pick4q,4);
    fwrite(fid,unicode2native(pick4q));
    pick1name = pad(efsStruct.waveforms(ii).pick1name,4);
    fwrite(fid,unicode2native(pick1name));
    pick2name = pad(efsStruct.waveforms(ii).pick2name,4);
    fwrite(fid,unicode2native(pick2name));
    pick3name = pad(efsStruct.waveforms(ii).pick3name,4);
    fwrite(fid,unicode2native(pick3name));
    pick4name = pad(efsStruct.waveforms(ii).pick4name,4);
    fwrite(fid,unicode2native(pick4name));
    ppolarity = pad(efsStruct.waveforms(ii).ppolarity,4);
    fwrite(fid,unicode2native(ppolarity));
    problem = pad(efsStruct.waveforms(ii).problem,4);
    fwrite(fid,unicode2native(problem));
    
    
    fwrite(fid,efsStruct.waveforms(ii).npts,'int32');
    
    fwrite(fid,efsStruct.waveforms(ii).syr,'int32');
    fwrite(fid,efsStruct.waveforms(ii).smon,'int32');
    fwrite(fid,efsStruct.waveforms(ii).sdy,'int32');
    fwrite(fid,efsStruct.waveforms(ii).shr,'int32');
    fwrite(fid,efsStruct.waveforms(ii).smn,'int32');
    
    fwrite(fid,efsStruct.waveforms(ii).compazi,'single');
    fwrite(fid,efsStruct.waveforms(ii).compang,'single');
    fwrite(fid,efsStruct.waveforms(ii).gain,'single');
    fwrite(fid,efsStruct.waveforms(ii).f1,'single');
    fwrite(fid,efsStruct.waveforms(ii).f2,'single');
    
    fwrite(fid,efsStruct.waveforms(ii).dt,'single');
    fwrite(fid,efsStruct.waveforms(ii).ssc,'single');
    fwrite(fid,efsStruct.waveforms(ii).tdif,'single');
    fwrite(fid,efsStruct.waveforms(ii).slat,'single');
    fwrite(fid,efsStruct.waveforms(ii).slon,'single');
    fwrite(fid,efsStruct.waveforms(ii).selev,'single');
    fwrite(fid,efsStruct.waveforms(ii).deldist,'single');
    fwrite(fid,efsStruct.waveforms(ii).sazi,'single');
    fwrite(fid,efsStruct.waveforms(ii).qazi,'single');
    fwrite(fid,efsStruct.waveforms(ii).pick1,'single');
    fwrite(fid,efsStruct.waveforms(ii).pick2,'single');
    fwrite(fid,efsStruct.waveforms(ii).pick3,'single');
    fwrite(fid,efsStruct.waveforms(ii).pick4,'single');
    
    fwrite(fid,zeros(20,1),'int32'); %dummy
    fwrite(fid,efsStruct.waveforms(ii).data,'int32'); %data

    
end

    
iosuc=fclose(fid);
