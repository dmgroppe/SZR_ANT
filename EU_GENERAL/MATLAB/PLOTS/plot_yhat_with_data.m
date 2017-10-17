% This script plots raw data, true class, class hat, features (z-scored),
% spectrogram, and t-scored spectrogram for a szr
%
% It is useful for seeing what features pickup and miss

%% Load data
ftr_root='/Users/davidgroppe/PycharmProjects/SZR_ANT/EU_GENERAL/EU_GENERAL_FTRS/SE/';
% sub=1096;
% chan='HL2-HL3';
%chan='HL3-HL4';
% szr_num=6;

sub=565;
chan='HL4-HL5';
szr_num=6;

dash_id=find(chan=='-');
chan1=chan(1:dash_id-1);
chan2=chan(dash_id+1:end);
ftr_fname=sprintf('%d_%s_%s_szr%d.mat',sub,chan1,chan2,szr_num);
fprintf('Loading %s\n',ftr_fname);
%ftr_fname='1096_HL3_HL4_szr6.mat';
load(fullfile(ftr_root,num2str(sub),ftr_fname));

% Remove _ from feature labels
for a=1:size(ftr_labels,1),
    use_ids=find(ftr_labels{a}~='_');
    ftr_labels{a}=ftr_labels{a}(use_ids);
end

% Scale all features from 0 to 1
% for a=1:size(ftr_labels,1),
%     se_ftrs(a,:)=se_ftrs(a,:)-min(se_ftrs(a,:));
%     se_ftrs(a,:)=se_ftrs(a,:)/max(se_ftrs(a,:));
% end

%% Load yhat
%load('/Users/davidgroppe/PycharmProjects/SZR_ANT/MODELS/genLogregSe_yhat/1096_HL1_HL2_phat_szr6.mat')
yhat_root='/Users/davidgroppe/PycharmProjects/SZR_ANT/MODELS/genLogregSe_3_yhat/';
%load(fullfile(yhat_root,'1096_HL3_HL4_phat_szr6.mat'))
load(fullfile(yhat_root,sprintf('%d_%s_%s_phat_szr%d.mat',sub,chan1,chan2,szr_num)));


%% Load PSD
% /Users/davidgroppe/PycharmProjects/SZR_ANT/EU_METADATA/PSD/1096_non_szr_psd.mat
psd_fname=sprintf( ...
    '/Users/davidgroppe/PycharmProjects/SZR_ANT/EU_METADATA/PSD/%d_non_szr_psd.mat',sub);
if exist(psd_fname,'file'),
    psd_exists=1;
    load(psd_fname);
    chan_id=NaN;
    for a=1:size(bipolar_labels,1),
        if strcmpi(bipolar_labels{a,1},chan1) && strcmpi(bipolar_labels{a,2},chan2),
            chan_id=a;
        end
    end
    if isnan(chan_id),
        error('Could not find index to channel %s-%s in PSD data',chan1,chan2);
    end
    good_psd_ids=find(psd_samps(:,1,chan_id));
    mn_psd=squeeze(mean(psd_samps(good_psd_ids,:,:),1));
    se_psd=squeeze(std(psd_samps(good_psd_ids,:,:),1,1))/sqrt(size(psd_samps,1));
else
    psd_exists=0;
    mn_psd=zeros(length(sgram_f),1);
    se_psd=ones(length(sgram_f),1);
end

%% Plot Mean PSD
if psd_exists,
    figure(2); clf; hold on;
    %plot(sgram_f,mn_psd(:,chan_id),'k-','linewidth',2);
    h=shadedErrorBar(sgram_f,mn_psd(:,chan_id),se_psd(:,chan_id),[]);
    plot(sgram_f,squeeze(psd_samps(:,:,chan_id)));
    hold on;
end

%% Bands
bands=[0 4; 4 8; 8 13; 13 30; 30 50; 70 100];
band_labels={'DeltaMag','ThetaMag','AlphaMag','BetaMag','GammaMag','HGammaMag'};


