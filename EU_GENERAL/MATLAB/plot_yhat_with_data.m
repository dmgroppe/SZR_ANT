%% Load data
ftr_root='/Users/davidgroppe/PycharmProjects/SZR_ANT/EU_GENERAL/EU_GENERAL_FTRS/SE/';
sub='1096';
ftr_fname='1096_HL1_HL2_szr6.mat';
load(fullfile(ftr_root,sub,ftr_fname));


%%
load('/Users/davidgroppe/PycharmProjects/SZR_ANT/MODELS/genLogregSe_yhat/1096_HL1_HL2_phat_szr6.mat')


%%
figure(1); clf();
ax1=subplot(311);
plot(targ_raw_ieeg_sec,targ_raw_ieeg,'b-');
axis tight;
title(ftr_fname);

ax2=subplot(312); 
plot(se_time_sec,se_szr_class,'r-'); hold on;
plot(se_time_sec,yhat,'b--');
axis tight;

ax3=subplot(313); 
h=plot(se_time_sec,se_ftrs);
for floop=1:length(h),
    clickText(h(floop),ftr_labels{floop},'none');
end
axis tight

linkaxes([ax1 ax2 ax3],'x');
