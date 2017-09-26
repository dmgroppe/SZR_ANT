
            
            %%
            fszr_onset_tpt=round(Fs*cli_szr_info(sloop).clinical_onset_sec);
            fszr_offset_tpt=round(Fs*cli_szr_info(sloop).clinical_offset_sec);
            fprintf('Szr onset tpt %d\n',fszr_onset_tpt);
            fprintf('Szr offset tpt %d\n',fszr_offset_tpt);
            szr_class=zeros(pat.a_n_samples,1,'int8');
            szr_class(fszr_onset_tpt:fszr_offset_tpt)=1;
            
            % Identify target window onset for classifier 5 sec before clinician onset
            targ_window=zeros(pat.a_n_samples,1,'int8');
            targ_onset_tpt=fszr_onset_tpt-round(Fs*5);
            if targ_onset_tpt<0,
                targ_onset_tpt=1;
            end
            
            % Identify target window offset for classifier=clinician offset
            targ_offset_tpt=fszr_offset_tpt;
            if targ_offset_tpt>pat.a_n_samples,
                targ_offset_tpt=pat.a_n_samples;
            end
            targ_window(targ_onset_tpt:targ_offset_tpt)=1;
            
            %%
            preonset_tpts=Fs*15; % 15 second preonset baseline
            clip_onset_tpt=fszr_onset_tpt-preonset_tpts; %time pt at which to START data import
            if clip_onset_tpt<1,
                clip_onset_tpt=1;
            end
            

            % Figure out how many feature time points there are
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
            
            % Compute features with EDM for all data
            se_ftrs=zeros(n_lags*n_bands,n_ftr_wind);

            % Compute raw feature without any smoothing
            for bloop=1:n_bands,
                % Apply causal butterworth filter
                bp_ieeg=butterfiltMK(ieeg,256,[bands(bloop,1) bands(bloop,2)],0,4);
                
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
            
            % Remove initial time points polluted by edge effects
            se_ftrs=se_ftrs(:,edge_pts:end);
            se_time_sec=se_time_sec(edge_pts:end);
            se_class=se_class(edge_pts:end);
            se_szr_class=se_szr_class(edge_pts:end);
            
            if 0,
                % Code for checking results
                se_ftrs_z=zscore(se_ftrs')'; %z-score
                
                figure(1); clf();
                ax1=subplot(311);
                %imagesc(se_ftrs_z);
                h=plot(se_time_sec,se_ftrs_z);
                title(sprintf('%s-%s, Szr%d',soz_chans_bi{cloop,1},soz_chans_bi{cloop,2},sloop));
                
                ax2=subplot(312); plot(se_time_sec,se_class,'--b'); hold on;
                plot(se_time_sec,se_szr_class,'r-');
                axis tight;
                
                ax3=subplot(313);
                plot(time_dec,ieeg);
                axis tight;
                
                linkaxes([ax1 ax2 ax3],'x');
            end
            
            %% Grab only features during target window
            se_targ_ids=find(se_class>=0.5);
            se_ftrs=se_ftrs(:,se_targ_ids);
            se_time_sec=se_time_sec(se_targ_ids);
            se_class=se_class(se_targ_ids);
            se_szr_class=se_szr_class(se_targ_ids);
            
            n_tpt_ct(cloop)=n_tpt_ct(cloop)+length(se_targ_ids); % Keep track
            % of how many target observations were captured for each
            % electrode so that we can sample an equal number of non-target
            % examples
            
            %% Save just target window time points
            outdir=fullfile(root_dir,'EU_GENERAL','EU_GENERAL_FTRS','SE');
            if ~exist(outdir,'dir'),
               mkdir(outdir); 
            end
            outfname=fullfile(outdir,sprintf('%d_%s_%s_szr%d',sub_id, ...
                soz_chans_bi{cloop,1},soz_chans_bi{cloop,2}, ...
                cli_szr_info(sloop).clinical_szr_num));
            szr_fname=cli_szr_info(sloop).clinical_fname;
%             fprintf('Saving szr features to %s\n',outfname);
%             save(outfname,'se_ftrs','se_time_sec','se_szr_class', ...
%                 'ftr_labels','szr_fname');
            disp('there');
        end
        
    end
end
