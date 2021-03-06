%% This script computes phase locking value (PLV) and spectral energy (SE)
% features with EDM for a patient's non-ictal clips. A subset of the data
% are output to a file for classifier training. They are all output to a
% directory like this:
% /SZR_ANT/EU_GENERAL/EU_GENERAL_FTRS/PLV_SE/1096/1096_HL2_HL3_non.mat
%
% NOTE: a key difference between this and compute_se_interictal.m is that
% only a subset of interictal files are sampled from (as determined by the
% parameter fsi). This is because PLV takes so long to compute.
%
%% KEY VARIABLES
% ** Voltage Data
% ieeg: raw bipolar data
% szr_class: 0=no szr, 1=clinical szr, -1=subclinical szr
%
% targ_window: same as szr class but extends 5 sec min before clinician
% onset to try to trigger stim as early as possible
%
% ieeg_time_sec_pre_decimate: time relative to start of file
%
%
% ** Downsampled Data (256 Hz for all patients)
% ieeg: raw bipolar data
% time_dec: dowsample dtime
% targ_wind_dec=downsampled version of targ_window
% szr_class_dec=downsampled version of szr_class
%
%
% ** Spectral Energy Features
% n_ftr_wind: # of feature time pts (about 10 Hz srate)
% se_time_sec: time relative to start of file
% se_szr_class: 0=no szr, 1=szr
% se_class: 0=no szr, 1=szr <-target windowfor classifier
% se_ftrs: feature matrix (ftr x time)
% ftr_labes: feature labels


%sub_id=1096; % DONE
%sub_id=620; % DONE
%sub_id=264; % DONE
% sub_id=590; % DONE
% sub_id=862;% DONE
% sub_id=565; % DONE
%sub_id=253; % DONE
%sub_id=273; % DONE
%sub_id=1125; % DONE
%sub_id=1077; %DONE
%sub_id=922; %DONE

if ismac,
    root_dir='/Users/davidgroppe/PycharmProjects/SZR_ANT/';
else
    root_dir='/home/dgroppe/GIT/SZR_ANT/';
end

subs=[970, 253, 565, 590, 620, 958];
%subs=264;
subs=[273, 862, 1125];
%subs=115;
%subs=442;
%subs=1096; % DONE
%subs=1077; % DONE took 5.8 hrs
subs=1096;

