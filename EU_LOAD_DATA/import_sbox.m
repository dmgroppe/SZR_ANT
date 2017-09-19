% This script loads all channels of eeg data files that contain seizures
% (both clinical and subclinical)
sub=1096;
times_fname=fullfile('/Users/dgroppe/Desktop/Dropbox/TWH_INFO/EU_METADATA/',['data_on_off_FR_' num2str(sub) '.csv']);
fprintf('Reading *.data onset/offset times from %s\n',times_fname);
times_csv=csv2Cell(times_fname,',',1);


%% Load seizure times in seconds
szr_times_fname=fullfile('/Users/dgroppe/Desktop/Dropbox/TWH_INFO/EU_METADATA/',['szr_on_off_FR_' num2str(sub) '.csv']);
szr_csv=csv2Cell(szr_times_fname,',',1);
n_szrs=size(szr_csv,1);
szr_onoff_sec=zeros(n_szrs,2);
for a=1:n_szrs,
    szr_onoff_sec(a,1)=str2num(szr_csv{a,4});
    szr_onoff_sec(a,2)=str2num(szr_csv{a,2});
end

%% Convert *.header names to *.dat
n_hdr_files=size(times_csv,1);
csv_data_fnames=cell(n_hdr_files,1);
for a=1:n_hdr_files,
   tmp=times_csv{a,3};
   dot_id=find(tmp=='.');
   csv_data_fnames{a}=[tmp(1:dot_id-1) '.data'];
end

%% Get list of electrodes to import
elec_path='/Users/dgroppe/Desktop/Dropbox/TWH_INFO/EU_INFO';
in_fname=fullfile(elec_path,'FR_1096_use_elecs.txt');
use_chans=csv2Cell(in_fname);


%% Get list of all files for a patient
in_data_path='/Volumes/ValianteLabEuData/EU/inv/pat_FR_1096/adm_1096102/rec_109600102/';
fdir=dir(fullfile(in_data_path,'*.data'));
n_raw_files=length(fdir);
fprintf('%d total *.data files\n',n_raw_files);
file_ct=0;


%% Loop over files
out_data_path='/Users/dgroppe/EU_MAT_DATA/FR_1096';
if ~exist(out_data_path,'dir'),
    fprintf('Creating dir %s\n',out_data_path);
    mkdir(out_data_path);
end

chan_labels=use_chans;
for floop=1:1, % ?? FIX!!!!!!!
    ieeg_fname=fullfile(in_data_path,fdir(floop).name);
    fprintf('Reading %s\n',ieeg_fname);
    
    % Read header
    pat=bin_file(ieeg_fname);
    Fs=pat.a_samp_freq;
    fprintf('FS=%f\n',Fs);
    fprintf('# of chans %d\n',pat.a_n_chan);
    fprintf('# of samples=%d\n',(pat.a_n_samples));
    %     disp(pat.a_file_elec_cell);
    %     disp(pat.a_start_ts);
    %     disp(pat.a_stop_ts);

    % Import just channels of interest
    %pat.a_channs_cell=setdiff(pat.a_file_elec_cell,ignore_channels); % Remove none iEEG channels
    pat.a_channs_cell=use_chans; % Channels to import
    ieeg=pat.get_bin_signals([],[]);
    
    % Get timing from csv file
    csv_id=findStrInCell(fdir(floop).name,csv_data_fnames,1);
    start_sec=str2num(times_csv{csv_id,4});
    stop_sec=str2num(times_csv{csv_id,6});
    
    % Downsample to 256 Hz
    div_fact=Fs/256;
    % dec_fact=round(log2(div_fact));
    n_tpt=round(pat.a_n_samples/div_fact);
    n_chan=size(ieeg,1);
    ieeg256=zeros(n_chan,n_tpt);
    for c=1:n_chan,
        fprintf('Decimating chan %d/%d\n',c,n_chan);
        ieeg256(c,:)=decimate(ieeg(c,:),div_fact);
    end
%         tpts_sec=start_sec:(1/Fs):(stop_sec-1/Fs);
%     tpts_sec=decimate(tpts_sec,div_fact);
    Fs=round(Fs/div_fact);
    tpts_sec=start_sec:(1/Fs):(stop_sec-1/Fs);
    clear ieeg
    
    % Load szr classes
    
    
    % Save
    start_ts=pat.a_start_ts;
    stop_ts=pat.a_stop_ts;
    dot_id=find(fdir(floop).name=='.');
    stem=fdir(floop).name(1:dot_id-1);
    out_fname=[stem '.mat'];
    % Add file timing in seconds from csv file TODO ??
    fprintf('Saveing file to %s\n',out_fname);
    save(fullfile(out_data_path,out_fname),'Fs','tpts_sec','start_ts','stop_ts','ieeg256','use_chans');
end


%% TOOO import all electrods from just hours incluing szrs