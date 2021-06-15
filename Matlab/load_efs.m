function efsStruct=load_efs(name)
%
% function to read EFS file format into a MATLAB structure
% based on variables in PS efs_subs.f90
%
% Example:
% efsStruct=load_efs('filename.efs');
%
% IMPORTANT: station information and seismograms are stored in NESTED DATA
% structure.
% For example to plot third seismogram in structure:
% figure; plot(efsStruct.waveforms(3).data);
% or to access all station names:
% stname=[efsStruct.data.stat];
%
% JSB, 2009
% 2020/01/03 WF
% 2021/03/02 WF: update the file to read in EFSs from Python
% 'name' needs to include '.efs'
%%
% Data file ID
fid=fopen(name);% fclose(fid); clear efsStruct fid=fopen(n)
% File name (string)
clear efsStruct;
% fseek(fid, 0, 'bof');
efsStruct.name=name;

%% READ File HEADER INFORMATION
efsStruct.fhead.byteype = fread(fid,1,'int32');
efsStruct.fhead.eheadtype = fread(fid,1,'int32');
efsStruct.fhead.nbytes_ehead = fread(fid,1,'int32');
efsStruct.fhead.tsheadtype = fread(fid,1,'int32');
efsStruct.fhead.nbytes_tshead = fread(fid,1,'int32');

