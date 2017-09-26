%% Identify files that have seizures in them
sub_id=1096;
[clinical_fname, clinical_szr_num, clinical_offset_sec, clinical_onset_sec]=get_szr_fnames(sub_id);
n_szrs=length(clinical_fname);

%%

%for sloop=1:n_szrs,
for sloop=1:1,
    %ieeg_fname='/Volumes/ValianteLabEuData/EU/inv/pat_FR_1096/adm_1096102/rec_109600102/109600102_0000.data';
    %     data_fname='109600102_0000.data';
    %     ieeg_fname=fullfile('/Volumes/ValianteLabEuData/EU/inv/pat_FR_1096/adm_1096102/rec_109600102/',data_fname);
    
    fprintf('Importing szr #%d\n',sloop);
    
    % Read header
    pat=bin_file(clinical_fname{sloop});
    Fs=pat.a_samp_freq;
    fprintf('FS=%f\n',Fs);
    fprintf('# of chans %d\n',pat.a_n_chan);
    fprintf('# of samples=%d\n',(pat.a_n_samples));
    
    % Get data from 30 seconds before to end of szr
    
    
    %%
    fszr_onset_tpt=round((clinical_onset_sec(a)-file_onset_sec(file_id))*Fs+1);
    fszr_offset_tpt=round((clinical_offset_sec(a)-file_onset_sec(file_id))*Fs+1);
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
    
    
end

%%
% ignore_chans={'EOG1','EOG2','EMG','TP1','TP2','TP3','TP4','FP1','FP2', ...
%     'F3','F4','C3','C4','P3','P4','O1','O2','F7','F8','T3','T4','T5', ...
%     'T6','FZ','CZ'};
bipolar_labels=derive_bipolar_pairs(sub_id);

%%
%use_chans={'EOG1','EOG2','EMG'};
%use_chans={'HL4','HL2'};
%n_chan=length(use_chans);
n_chan=size(bipolar_labels,1);
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

%% Butterfly plot
ieeg_tpt=size(ieeg,2);
figure(1); clf;
plot(1:ieeg_tpt,ieeg'); hold on;
xlim=get(gca,'xlim');
ylim=get(gca,'ylim');
% plot([1, 1]*Fs*10,ylim,'r-');
plot(1:ieeg_tpt,single(clip_szr_class)*ylim(2),'r-','linewidth',4);
%plot(1:ieeg_tpt,clip_szr_class*1000000,'r-','linewidth',4);
% set(gca,'xlim',[0 Fs*20]);
axis tight;

%% Strat plot
voffset=1000;
ieeg_tpt=size(ieeg,2);
figure(2); clf;
onset_chans={'TBA1','TBA2'};
for cloop=1:n_chan,
    indiv_chans=strsplit(ieeg_labels{cloop},'-');
    onset_chan=1;
    for biloop=1:2,
        if isempty(findStrInCell(indiv_chans{biloop},onset_chans)),
            onset_chan=0;
        end
    end
    if onset_chan,
        h=plot(1:ieeg_tpt,ieeg(cloop,:)+(cloop-1)*voffset,'m-');
        disp(cloop)
    else
        h=plot(1:ieeg_tpt,ieeg(cloop,:)+(cloop-1)*voffset,'k-');
    end
    clickText(h,ieeg_labels{cloop});
    hold on;
end
ylim=[-voffset, voffset*n_chan];
xlim=get(gca,'xlim');
%ylim=get(gca,'ylim');
set(gca,'ylim',ylim);
% plot([1, 1]*Fs*10,ylim,'r-');
plot(1:ieeg_tpt,single(clip_szr_class)*ylim(2),'r--','linewidth',1);
% set(gca,'ytick',0:(n_chan-1)*voffset);
%plot(1:ieeg_tpt,clip_szr_class*1000000,'r-','linewidth',4);
% set(gca,'xlim',[0 Fs*20]);
axis tight;