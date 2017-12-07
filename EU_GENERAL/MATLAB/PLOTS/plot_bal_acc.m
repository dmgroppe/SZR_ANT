% Plots balanced accuracy bar plots for CLAE poster
%bal_acc=[0.868, 0.837, 0.836]; % train, valid, test
bal_acc=[0.937, 0.836, 0.854]; % train, valid, test
low_cis=[0.930, 0.747, 0.807];
hi_cis=[0.944, 0.925, 0.901];

% Validation Data
% 0.836249581547
% 0.747432385681
% 0.925066777413
% Training Data
% 0.93707112363
% 0.930004703389
% 0.944137543871

% Test Data
%Mean (95p CI) bacc: 0.854484 (0.807916-0.901052)

% Mean across subs:
% Mean (95p CI) bacc: 0.854484 (0.807916-0.901052)
% Mean (95p CI) spec: 0.972296 (0.949523-0.995068)
% Mean (95p CI) sens: 0.736673 (0.651675-0.821671)
% Mean (95p CI) AUC: 0.854484 (0.807916-0.901052)



clear rgb
rgb{1}=[88, 29, 175]/255;
rgb{2}=[88, 29, 175]/255;
rgb{3}=[88, 29, 175]/255;

figure(1);
clf();
hold on;
%h=bar(bal_acc);
for a=1:3,
    h=bar(a,bal_acc(a));
    set(h,'facecolor',rgb{a});
    plot([1, 1]*a,[low_cis(a), hi_cis(a)],'k-','linewidth',3);
end
set(gca,'xtick',[],'ylim',[0.5, 1],'ytick',[0.5:.1:1], ...
    'fontsize',32,'xlim',[0.5, 3.5]);
print(gcf,'-depsc','bal_acc');