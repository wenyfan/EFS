clf;
close all;
clear;
%%
% example file path
efspath = '../EX_DATA/';
% example file name for read in
% HHZ components of 2019 Ridgecrest earthquake
efsname = 'EFS_Example.efs';
% 
efsname2 = 'EFS_Test2.efs';
efsname3 = 'EFS_Example_Matlab.efs';
efsname_Fortran = '10056345.efs';

%%

efsStruct_o=load_efs(['../Fortran/' efsname_Fortran]);


efsStruct1=load_efs([efspath,efsname]);
iosuc1 =write_structure2efs(efspath,efsname2,efsStruct1);
% 
efsStruct2=load_efs([efspath,efsname2]);

figure(1);clf;
plot(efsStruct1.waveforms(1).data,'k-');
hold on;
plot(efsStruct1.waveforms(1).data,'r--')
%%
evtdatenum0 = datenum([2019, 7, 6, 3, 19, 53]);
daylen = 86400;
starttime = evtdatenum0-1/daylen*1*60;
endtime = evtdatenum0+1/daylen*5*60;
sstr = datestr(starttime,'yyyy-mm-dd HH:MM:SS');
edtr = datestr(endtime,'yyyy-mm-dd HH:MM:SS');

irisSTR = irisFetch.Traces('CI','ADO','*','HHZ',sstr, edtr);
iosuc3 =write_iris2efs(efspath,efsname3,irisSTR);
efsStruct3=load_efs([efspath,efsname3]);

figure(2);clf;
plot(efsStruct1.waveforms(1).data(2:end),'k-');
hold on;
plot(efsStruct3.waveforms(1).data,'r--')