for sub_id=subs,
    %% Load list of channels to use for computing PLV for each electrode
    plvchan_fname=fullfile(root_dir,'EU_METADATA','PLV_CHANS',sprintf('%d_plv.csv',sub_id));
    plvchans=csv2Cell(plvchan_fname,',',1);
    n_plv_pairs=size(plvchans,2)-1;
    
    %% EDM Lags and moving window length
    edm_lags=0:2:8;
    n_lags=length(edm_lags);
    wind_len_sec=1; % moving window length in seconds
    
    edge_pts=1178; % # of initial time points to remove due to edge effect
    % Decay fact 2, it takes 18 tpts (1.800000 sec) to get below .01 threshold
    % Decay fact 4, it takes 73 tpts (7.300000 sec) to get below .01 threshold
    % Decay fact 6, it takes 294 tpts (29.400000 sec) to get below .01 threshold
    % Decay fact 8, it takes 1178 tpts (117.800000 sec) to get below .01 threshold
    % Decay fact 2, it takes 18 tpts (1.800000 sec) to get below .01 threshold
    % Decay fact 4, it takes 73 tpts (7.300000 sec) to get below .01 threshold
    % Decay fact 6, it takes 294 tpts (29.400000 sec) to get below .01 threshold
    % Decay fact 8, it takes 1178 tpts (117.800000 sec) to get below .01 threshold
    % Decay fact 10, it takes 4715 tpts (471.500000 sec) to get below .01 threshold
    
    
    %% Define frequency bands
    bands=[0 4; 4 8; 8 13; 13 30; 30 50; 70 100];
    band_labels={'DeltaMag','ThetaMag','AlphaMag','BetaMag','GammaMag','HGammaMag'};
    n_bands=length(bands);
    
    
    %% Derive feature labels
    n_ftrs=n_bands*n_lags;
    ftr_labels=cell(n_ftrs,1);
    temp_ct=0;
    for lag_loop=1:n_lags,
        for band_loop=1:n_bands,
            temp_ct=temp_ct+1;
            ftr_labels{temp_ct}=sprintf('%s_Lag_%d',band_labels{band_loop},edm_lags(lag_loop));
        end
    end
    
    
    %% Load bad chans and ignore them
    badchan_fname=fullfile(root_dir,'EU_METADATA','BAD_CHANS',sprintf('bad_chans_%d.txt',sub_id));
    badchans=csv2Cell(badchan_fname);
    if strcmpi(badchans{1},'None'),
        badchans=[];
    end
    fprintf('# of bad chans: %d\n',length(badchans));
    
    
    %% SGRAM Params
    sgramCfg=[];
    sgramCfg.Fs=256; % Sampling rate of downsampled data
    sgramCfg.T=2; %1 second window
    sgramCfg.K=3; % # of tapers
    sgramCfg.fpass=[0 .4*sgramCfg.Fs];
    W=(sgramCfg.K+1)/(2*sgramCfg.T);
    sgramCfg.tapers=[W*sgramCfg.T sgramCfg.K]; %[TW K]
    sgramCfg.rm_mean=0;
    sgramCfg.trialave=0;
    sgramCfg.movingwin=[sgramCfg.T .2];
    
    
    %% Load list of SOZ channels and the number of samples for each
    indir=fullfile(root_dir,'EU_GENERAL','EU_GENERAL_FTRS');
    infname=fullfile(indir,sprintf('%d_szr_sample_size',sub_id));
    fprintf('Loading counts of # of szr observations/electrode in %s\n',infname);
    % save(infname,'n_tpt_ct','soz_chans_bi','ftr_fs');
    load(infname);
    
    n_chan=size(soz_chans_bi,1);
    fprintf('# of SOZ Channels (good & bad): %d\n',n_chan);
    fprintf('Feature sampling rate: %f Hz\n',ftr_fs);
    good_chan_ids=[];
    for a=1:n_chan,
        temp_label=sprintf('%s-%s',soz_chans_bi{a,1},soz_chans_bi{a,2});
        if findStrInCell(temp_label,badchans),
            fprintf('SOZ channel %s is bad. Ignoring it.\n',temp_label);
        else
            good_chan_ids=[good_chan_ids a];
            fprintf('%s-%s # of obs: %d\n',soz_chans_bi{a,1},soz_chans_bi{a,2},n_tpt_ct(a));
        end
    end
    soz_chans_bi=soz_chans_bi(good_chan_ids,:);
    n_chan=size(soz_chans_bi,1);
    fprintf('# of SOZ Channels (just good): %d\n',n_chan);
    clear good_chan_ids
    
    
    %% Get list of all files and the timing of all szrs (clinical and subclinical)
    file_info=get_fnames_and_szr_times(sub_id);
    n_files=length(file_info);
    
    %% File sampling interval
    % if fsi=1; some observations are taken from every file, if fsi=2,
    % observations are only taken from every other file, etc..
    fsi=10;
    
    %% Loop over SOZ electrodes
    for cloop=1:n_chan,
        fprintf('Working on chan %s-%s\n',soz_chans_bi{cloop,1},soz_chans_bi{cloop,1});
        
        % Figure out how many non-szr samples to draw from each file
        n_nonszr_obs=ceil(fsi*n_tpt_ct(cloop)/n_files);
        fprintf('Drawing %d random non-szr samples from each file.\n',n_nonszr_obs);
        
        nonszr_se_ftrs=[];
        n_sampled_files=round(n_files/fsi);
        % Loop over files
        %for floop=1:1, PICKUP ?? start at n_files=25
        for floop=1:n_sampled_files,
        %for floop=1:fsi:n_files,
            % Compute features
            
            % Read header
            full_data_fname=get_data_fullfname(sub_id,file_info(1+(floop-1)*fsi).fname);
            fprintf('Channel %d/%d\n',cloop,n_chan);
            fprintf('Loading file %d/%d %s\n',floop,n_sampled_files,file_info(1+(floop-1)*fsi).fname);
            pat=bin_file(full_data_fname);
            Fs=pat.a_samp_freq;
            if isempty(Fs),
                error('Could not find file: %s',full_data_fname);
            end
            fprintf('Fs=%f\n',Fs);
            %fprintf('# of monopolar chans %d\n',pat.a_n_chan);
            n_samp=pat.a_n_samples;
            fprintf('# of samples=%d\n',n_samp);
            ieeg_time_sec_pre_decimate=[0:(n_samp-1)]/Fs; % time relative to start of file
            
            %% Compute ictal-class
            szr_class=zeros(1,n_samp);
            targ_window=zeros(1,n_samp); % Same as szr class but extended
            % 5 seconds before onset to try to stimulate before onset
            % Clinical Szrs
            if ~isempty(file_info(1+(floop-1)*fsi).clin_szr_onsets_sec),
                % There are szrs in this file (clinical and/or subclinical)
                for sloop=1:length(file_info(1+(floop-1)*fsi).clin_szr_onsets_sec),
                    onset_id=findTpt(file_info(1+(floop-1)*fsi).clin_szr_onsets_sec(sloop),ieeg_time_sec_pre_decimate);
                    if ~isempty(file_info(1+(floop-1)*fsi).clin_szr_offsets_sec),
                        % Sadly, some szrs have marked onsets but not offsets
                        % When this happens make szr last until end of clip
                        offset_id=findTpt(file_info(1+(floop-1)*fsi).clin_szr_offsets_sec(sloop),ieeg_time_sec_pre_decimate);
                    else
                        offset_id=n_samp;
                    end
                    szr_class(onset_id:offset_id)=1;
                    targ_onset_id=onset_id-Fs*5; %extend 5 seconds in past to try to stimulate before onset
                    if targ_onset_id<1,
                        targ_onset_id=1;
                    end
                    targ_window(targ_onset_id:offset_id)=1;
                end
            end
            
            %% Subclinical Szrs
            if ~isempty(file_info(1+(floop-1)*fsi).sub_szr_onsets_sec),
                % There are szrs in this file (clinical and/or subclinical)
                for sloop=1:length(file_info(1+(floop-1)*fsi).sub_szr_onsets_sec),
                    onset_id=findTpt(file_info(1+(floop-1)*fsi).sub_szr_onsets_sec(sloop),ieeg_time_sec_pre_decimate);
                    if ~isempty(file_info(1+(floop-1)*fsi).sub_szr_offsets_sec),
                        % Sadly, some szrs have marked onsets but not offsets
                        % When this happens make szr last until end of clip
                        offset_id=findTpt(file_info(1+(floop-1)*fsi).sub_szr_offsets_sec(sloop),ieeg_time_sec_pre_decimate);
                    else
                        offset_id=n_samp;
                    end
                    szr_class(onset_id:offset_id)=-1;
                    targ_onset_id=onset_id-Fs*5; %extend 5 seconds in past to try to stimulate before onset
                    if targ_onset_id<1,
                        targ_onset_id=1;
                    end
                    targ_window(targ_onset_id:offset_id)=-1;
                end
            end
            
            %% Import entire clip of SOZ chan (bipolar data)
            [ieeg, time_dec, targ_raw_ieeg, targ_raw_ieeg_sec, targ_win_dec, szr_class_dec]=import_eu_clip(pat,soz_chans_bi{cloop,1},soz_chans_bi{cloop,2}, ...
                targ_window,szr_class,Fs,sgramCfg);
            
            %             pat.a_channs_cell={soz_chans_bi{cloop,1}}; % Channel to import
            %             ieeg_temp1=pat.get_bin_signals(1,pat.a_n_samples);
            %
            %             pat.a_channs_cell={soz_chans_bi{cloop,2}}; % Channel to import
            %             ieeg_temp2=pat.get_bin_signals(1,pat.a_n_samples);
            %
            %             ieeg=ieeg_temp1-ieeg_temp2;
            %             ieeg_time_sec_pre_decimate=[0:(n_samp-1)]/Fs; % time relative to start of file
            %             clear ieeg_temp1 ieeg_temp2;
            
            
            %%%%%%%% Compute features %%%%%%%%%%%
            %% Figure out how many feature time points there are
            wind_len=256*wind_len_sec;
            wind_step=round(256/10); %10 Hz moving window sampling
            wind=1:wind_len;
            n_ftr_wind=0;
            while wind(end)<length(ieeg),
                n_ftr_wind=n_ftr_wind+1;
                wind=wind+wind_step;
            end
            n_ftr_wind=n_ftr_wind-1;
            
            % Find mean time and class of moving windows
            se_time_sec=zeros(1,n_ftr_wind);
            se_class=zeros(1,n_ftr_wind);
            se_szr_class=zeros(1,n_ftr_wind);
            wind=1:wind_len;
            for a=1:n_ftr_wind,
                se_time_sec(a)=mean(time_dec(wind));
                se_class(a)=mean(targ_win_dec(wind));
                se_szr_class(a)=mean(szr_class_dec(wind));
                wind=wind+wind_step;
            end
            
            %% Compute features with EDM for all data
            se_ftrs=zeros(n_lags*n_bands,n_ftr_wind);
            
            % Compute raw feature without any smoothing
            for bloop=1:n_bands,
                % Apply causal butterworth filter
                %bp_ieeg=butterfiltMK(ieeg,256,[bands(bloop,1) bands(bloop,2)],0,4);
                bp_ieeg=butterfilt4_causalEU(ieeg,256,[bands(bloop,1) bands(bloop,2)],0);
                
                % Compute moving window hilbert transform
                [se_ftrs(bloop,:), hilb_ifreq]=bp_hilb_mag(bp_ieeg,n_ftr_wind,wind_len,wind_step);
            end
            
            % Set initial value of all features
            se_ftrs(:,1)=repmat(se_ftrs(1:n_bands,1),n_lags,1);
            
            % Apply EDM smoothing
            fprintf('Applying EDM smoothing...\n');
            ftr_ids=1:n_bands;
            base_ftr_ids=1:n_bands;
            for edm_loop=2:n_lags,
                ftr_ids=ftr_ids+n_bands;
                now_wt=1/(2^edm_lags(edm_loop));
                for t=2:n_ftr_wind,
                    se_ftrs(ftr_ids,t)=now_wt*se_ftrs(base_ftr_ids,t)+(1-now_wt)*se_ftrs(ftr_ids,t-1);
                end
            end
            
            
            %% Compute PLV
            % Preallocate memory for PLV features with EDM
            plv_ftrs=zeros(n_lags*n_bands,n_ftr_wind);
            hilb_pcos=zeros(n_lags*n_bands,n_ftr_wind);
            hilb_psin=zeros(n_lags*n_bands,n_ftr_wind);
            
            % Get list of 7 other electrodes to compute plv with
            seed_chan=sprintf('%s-%s',soz_chans_bi{cloop,1},soz_chans_bi{cloop,2});
            plv_row_id=findStrInCell(seed_chan,plvchans(:,1));
            
            % Compute PLV features without any smoothing
            for other_chan=1:n_plv_pairs,
                fprintf('Computing PLV with chan %d of %d\n',other_chan,n_plv_pairs);
                pair_chan_bi=plvchans{plv_row_id,other_chan+1};
                dash_id=find(pair_chan_bi=='-');
                pair_chan1=pair_chan_bi(1:dash_id-1);
                pair_chan2=pair_chan_bi(dash_id+1:end);
                
                % Data from pair chan
                ieeg_pair=import_eu_clip(pat,pair_chan1,pair_chan2,targ_window,szr_class,Fs,sgramCfg);
                
                for bloop=1:n_bands,
                    % Apply causal butterworth filter to seed channel
                    bp_ieeg=butterfilt4_causalEU(ieeg,256,[bands(bloop,1) bands(bloop,2)],0);
                    
                    % Apply causal butterworth filter to pair channel
                    bp_ieeg_pair=butterfilt4_causalEU(ieeg_pair,256,[bands(bloop,1) bands(bloop,2)],0);
                    
                    % Compute PLV via moving window hilbert transform
                    [hilb_pcos(bloop,:), hilb_psin(bloop,:)]=bp_hilb_plv(bp_ieeg, bp_ieeg_pair, ...
                        n_ftr_wind,wind_len,wind_step);
                end
                
                % Apply EDM smoothing
                % Set initial value of all features
                hilb_pcos(:,1)=repmat(hilb_pcos(1:n_bands,1),n_lags,1);
                hilb_psin(:,1)=repmat(hilb_psin(1:n_bands,1),n_lags,1);
                
                fprintf('Applying EDM smoothing to PLV cos & sin...\n');
                ftr_ids=1:n_bands;
                base_ftr_ids=1:n_bands;
                for edm_loop=2:n_lags,
                    ftr_ids=ftr_ids+n_bands;
                    now_wt=1/(2^edm_lags(edm_loop));
                    for t=2:n_ftr_wind,
                        hilb_pcos(ftr_ids,t)=now_wt*hilb_pcos(base_ftr_ids,t)+(1-now_wt)*hilb_pcos(ftr_ids,t-1);
                        hilb_psin(ftr_ids,t)=now_wt*hilb_psin(base_ftr_ids,t)+(1-now_wt)*hilb_psin(ftr_ids,t-1);
                    end
                end
                plv_ftrs=plv_ftrs+sqrt(hilb_pcos.*hilb_pcos+hilb_psin.*hilb_psin)/n_plv_pairs;
            end
            
            
            %% Remove initial time points polluted by edge effects
            se_ftrs=se_ftrs(:,edge_pts:end);
            plv_ftrs=plv_ftrs(:,edge_pts:end);
            se_time_sec=se_time_sec(edge_pts:end);
            se_class=se_class(edge_pts:end);
            se_szr_class=se_szr_class(edge_pts:end);
            
            %%
            if 0,
                % Code for checking results
                se_ftrs_z=zscore(se_ftrs')'; %z-score
                plv_ftrs_z=zscore(plv_ftrs')'; %z-score
                
                figure(1); clf();
                ax1=subplot(411);
                %imagesc(se_ftrs_z);
                h=plot(se_time_sec,se_ftrs_z);
                title(sprintf('%s-%s, Szr%d',soz_chans_bi{cloop,1},soz_chans_bi{cloop,2},floop));
                       ax2=subplot(412); 
                plot(se_time_sec,se_class,'--b'); hold on;
                plot(se_time_sec,se_szr_class,'r-');
                axis tight;
                
                ax3=subplot(413);
                plot(se_time_sec,plv_ftrs_z);
                axis tight;
                
                ax4=subplot(414);
                plot(time_dec,ieeg);
                axis tight;
                
                linkaxes([ax1 ax2 ax3 ax4],'x');
            end
            
            %% Collect a random subsample of ftrs from non-szr time periods
            if isempty(nonszr_se_ftrs),
                %preallocate mem, first time adding data
                nonszr_se_ftrs=zeros(n_ftrs,n_nonszr_obs*n_sampled_files)*NaN;
                nonszr_plv_ftrs=zeros(n_ftrs,n_nonszr_obs*n_sampled_files)*NaN;
                nonszr_se_ftrs_time_sec=zeros(1,n_nonszr_obs*n_sampled_files)*NaN;
                source_fnames=cell(1,n_sampled_files);
            end
            
            % Get non-szr time window ids
            non_szr_ids=find(se_class<0.5);
            % Randomly select subset of non-szr features
            if length(non_szr_ids)==0,
                nonszr_se_ftrs(:,[1:n_nonszr_obs]+(floop-1)*n_nonszr_obs)=NaN;
                nonszr_plv_ftrs(:,[1:n_nonszr_obs]+(floop-1)*n_nonszr_obs)=NaN;
                nonszr_se_ftrs_time_sec([1:n_nonszr_obs]+(floop-1)*n_nonszr_obs)=NaN;
            else
                use_non_szr_ids=non_szr_ids(randi(length(non_szr_ids),1,n_nonszr_obs));
                nonszr_se_ftrs(:,[1:n_nonszr_obs]+(floop-1)*n_nonszr_obs)=se_ftrs(:,use_non_szr_ids);
                nonszr_plv_ftrs(:,[1:n_nonszr_obs]+(floop-1)*n_nonszr_obs)=plv_ftrs(:,use_non_szr_ids);
                nonszr_se_ftrs_time_sec([1:n_nonszr_obs]+(floop-1)*n_nonszr_obs)=se_time_sec(use_non_szr_ids);
                source_fnames{floop}=full_data_fname;
            end
            
            
        end
        
        %% Save results to disk
        outdir=fullfile(root_dir,'EU_GENERAL','EU_GENERAL_FTRS','PLV_SE',num2str(sub_id));
        if ~exist(outdir,'dir'),
            mkdir(outdir);
        end
        outfname=fullfile(outdir,sprintf('%d_%s_%s_non',sub_id, ...
            soz_chans_bi{cloop,1},soz_chans_bi{cloop,2}));
        fprintf('Saving szr features to %s\n',outfname);
        % Remove time points that have no data because the source file
        % contained less than the desired number of time points
        non_nan_ids=find(~isnan(nonszr_se_ftrs_time_sec));
        nonszr_se_ftrs_time_sec=nonszr_se_ftrs_time_sec(non_nan_ids);
        nonszr_se_ftrs=nonszr_se_ftrs(:,non_nan_ids);
        nonszr_plv_ftrs=nonszr_plv_ftrs(:,non_nan_ids);
        save(outfname,'nonszr_se_ftrs','nonszr_plv_ftrs','nonszr_se_ftrs_time_sec', ...
            'source_fnames','ftr_labels');
    end
    
    
end



disp('Done!!');

