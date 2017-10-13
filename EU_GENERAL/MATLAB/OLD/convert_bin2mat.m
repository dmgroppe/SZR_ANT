% This script was supposed to convert continous binary EEG files into mat
% files, but I abandoned it before CLAE as I found some files I had already
% converted

sub_id=1096; %DONE (need sgrams)
% sub_id=620; %DONE (need sgrams)
%sub_id=264; % DONE
% sub_id=590; % DONE
%sub_id=253; % DONE
% sub_id=862; % DONE
% sub_id=565; %DONE
% sub_id=273; % DONE
% sub_id=1125; % DONE
% sub_id=1077; %DONE
if ismac,
    root_dir='/Users/davidgroppe/PycharmProjects/SZR_ANT/';
else
    root_dir='/home/dgroppe/GIT/SZR_ANT/';
end

%
% %% Get all the files with clinical szrs and their SOZ
% cli_szr_info=get_szr_fnames(sub_id);
%
% % Remove szrs without SOZ-labels
% keep_ids=[];
% n_szrs=length(cli_szr_info);
% fprintf('%d Clinical Szrs\n',n_szrs);
% for a=1:n_szrs,
%     if ~isempty(cli_szr_info(a).clinical_soz_chans{1}),
%         keep_ids=[keep_ids a];
%     end
% end
% cli_szr_info=cli_szr_info(keep_ids);
% n_szrs=length(cli_szr_info);
% fprintf('%d Clinical Szrs with SOZs defined\n',n_szrs);


%% Get channel labels
bipolar_labels=derive_bipolar_pairs(sub_id);
n_chan=size(bipolar_labels,1);


%% Get list of all files and the timing of all szrs (clinical and subclinical)
file_info=get_fnames_and_szr_times(sub_id);
n_files=length(file_info);

%% Loop over bipolar soz chans
clear soz_chans_bi
if sub_id==1096,
    soz_chans_bi{1,1}='HL3';
    soz_chans_bi{1,2}='HL4';
    bin_path='/Volumes/SgateOSExJnld/EU_TEMP/inv/pat_FR_1096/adm_1096102/rec_109600102';
else
    soz_chans_bi{1,1}='HR11';
    soz_chans_bi{1,2}='HR12';
end
for cloop=1:size(soz_chans_bi,1),
    %for cloop=1:1,
    fprintf('Working on chan %s-%s\n',soz_chans_bi{cloop,1},soz_chans_bi{cloop,2});
    file_id=1;
    
    % Read header
    temp_id=find(file_info(file_id).fname=='.');
    data_fname=[file_info(file_id).fname(1:temp_id-1) '.data'];
    pat=bin_file(fullfile(bin_path,data_fname));
    %pat=bin_file('/Volumes/SgateOSExJnld/EU_TEMP/inv/pat_FR_1096/adm_1096102/rec_109600102/109600102_0000.data');
    Fs=pat.a_samp_freq;
    if isempty(Fs),
        error('Could not find file: %s',file_info(file_id).fname);
    end
    fprintf('FS=%f\n',Fs);
    %fprintf('# of monopolar chans %d\n',pat.a_n_chan);
    fprintf('# of samples=%d\n',(pat.a_n_samples));
    

    %%    
    % Import entire clip (typically 1 hour long)
    %             ieeg_labels=cell(n_chan,1);
    pat.a_channs_cell={soz_chans_bi{cloop,1}}; % Channel to import
    %ieeg(1:n_chan,:)=pat.get_bin_signals([],[]);
    ieeg_temp1=pat.get_bin_signals(1,pat.a_n_samples);
    
    pat.a_channs_cell={soz_chans_bi{cloop,2}}; % Channel to import
    ieeg_temp2=pat.get_bin_signals(1,pat.a_n_samples);
    
    ieeg=ieeg_temp1-ieeg_temp2;
    ieeg_time_sec_pre_decimate=[0:(length(ieeg)-1)]/Fs; % time relative to start of file
    clear ieeg_temp1 ieeg_temp2;
    if Fs>256,
        % Downsample data to 256 Hz
        down_fact=round(Fs/256);
        ieeg=decimate(ieeg,down_fact);
        time_dec=zeros(1,length(ieeg));
        for tloop=1:length(ieeg),
            time_dec(tloop)=mean(ieeg_time_sec_pre_decimate([1:down_fact] ...
                +(tloop-1)*down_fact));
        end
    else
        time_dec=ieeg_time_sec_pre_decimate;
    end
    n_ieeg_dec_tpts=length(ieeg);
    clear ieeg_time_sec_pre_decimate;
    
    % Clip raw szr data
    %             targ_raw_ieeg_tpts=(targ_win_dec>0);
    %             targ_raw_ieeg=ieeg(targ_raw_ieeg_tpts);
    %             targ_raw_ieeg_sec=time_dec(targ_raw_ieeg_tpts);
    %
    
    %% Save data as mat file
    chan_imported=soz_chans_bi;
    out_fname=sprintf('%d_all_%s',sub_id,file_info(file_id).fname(1:temp_id-1));
    save(fullfile('/Users/davidgroppe/ONGOING/EU_YHAT',out_fname),'ieeg', ...
        'time_dec','data_fname','chan_imported');
    fprintf('Data saved to %s\n',fullfile('/Users/davidgroppe/ONGOING/EU_YHAT',out_fname));
end


%%  Save sample size of each electrode
% ftr_fs=1/median(diff(se_time_sec));
% outdir=fullfile(root_dir,'EU_GENERAL','EU_GENERAL_FTRS');
% outfname=fullfile(outdir,sprintf('%d_szr_sample_size',sub_id));
% fprintf('Saving counts of # of szr observations/electrode in %s\n',outfname);
% save(outfname,'n_tpt_ct','soz_chans_bi','ftr_fs');

disp('Done!!');

