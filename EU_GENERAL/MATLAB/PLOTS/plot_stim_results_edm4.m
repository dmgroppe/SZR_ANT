% This script gathers the stimulation performance for each subject using
% various EDM yhat smoothing parameters and plots them

% Gather results from each subject
use_subs=[620, 565, 970, 1096, 1077, 264, 273, 862, 1125];
%yhat error: 590, 253
%use_subs=[565, 620];
%use_subs=[620, 565, 273, 862, 1125];
%redo 1096
n_sub=length(use_subs);

sub_str=cell(n_sub+1,1);
for sloop=1:n_sub
    sub_str{sloop}=num2str(use_subs(sloop));
end
sub_str{n_sub+1}='Mean';

mn_abs_stim=[];
edm_wts=[];
fp_per_day=[];
for sloop=1:n_sub
    sub=use_subs(sloop);
    fprintf('Working on sub %d\n',sub);
    
    stim_stats=grab_sub_stim_results(sub);
    if isempty(edm_wts)
        % first time through loop
        n_edm_wt=length(stim_stats.grand_edm_wts);
        mn_abs_stim=zeros(n_edm_wt,n_sub);
        md_abs_stim=zeros(n_edm_wt,n_sub);
        fp_per_day=zeros(n_edm_wt,n_sub);
        pcnt_under_10sec=zeros(n_edm_wt,n_sub);
        edm_wts=stim_stats.grand_edm_wts;
    else
        
    end
    mn_abs_stim(:,sloop)=stim_stats.grand_mn_stim_lat;
    md_abs_stim(:,sloop)=stim_stats.grand_md_stim_lat;
    fp_per_day(:,sloop)=stim_stats.grand_fp_per_day;
    pcnt_under_10sec(:,sloop)=stim_stats.pcnt_within_10sec;
end

%%
% Get unique color for each subject
CT=cbrewer('qual','Set3',9);
CT(2,:)=[.2, .5, .1];
CT=cbrewer('qual','Paired',9);

figure(2); clf;
% Median Stim Latency
subplot(1,3,1); hold on;
for a=1:n_sub,
    h=plot(a,md_abs_stim(5,a),'o','markersize',6,'linewidth',4);
    set(h,'color',CT(a,:));
end
set(gca,'yscale','log','fontsize',22,'ygrid','on','linewidth',1);
ylabel('Seconds');
title({'Median Absolute','Szr Stim Latency'});
xlabel('Patient');
set(gca,'xtick',1:9);

subplot(1,3,2); hold on;
for a=1:n_sub,
    h=plot(a,pcnt_under_10sec(5,a),'o','markersize',6,'linewidth',4);
    set(h,'color',CT(a,:));
end
set(gca,'fontsize',22,'ygrid','on','linewidth',1);
ylabel('Percent of All Szrs');
title({'Stimulations within','10 sec of Onset'});
xlabel('Patient');
set(gca,'xtick',1:9);

subplot(1,3,3); hold on;
for a=1:n_sub,
    h=plot(a,fp_per_day(5,a),'o','markersize',6,'linewidth',4);
    set(h,'color',CT(a,:));
end
set(gca,'fontsize',22,'ygrid','on','linewidth',1);
ylabel('FP per Day');
title({'False Positive Rate'});
set(gcf,'paperpositionmode','auto');
xlabel('Patient');
set(gca,'xtick',1:9);
v=axis();
mn=mean(fp_per_day(5,:));
prple=[148,0,211]/255;
plot(v(1:2),[1, 1]*600,'--','color',prple);
ht=text(0.5,550,'NeuroPace Lower Bound','color',prple);
set(ht,'horizontalalignment','left','fontsize',16);
plot(v(1:2),[1, 1]*mn,'m--');
ht=text(0.5,mn+50,'Mean FPR');
set(ht,'horizontalalignment','left','fontsize',16,'color','m');

set(gcf,'paperpositionmode','auto');
print -f2 -depsc edm4_rslts

%% Plot results for all EDM values
% Plot for the best EDM value (a value of 4)
figure(1); clf;
subplot(4,1,1);
plot(edm_wts,mn_abs_stim,'-o'); hold on;
plot(edm_wts,mean(mn_abs_stim,2),'r-o','linewidth',2);
set(gca,'yscale','log');
ylabel({'MEAN Absolute','Stim Latency (Seconds)'});
v=axis();
axis([edm_wts(1) edm_wts(end) 0 1000]);
set(gca,'ytick',[0 10 100]);

subplot(4,1,2);
plot(edm_wts,md_abs_stim,'-o'); hold on;
plot(edm_wts,mean(md_abs_stim,2),'r-o','linewidth',2);
set(gca,'ytick',[0 10 100]);
set(gca,'yscale','log');
ylabel({'MEDIAN Absolute','Stim Latency (Seconds)'});
axis([edm_wts(1) edm_wts(end) 0 1000]);

subplot(4,1,3);
plot(edm_wts,pcnt_under_10sec,'-o'); hold on;
plot(edm_wts,mean(pcnt_under_10sec,2),'r-o','linewidth',2);
axis([edm_wts(1) edm_wts(end) 0 100]);
ylabel({'% of szrs stimulated','within 10 sec on onset.'});

subplot(4,1,4);
plot(edm_wts,fp_per_day,'-o'); hold on;
plot(edm_wts,mean(fp_per_day,2),'r-o','linewidth',2);
% set(gca,'yscale','log');
xlabel('yhat EDM Weight');
axis([edm_wts(1) edm_wts(end) 400 1200]);
plot([edm_wts(1), edm_wts(end)],[1, 1]*600,'k--');
ylabel({'MEAN False','Positives/Day'});
legend(sub_str);

set(gcf,'paperpositionmode','auto');
%print -f1 -depsc stim_per_edm