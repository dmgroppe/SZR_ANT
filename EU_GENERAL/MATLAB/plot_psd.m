% Script for plotting pwr spectrum density produced by compute_psd_interictal.m

%%
mn_psd=squeeze(mean(psd_samps,1));
[n_samp, n_freq, n_chan]=size(psd_samps);
se_psd=squeeze(std(psd_samps,0,1))/sqrt(n_samp);

figure(1); clf();
subplot(1,2,1);
h=plot(f,mn_psd);
axis tight;
for cloop=1:length(h),
   clickText(h(cloop),[bipolar_labels{cloop,1} '-'  bipolar_labels{cloop,2}]);
end
xlabel('Hz');
ylabel('dB');

subplot(1,2,2);
hold on;
for cloop=1:n_chan,
    hh=shadedErrorBar(f,mn_psd(:,cloop),se_psd(:,cloop));
    set(hh.patch,'FaceColor',h(cloop).Color,'FaceAlpha',0.5);
    set(hh.mainLine,'Color',h(cloop).Color);
    clickText(hh.mainLine,[bipolar_labels{cloop,1} '-'  bipolar_labels{cloop,2}]);
    clickText(hh.patch,[bipolar_labels{cloop,1} '-'  bipolar_labels{cloop,2}]);
    for a=1:2,
        set(hh.edge(a),'Color',h(cloop).Color);
    end
end
axis tight;
xlabel('Hz');