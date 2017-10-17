%% Load data

%% Load yhat
%load('/Users/davidgroppe/PycharmProjects/SZR_ANT/MODELS/genLogregSe_yhat/1096_HL1_HL2_phat_szr6.mat')
ftr_root='/Users/davidgroppe/PycharmProjects/SZR_ANT/EU_GENERAL/EU_GENERAL_FTRS/SE/';

example_szr=2;
switch example_szr,
    case 1,
        sub='1096';
        ftr_fname='1096_HL3_HL4_szr6.mat';
        load(fullfile(ftr_root,sub,ftr_fname));
        yhat_root='/Users/davidgroppe/PycharmProjects/SZR_ANT/MODELS/genLogregSe_yhat/';
        load(fullfile(yhat_root,'1096_HL3_HL4_phat_szr6.mat')); % Test Patient 1, Exmple Szr 1
    otherwise,
        sub='1125';
        ftr_fname='1125_HR11_HR12_szr6.mat';
        load(fullfile(ftr_root,sub,ftr_fname));
        yhat_root='/Users/davidgroppe/Desktop/genLogregSe_1_yhat/';
        load(fullfile(yhat_root,'1125_HR11_HR12_phat_szr6.mat')); % Test Patient 1, Exmple Szr 1
end

%%
onset_tpt=min(find(se_szr_class>0.5));
onset_sec=se_time_sec(onset_tpt);
fontsize=16;
prpl=[88, 29, 175]/255;
t1=targ_raw_ieeg_sec(1);
se_t1=se_time_sec(1);
switch example_szr,
    case 1,
        xtick=[0:20:120];
    otherwise,
        xtick=[0:20:120];
end

figure(1); clf();
set(gcf,'position',[85   230   844   452]);
ax1=axes('position',[0.1300    0.6793    0.7750    0.2457]);
% ax1=subplot(311);
plot(targ_raw_ieeg_sec-onset_sec,targ_raw_ieeg,'k-'); hold on;
axis tight;
ylim=get(gca,'ylim');
%plot([1, 1]*onset_sec-t1,ylim,'r:','linewidth',3);
plot([0, 0],ylim,'r:','linewidth',3);
set(gca,'xticklabels',[],'ytick',[],'xtick',xtick);
set(gca,'LineWidth',2);


ax2=axes('position',[0.1300    0.365    0.7750    0.3157]);
imagesc(se_ftrs); hold on;
fprintf('Min max cbar values should be: %f %f\n',max(max(se_ftrs)),min(min(se_ftrs)));
ylim=get(gca,'ylim');
plot([1, 1]*onset_tpt,ylim,'r:','linewidth',3);
set(gca,'xtick',[],'ytick',[]);
axis tight

% Add colorbar
%ax2=axes('position',[0.1300    0.365    0.7750    0.3157]);
pos=[.91 .365 .02 .3157];
%pos=[.09 .365 .02 .3157];
limits=[-1, 1];
cmapName='parula';
units='';
nTick=0;
fontSize=12;
unitLocation='top';
hCbar = cbarDGplus(pos,limits,cmapName,nTick,units,unitLocation,fontSize);

% ax3=subplot(313); 
ax3=axes('position',[0.1300    0.1100    0.7750    0.2535]);
%h=plot(se_time_sec,yhat,'b-');
h=area(se_time_sec-onset_sec,yhat);
set(h,'facecolor',prpl,'edgecolor',prpl);
axis([[se_time_sec(1) se_time_sec(end)]-onset_sec 0 1]);
hold on;
ylim=get(gca,'ylim');
%plot([1, 1]*onset_sec-se_t1,ylim,'r:','linewidth',3);
plot([0, 0],ylim,'r:','linewidth',3);
set(gca,'fontsize',fontsize,'ytick',[0:.25:1],'xtick',xtick);
set(gca,'LineWidth',2);
%'TickLength',[0.025 0.025]);
set(gca, 'Layer','top')



set(gcf,'paperpositionmode','auto');
print(1,'-djpeg',sprintf('yhat_example_%d',example_szr));

disp('Done!');