tpts=1:256*10; figure(1); clf; plot(ieeg_time_sec(tpts),ieeg(tpts)); hold on;
plot(ieeg_time_sec(tpts),bp_ieeg(tpts),'r-')
plot(se_time_sec(1:60),se_ftrs(1:6,1:60),'-o');


%%
figure(1); clf;
plot(se_ftrs(1:6,1:60)','r-o');
hold on;
plot(se_ftrs([1:6]+6*4,1:60)','b-o');



%%
for decay_fact=[2:2:10],
    temp=zeros(10000,1);
    temp(1)=1;
    now_wt=1/(2^decay_fact);
    for a=2:length(temp),
        temp(a)=temp(a)*now_wt+(1-now_wt)*temp(a-1);
    end
    min_id=min(find(temp<.01));
    fprintf('Decay fact %d, it takes %d tpts (%f sec) to get below .01 threshold\n',decay_fact,min_id,min_id/10);
end



%% Plot features & classes
se_ftrs_z=zscore(se_ftrs')'; %z-score

figure(1); clf();
ax1=subplot(311);
%imagesc(se_ftrs_z);
h=plot(se_time_sec,se_ftrs_z);
title(sprintf('%s-%s, Szr%d',soz_chans_bi{cloop,1},soz_chans_bi{cloop,2},sloop));

ax2=subplot(312); plot(se_time_sec,se_class,'--b'); hold on;
plot(se_time_sec,se_szr_class,'r-');
axis tight;

ax3=subplot(313);
plot(time_dec,ieeg);
axis tight;

linkaxes([ax1 ax2 ax3],'x');


%% Plot raw data and classes
figure(1); clf();
ax1=subplot(211);
plot(ieeg);
axis tight;
title(sprintf('%s-%s, Szr%d',soz_chans_bi{cloop,1},soz_chans_bi{cloop,2},sloop));

ax2=subplot(212); plot(targ_window,'--b'); hold on;
plot(szr_class,'r-');
axis tight;

linkaxes([ax1 ax2],'x');


%%
figure(2); clf;
subplot(211);
plot(nonszr_se_ftrs')
subplot(212);
plot(nonszr_se_ftrs_time_sec);
% nonszr_ieeg(:,[1:n_nonszr_obs]+(floop-1)*n_nonszr_obs)=se_ftrs(:,use_non_szr_ids);
% nonszr_ieeg_time_sec(


%% Get directories where EU data might be stored. For some reason some
% patients have many of them
inv_subs=[1084, 1096, 1146, 253, 264, 273, 375, 384, 548, 565, 583, 590, 620, 862, 916, 922, 958, 970];
inv_subs2=[1073, 1077, 1125, 115, 1150, 139, 442, 635, 818];
inv_subs3=[13089, 13245, 732];
if ~isempty(intersect(sub_id,inv_subs)),
    inv_dir='inv';
elseif ~isempty(intersect(sub_id,inv_subs2)),
    inv_dir='inv2';
elseif ~isempty(intersect(sub_id,inv_subs3)),
    inv_dir='inv3';
else
    error('Could not find sub %d in inv, inv2, or inv3 subdirectories on external hard drive.', ...
        sub_id);
end

ieeg_root_dir=fullfile(external_root,'ValianteLabEuData','EU',inv_dir, ...
    sprintf('pat_FR_%d',sub_id),sprintf('adm_%d102',sub_id));
ieeg_dirs=get_eu_data_dirs(ieeg_root_dir);
n_ieeg_dirs=length(ieeg_dirs);
% '/Volumes/ValianteLabEuData/EU/inv/pat_FR_620/adm_620102';
% '/media/dgroppe/ValianteLabEuData/EU/inv/pat_FR_1096/adm_1096102/


%% Load list of file start and stop times
file_times_csv=fullfile(git_root,'EU_METADATA','IEEG_ON_OFF',['data_on_off_FR_' num2str(sub_id) '.csv']);
file_times=csv2Cell(file_times_csv,',',1);
n_files=size(file_times,1);
fprintf('%d data files\n',n_files);

% Get onset and offset times for each file
file_onset_sec=zeros(n_files,1);
file_offset_sec=zeros(n_files,1);
file_fname=cell(n_files,1);
file_duration_sec=zeros(n_files,1);
for a=1:n_files,
    file_onset_sec(a)=str2num(file_times{a,4});
    file_offset_sec(a)=str2num(file_times{a,6});
    file_fname{a}=file_times{a,3};
    file_duration_sec(a)=str2num(file_times{a,2});
end