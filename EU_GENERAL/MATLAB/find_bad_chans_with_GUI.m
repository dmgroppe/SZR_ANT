% This script loads the power spectra density from randomly sampled
% non-ictal data and plots it with a GUI that allows one to select bad
% channels.
%
% Bad channels are then output as a textfile here:
%/Users/davidgroppe/PycharmProjects/SZR_ANT/EU_METADATA/BAD_CHANS

%% Load PSD data
%sub=264;
sub=1125;
psd_fname=sprintf('/Users/davidgroppe/PycharmProjects/SZR_ANT/EU_METADATA/PSD/%d_non_szr_psd.mat',sub);
load(psd_fname);

%%
n_chan=size(bipolar_labels,1);
n_files=size(psd_samps,1);
chan_labels_str=cell(n_chan,1);
for a=1:n_chan,
   chan_labels_str{a}=[bipolar_labels{a,1} '-'  bipolar_labels{a,2}];
end


%% Create ecog variable
mn_psd=squeeze(mean(psd_samps,1));
se_psd=squeeze(std(psd_samps,0,1))/sqrt(n_files);
global ecog
ecog=[];
ecog.filename=psd_fname;
ecog.psd.freqs=f;
ecog.psd.pwr=mn_psd';
%ecog.ftrip.label=pat.a_channs_cell;
ecog.ftrip.label=chan_labels_str;
ecog.bad_chans=[];
ecog.lnnz=50;
bad_chan_GUI();


disp('Select bad channels with GUI and then run rest of script manually.');
return



%% Plot good & bad chams with stderr
good_chan_ids=get_good_chans(ecog);
bad_chan_ids=setdiff(1:n_chan,good_chan_ids);
figure(10);
clf();
subplot(1,2,1); hold on;
hh=plot(f,mn_psd(:,good_chan_ids));
ct=0;
for a=good_chan_ids,
    ct=ct+1;
    h=shadedErrorBar(f,mn_psd(:,a),se_psd(:,a),[]);
    h.patch.FaceAlpha=0.2;
    h.patch.FaceColor=hh(ct).Color;
    h.mainLine.Color=hh(ct).Color;
    clickText(h.mainLine,chan_labels_str{a});
    %shadedErrorBar(x,mean(y,1),std(y),'g');
    %plot(f,mn_psd(:,good_chan_ids));
end
axis tight;
xlabel('Hz');
ylabel('Log Pwr');
title('Good Channels');

subplot(1,2,2); hold on;
hh=plot(f,mn_psd(:,bad_chan_ids));
ct=0;
for a=bad_chan_ids,
    ct=ct+1;
    h=shadedErrorBar(f,mn_psd(:,a),se_psd(:,a),[]);
    h.patch.FaceAlpha=0.2;
    h.patch.FaceColor=hh(ct).Color;
    h.mainLine.Color=hh(ct).Color;
    clickText(h.mainLine,chan_labels_str{a});
    %shadedErrorBar(x,mean(y,1),std(y),'g');
    %plot(f,mn_psd(:,good_chan_ids));
end
axis tight;
xlabel('Hz');
title('Bad Channels');
ylabel('Log Pwr');


%% Output bad channels to text file
out_fname=sprintf('/Users/davidgroppe/PycharmProjects/SZR_ANT/EU_METADATA/BAD_CHANS/bad_chans_%d.txt',sub);
fid=fopen(out_fname,'w');
for a=bad_chan_ids,
   fprintf(fid,'%s\n',chan_labels_str{a}); 
end
fclose(fid);