%% READ Event HEADER INFORMATION
efsStruct.ehead.efslabel=strtrim([native2unicode(fread(fid,40,'char')')]);
efsStruct.ehead.datasource=strtrim([native2unicode(fread(fid,40,'char')')]);
efsStruct.ehead.maxnumts = fread(fid,1,'int32');
efsStruct.ehead.numts=fread(fid,1,'int32');
efsStruct.ehead.cuspid=fread(fid,1,'int32');

% Earthquake Info
efsStruct.ehead.qtype=strtrim([native2unicode(fread(fid,4,'char')')]);
efsStruct.ehead.qmag1type=strtrim([native2unicode(fread(fid,4,'char')')]);
efsStruct.ehead.qmag2type=strtrim([native2unicode(fread(fid,4,'char')')]);
efsStruct.ehead.qmag3type=strtrim([native2unicode(fread(fid,4,'char')')]);
efsStruct.ehead.qmomenttype=strtrim([native2unicode(fread(fid,4,'char')')]);
efsStruct.ehead.qlocqual=strtrim([native2unicode(fread(fid,4,'char')')]);
efsStruct.ehead.qfocalqual=strtrim([native2unicode(fread(fid,4,'char')')]);
efsStruct.ehead.qlat=fread(fid,1,'single');
efsStruct.ehead.qlon=fread(fid,1,'single');
efsStruct.ehead.qdep=fread(fid,1,'single');
efsStruct.ehead.qsc=fread(fid,1,'single');
efsStruct.ehead.qmag1=fread(fid,1,'single');
efsStruct.ehead.qmag2=fread(fid,1,'single');
efsStruct.ehead.qmag3=fread(fid,1,'single');
efsStruct.ehead.qmoment=fread(fid,1,'single');
efsStruct.ehead.qstrike=fread(fid,1,'single');
efsStruct.ehead.qdip=fread(fid,1,'single');
efsStruct.ehead.qrake=fread(fid,1,'single');

efsStruct.ehead.qyr=fread(fid,1,'int32');
efsStruct.ehead.qmon=fread(fid,1,'int32');
efsStruct.ehead.qdy=fread(fid,1,'int32');
efsStruct.ehead.qhr=fread(fid,1,'int32');
efsStruct.ehead.qmn=fread(fid,1,'int32');

fread(fid,20,'int32'); %dummy
efsStruct.ehead.bytepos=fread(fid,efsStruct.ehead.numts,'int32');
bytepos = efsStruct.ehead.bytepos;
%% READ DATA
%Pre-allocate data structure for station information and seismograms
stnum=length(efsStruct.ehead.bytepos); % stnum/trace number.
if stnum == efsStruct.ehead.numts
else
    disp('error: trace number does not match with station number')
end

efsStruct.waveforms(stnum).stname='AAA';
efsStruct.waveforms(stnum).loccode='BB';
efsStruct.waveforms(stnum).datasource='';
efsStruct.waveforms(stnum).sensor='';
efsStruct.waveforms(stnum).units='';
efsStruct.waveforms(stnum).chnm='Z';
efsStruct.waveforms(stnum).stype='';
efsStruct.waveforms(stnum).dva='';
efsStruct.waveforms(stnum).pick1q='NA';
efsStruct.waveforms(stnum).pick2q='NA';
efsStruct.waveforms(stnum).pick3q='NA';
efsStruct.waveforms(stnum).pick4q='NA';
efsStruct.waveforms(stnum).pick1name='NA';
efsStruct.waveforms(stnum).pick2name='NA';
efsStruct.waveforms(stnum).pick3name='NA';
efsStruct.waveforms(stnum).pick4name='NA';
efsStruct.waveforms(stnum).ppolarity='';
efsStruct.waveforms(stnum).problem='';
efsStruct.waveforms(stnum).npts=-99;
efsStruct.waveforms(stnum).syr=-99;
efsStruct.waveforms(stnum).smon=-99;
efsStruct.waveforms(stnum).sdy=-99;
efsStruct.waveforms(stnum).shr=-99;
efsStruct.waveforms(stnum).smn=-99;
efsStruct.waveforms(stnum).compazi=-99;
efsStruct.waveforms(stnum).compang=-99;
efsStruct.waveforms(stnum).gain=-99;
efsStruct.waveforms(stnum).f1=-99;
efsStruct.waveforms(stnum).f2=-99;
efsStruct.waveforms(stnum).dt=-99;
efsStruct.waveforms(stnum).ssc=-99;
efsStruct.waveforms(stnum).tdif=-99;
efsStruct.waveforms(stnum).slat=-99;
efsStruct.waveforms(stnum).slon=-99;
efsStruct.waveforms(stnum).selev=-99;
efsStruct.waveforms(stnum).deldist=-99;
efsStruct.waveforms(stnum).sazi=-99;
efsStruct.waveforms(stnum).qazi=-99;
efsStruct.waveforms(stnum).pick1=-99;
efsStruct.waveforms(stnum).pick2=-99;
efsStruct.waveforms(stnum).pick3=-99;
efsStruct.waveforms(stnum).pick4=-99;
efsStruct.waveforms(stnum).data=[];

%LOOP TO READ SEISMOGRAMS, STATION AND PICKING INFORMATION
for ii=1:stnum
    
    fseek(fid, bytepos(ii), 'bof');
    
    efsStruct.waveforms(ii).stname=strtrim([native2unicode(fread(fid,8,'char')')]);
    efsStruct.waveforms(ii).loccode=strtrim([native2unicode(fread(fid,8,'char')')]);
    efsStruct.waveforms(ii).datasource=strtrim([native2unicode(fread(fid,8,'char')')]);
    efsStruct.waveforms(ii).sensor=strtrim([native2unicode(fread(fid,8,'char')')]);
    efsStruct.waveforms(ii).units=strtrim([native2unicode(fread(fid,8,'char')')]);
    
    efsStruct.waveforms(ii).chnm=strtrim([native2unicode(fread(fid,4,'char')')]);
    efsStruct.waveforms(ii).stype=strtrim([native2unicode(fread(fid,4,'char')')]);
    efsStruct.waveforms(ii).dva=strtrim([native2unicode(fread(fid,4,'char')')]);
    efsStruct.waveforms(ii).pick1q=strtrim([native2unicode(fread(fid,4,'char')')]);
    efsStruct.waveforms(ii).pick2q=strtrim([native2unicode(fread(fid,4,'char')')]);
    efsStruct.waveforms(ii).pick3q=strtrim([native2unicode(fread(fid,4,'char')')]);
    efsStruct.waveforms(ii).pick4q=strtrim([native2unicode(fread(fid,4,'char')')]);
    efsStruct.waveforms(ii).pick1name=strtrim([native2unicode(fread(fid,4,'char')')]);
    efsStruct.waveforms(ii).pick2name=strtrim([native2unicode(fread(fid,4,'char')')]);
    efsStruct.waveforms(ii).pick3name=strtrim([native2unicode(fread(fid,4,'char')')]);
    efsStruct.waveforms(ii).pick4name=strtrim([native2unicode(fread(fid,4,'char')')]);
    efsStruct.waveforms(ii).ppolarity=strtrim([native2unicode(fread(fid,4,'char')')]);
    efsStruct.waveforms(ii).problem=strtrim([native2unicode(fread(fid,4,'char')')]);
    
    
    efsStruct.waveforms(ii).npts=fread(fid,1,'int32');
    efsStruct.waveforms(ii).syr=fread(fid,1,'int32');
    efsStruct.waveforms(ii).smon=fread(fid,1,'int32');
    efsStruct.waveforms(ii).sdy=fread(fid,1,'int32');
    efsStruct.waveforms(ii).shr=fread(fid,1,'int32');
    efsStruct.waveforms(ii).smn=fread(fid,1,'int32');
    
    efsStruct.waveforms(ii).compazi=fread(fid,1,'single');
    efsStruct.waveforms(ii).compang=fread(fid,1,'single');
    efsStruct.waveforms(ii).gain=fread(fid,1,'single');
    efsStruct.waveforms(ii).f1=fread(fid,1,'single');
    efsStruct.waveforms(ii).f2=fread(fid,1,'single');
    
    efsStruct.waveforms(ii).dt=fread(fid,1,'single');
    efsStruct.waveforms(ii).ssc=fread(fid,1,'single');
    efsStruct.waveforms(ii).tdif=fread(fid,1,'single');
    efsStruct.waveforms(ii).slat=fread(fid,1,'single');
    efsStruct.waveforms(ii).slon=fread(fid,1,'single');
    efsStruct.waveforms(ii).selev=fread(fid,1,'single');
    efsStruct.waveforms(ii).deldist=fread(fid,1,'single');
    efsStruct.waveforms(ii).sazi=fread(fid,1,'single');
    efsStruct.waveforms(ii).qazi=fread(fid,1,'single');
    efsStruct.waveforms(ii).pick1=fread(fid,1,'single');
    efsStruct.waveforms(ii).pick2=fread(fid,1,'single');
    efsStruct.waveforms(ii).pick3=fread(fid,1,'single');
    efsStruct.waveforms(ii).pick4=fread(fid,1,'single');
    
    fread(fid,20,'int32'); %move position
    efsStruct.waveforms(ii).data=fread(fid,efsStruct.waveforms(ii).npts,'int32');
    
end

fclose(fid);
