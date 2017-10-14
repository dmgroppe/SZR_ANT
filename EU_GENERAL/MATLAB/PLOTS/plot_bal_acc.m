% Plots balanced accuracy bar plots for CLAE poster
bal_acc=[0.868, 0.837, 0.836]; % train, valid, test

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
end
set(gca,'xtick',[],'ylim',[0.5, 1],'ytick',[0.5:.1:1], ...
    'fontsize',32,'xlim',[0.5, 3.5]);
print(gcf,'-depsc','bal_acc');