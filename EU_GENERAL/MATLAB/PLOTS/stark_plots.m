%% PLOT LATERAL VIEW OF IMPLANT LOCATIONS:


%% PLOT SZR 
%load('/home/dgroppe/TWH_EEG/SV/EEG_MAT/SV_d1_sz1.mat');
%load('/home/dgroppe/TWH_EEG/SV/EEG_MAT/SV_d1_sz2.mat');
%load('/home/dgroppe/TWH_EEG/SV/EEG_MAT/SV_d1_sz3.mat'); % artifact in some
%chans
%load('/home/dgroppe/TWH_EEG/SV/EEG_MAT/SV_d1_sz4.mat'); % ditto
%load('/home/dgroppe/TWH_EEG/SV/EEG_MAT/SV_d1_sz5.mat'); % ditto
load('/home/dgroppe/TWH_EEG/SV/EEG_MAT/SV_d1_sz6.mat'); % decent
load('/home/dgroppe/TWH_EEG/SV/SV_channel_info.mat')

%%
chan_offset=2;
ieeg=matrix_bi;
[n_tpt, n_chan]=size(ieeg);
time_sec=[1:n_tpt]/Sf-160;
figure(1); clf(); hold on;
n_show_chan=50;
for chan_loop=1:n_show_chan,
    ieeg(:,chan_loop)=ieeg(:,chan_loop)-mean(ieeg(:,chan_loop));
    h=plot(time_sec,ieeg(:,chan_loop)+chan_offset*(chan_loop-1),'k-');
    clickText(h,bi_labels{chan_loop});
end
%time_sec(end)
set(gca,'xlim',[0 70],'ylim',[-chan_offset n_show_chan*chan_offset]);
set(gca,'ytick',[]);
ht=xlabel('Seconds');
set(ht,'fontsize',20);
ht=ylabel('Electrode Signals (Voltage)');
set(ht,'fontsize',20);

onset_sec=18;
ylim=get(gca,'ylim');
h=plot([1 1]*onset_sec,ylim,'r-','linewidth',2);

% ht=text(onset_sec+0.2,14,'Seizure Onset','color','r','fontsize',16, ...
%     'fontweight','bold','backgroundcolor',[1 1 1]*.3);