%% Plot raw data, yhat, ftrs, & spectrograms
figure(1); clf();
set(gcf,'position',[85   170   844   512]);
ax1=subplot(511);
plot(targ_raw_ieeg_sec,targ_raw_ieeg,'b-');
axis tight;
ht=title(ftr_fname);
set(ht,'interpreter','none');
ylabel('Volatge');

% True Szr class and estimated szr class (note szrs start wit 5 sec before
% clinician onset
ax2=subplot(512); hold on;
area(se_time_sec,yhat);
plot(se_time_sec,se_szr_class,'r-','linewidth',2);
%plot(se_time_sec,yhat,'b--');
axis tight;
ylabel('P(Szr)');
% set(gca,'ylim',[0 1],'ytick',[0, 1]);

% Z-scored ftrs
ax3=subplot(513);
h=plot(se_time_sec,ftrs_z); hold on;
for floop=1:length(h),
    clickText(h(floop),ftr_labels{floop});
end
h=plot(se_time_sec,ftrs_z(1,:),'-','linewidth',2,'color',[250 175 63]/256); % Delta
clickText(h,'Delta');
h=plot(se_time_sec,ftrs_z(2,:),'r-','linewidth',2); % Theta
clickText(h,'Theta');
h=plot(se_time_sec,ftrs_z(3,:),'-','linewidth',2,'color',[158 40 226]/256); % Alpha
clickText(h,'Alpha');
h=plot(se_time_sec,ftrs_z(4,:),'b-','linewidth',2); % Beta
clickText(h,'Beta');
h=plot(se_time_sec,ftrs_z(5,:),'g-','linewidth',2); % Gamma
clickText(h,'Gamma');
h=plot(se_time_sec,ftrs_z(6,:),'m-','linewidth',2); % High Gamma
clickText(h,'HGamma');
axis tight
ylabel('Z');

% Spectrogram of Szr with freq bands marked with white lines
ax4=subplot(514);
h=imagesc(sgram_S');
hold on;
ytick=get(gca,'ytick');
yticklabels=cell(length(ytick),1);
for a=1:length(ytick),
    yticklabels{a}=num2str(sgram_f(ytick(a)));
end
xtick=get(gca,'xtick');
xticklabels=cell(length(xtick),1);
for a=1:length(xtick),
    xticklabels{a}=num2str(round(sgram_t(xtick(a))));
end
set(gca,'ydir','normal','xticklabel',xticklabels,'yticklabel',yticklabels);
ylabel('Hz');
axis tight
% Indicate borders between frequency bands with white lines
xlim=get(gca,'xlim');
for bloop=1:size(bands,1),
    hz_id=findTpt(bands(bloop,2),sgram_f);
    disp(hz_id);
    plot(xlim,[1 1]*hz_id,'w-');
end

if psd_exists,
    % t-scored Spectrogram of Szr with freq bands marked with white lines
    ax5=subplot(515);
    sgram_tscore=sgram_S-repmat(mn_psd(:,chan_id)',length(sgram_t),1);
    sgram_tscore=sgram_tscore./repmat(se_psd(:,chan_id)',length(sgram_t),1);
    h=imagesc(sgram_tscore'); hold on;
    ytick=get(gca,'ytick');
    yticklabels=cell(length(ytick),1);
    for a=1:length(ytick),
        yticklabels{a}=num2str(sgram_f(ytick(a)));
    end
    xtick=get(gca,'xtick');
    xticklabels=cell(length(xtick),1);
    for a=1:length(xtick),
        xticklabels{a}=num2str(round(sgram_t(xtick(a))));
    end
    set(gca,'ydir','normal','xticklabel',xticklabels,'yticklabel',yticklabels);
    ylabel('Hz');
    xlabel('Sec');
    axis tight
    % Indicate borders between frequency bands with white lines
    xlim=get(gca,'xlim');
    for bloop=1:size(bands,1),
        hz_id=findTpt(bands(bloop,2),sgram_f);
        disp(hz_id);
        plot(xlim,[1 1]*hz_id,'w-');
    end
end
linkaxes([ax1 ax2 ax3],'x');

% print(1,'-djpeg','