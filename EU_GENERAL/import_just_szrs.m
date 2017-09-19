%% Identify files that have seizures in them
sub_id=1096;
if ismac,
   ieeg_dir='/Volumes/ValianteLabEuData/EU/inv/pat_FR_1096/adm_1096102/rec_109600102';
else
   ieeg_dir='/media/dgroppe/ValianteLabEuData/EU/inv/pat_FR_1096/adm_1096102/rec_109600102/'; 
end

sub_id=1084;
ieeg_dir='/media/dgroppe/ValianteLabEuData/EU/inv/pat_FR_1084/adm_1084102/rec_108400102';

cli_szr_info=get_szr_fnames(sub_id,ieeg_dir);
n_szrs=length(cli_szr_info);

%%
bipolar_labels=derive_bipolar_pairs(sub_id);
n_chan=size(bipolar_labels,1);

%%
for sloop=1:n_szrs,
%for sloop=1:1,
    %ieeg_fname='/Volumes/ValianteLabEuData/EU/inv/pat_FR_1096/adm_1096102/rec_109600102/109600102_0000.data';
    %     data_fname='109600102_0000.data';
    %     ieeg_fname=fullfile('/Volumes/ValianteLabEuData/EU/inv/pat_FR_1096/adm_1096102/rec_109600102/',data_fname);
    
    fprintf('Importing szr #%d\n',sloop);
    
    % Read header
    pat=bin_file(cli_szr_info(sloop).clinical_fname);
    Fs=pat.a_samp_freq;
    if isempty(Fs),
       error('Could not find file: %s',cli_szr_info(sloop).clinical_fname);
    end
    fprintf('FS=%f\n',Fs);
    fprintf('# of chans %d\n',pat.a_n_chan);
    fprintf('# of samples=%d\n',(pat.a_n_samples));
    
    % Get data from 30 seconds before to end of szr
    
    
    %%
    fszr_onset_tpt=round(Fs*cli_szr_info(sloop).clinical_onset_sec);
    fszr_offset_tpt=round(Fs*cli_szr_info(sloop).clinical_offset_sec);
    fprintf('Szr onset tpt %d\n',fszr_onset_tpt);
    fprintf('Szr offset tpt %d\n',fszr_offset_tpt);
    szr_class=zeros(pat.a_n_samples,1,'int8');
    szr_class(fszr_onset_tpt:fszr_offset_tpt)=1;
    
    %%
    preonset_tpts=Fs*30; % 30 second preonset baseline
    clip_onset_tpt=fszr_onset_tpt-preonset_tpts;
    if clip_onset_tpt<1,
        clip_onset_tpt=1;
    end
    
    if fszr_offset_tpt>pat.a_n_samples,
        clip_offset_tpt=pat.a_n_samples;
        offset_missed=1;
    else
        clip_offset_tpt=fszr_offset_tpt;
        offset_missed=0;
    end
    clip_szr_class=szr_class(clip_onset_tpt:clip_offset_tpt);
    
    ieeg_labels=cell(n_chan,1);
    for chan_loop=1:n_chan,
        pat.a_channs_cell={bipolar_labels{chan_loop,1}}; % Channels to import
        %ieeg(1:n_chan,:)=pat.get_bin_signals([],[]);
        ieeg_temp1=pat.get_bin_signals(clip_onset_tpt,clip_offset_tpt);
        
        pat.a_channs_cell={bipolar_labels{chan_loop,2}}; % Channels to import
        ieeg_temp2=pat.get_bin_signals(clip_onset_tpt,clip_offset_tpt);
        
        if chan_loop==1,
            n_tpt=size(ieeg_temp1,2);
            ieeg=zeros(n_chan,n_tpt);
        end
        ieeg(chan_loop,:)=ieeg_temp1-ieeg_temp2;
        ieeg_labels{chan_loop,1}=[bipolar_labels{chan_loop,1} '-' bipolar_labels{chan_loop,2}];
    end
    
    %% Strat plot
    voffset=1000;
    ieeg_tpt=size(ieeg,2);
    figure(sloop); clf;
    %onset_chans={'TBA1','TBA2'};
    onset_chans=cli_szr_info(sloop).clinical_soz_chans;
    time_sec=[1:ieeg_tpt]/Fs;
    for cloop=1:n_chan,
        indiv_chans=strsplit(ieeg_labels{cloop},'-');
        onset_chan=0;
        for biloop=1:2,
            if ~isempty(findStrInCell(indiv_chans{biloop},onset_chans)),
                onset_chan=1;
            end
        end
        if onset_chan,
            h=plot(time_sec,ieeg(cloop,:)+(cloop-1)*voffset,'m-');
        else
            h=plot(time_sec,ieeg(cloop,:)+(cloop-1)*voffset,'k-');
        end
        clickText(h,ieeg_labels{cloop});
        hold on;
    end
    ylim=[-voffset, voffset*n_chan];
    xlim=get(gca,'xlim');
    %ylim=get(gca,'ylim');
    set(gca,'ylim',ylim,'ytick',[]);
    % plot([1, 1]*Fs*10,ylim,'r-');
    plot(time_sec,single(clip_szr_class)*ylim(2),'r--','linewidth',1);
    % set(gca,'ytick',0:(n_chan-1)*voffset);
    %plot(1:ieeg_tpt,clip_szr_class*1000000,'r-','linewidth',4);
    % set(gca,'xlim',[0 Fs*20]);
    xlabel('Sec');
    ht=title(sprintf('FR_%d: Clin Szr %d',sub_id,sloop));
    set(ht,'interpreter','none')
    axis tight;

    fprintf('Done with szr %d/%d\n',sloop,n_szrs);

    %% Save figure
    fig_path=fullfile('SZR_FIGS',num2str(sub_id));
    if ~exist(fig_path,'dir')
        mkdir(fig_path);
    end
    fig_fname=fullfile(fig_path,sprintf('strat_szr%d.fig',sloop));
    savefig(sloop,fig_fname,'compact');
    
    %% Butterfly plot
%     figure(2); clf;
%     plot(1:ieeg_tpt,ieeg'); hold on;
%     xlim=get(gca,'xlim');
%     ylim=get(gca,'ylim');
%     % plot([1, 1]*Fs*10,ylim,'r-');
%     plot(1:ieeg_tpt,single(clip_szr_class)*ylim(2),'r-','linewidth',4);
%     %plot(1:ieeg_tpt,clip_szr_class*1000000,'r-','linewidth',4);
%     % set(gca,'xlim',[0 Fs*20]);
%     axis tight;
    
end


disp('Done!!');

