function cli_szr_info=get_szr_fnames(sub_id,file_dir)
%function cli_szr_info=get_szr_fnames(sub_id,file_dir)
% 
% sub_id - subject id (e.g., 1096)
% file_dir-path to where the ieeg data are stored
%
% Output:
% cli_szr_info =  struct array with fields:
%     clinical_fname
%     clinical_onset_sec
%     clinical_offset_sec
%     clinical_szr_num


%% Load szr onset and offset times
%'/home/dgroppe/GIT/SZR_ANT/
if ismac,
    git_root='/Users/davidgroppe/PycharmProjects/SZR_ANT/';
else
    git_root='/home/dgroppe/GIT/SZR_ANT/';
end
szr_times_csv=fullfile(git_root,'EU_METADATA','SZR_TIMES',['szr_on_off_FR_' num2str(sub_id) '.csv']);
szr_times=csv2Cell(szr_times_csv,',',1);
n_szrs=size(szr_times,1);

clinical_ids=[];
for a=1:n_szrs,
    if strcmpi(szr_times{a,7},'Clinical'),
        clinical_ids=[clinical_ids a];
    end
end
n_clinical=length(clinical_ids);
fprintf('%d clinical szrs\n',n_clinical);

% Get onset and offset times of clinical seizures
clinical_onset_sec=zeros(n_clinical,1);
clinical_offset_sec=zeros(n_clinical,1);
clinical_onset_sec=zeros(n_clinical,1);
clinical_offset_sec=zeros(n_clinical,1);
clinical_szr_num=zeros(n_clinical,1);
clinical_soz_chans=cell(n_clinical,1);
for a=1:n_clinical,
    temp_str=szr_times{clinical_ids(a),2};
    % Remove nuisance characters
    temp_str=strrep(temp_str,'''','');
    temp_str=strrep(temp_str,'[','');
    temp_str=strrep(temp_str,']','');
    clinical_soz_chans{a}=strsplit(temp_str,' ');
    clinical_szr_num(a)=str2num(szr_times{clinical_ids(a),1});
    clinical_offset_sec(a)=str2num(szr_times{clinical_ids(a),3});
    clinical_onset_sec(a)=str2num(szr_times{clinical_ids(a),5});
end


%% Load list of file start and stop times
file_times_csv=fullfile(git_root,'EU_METADATA',['data_on_off_FR_' num2str(sub_id) '.csv']);
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


%% For each clinical szr import the data plus ?? minutes before and after szr
clinical_fname=cell(1,n_clinical);
clear cli_szr_info
for a=1:n_clinical,
%for a=1:1,
    fprintf('Trying to import clinical szr#%d\n',a);
    % Find out which file the szr is in
    file_id=0;
    for file_pointer=1:n_files,
        if clinical_onset_sec(a)>=file_onset_sec(file_pointer) && ...
                clinical_onset_sec(a)<file_offset_sec(file_pointer)
            file_id=file_pointer;
            break;
        end
    end
    if file_id==0,
        fprintf('Could NOT find szr#%d!!!!!!!!!!!\n',a);
    else
        hdr_fname=file_fname{file_pointer};
        hdr_stem=hdr_fname(1:(find(hdr_fname=='.')-1));
        data_fname=[hdr_stem '.data'];
        fprintf('Szr is in file %s\n',data_fname);
        cli_szr_info(a).clinical_fname=fullfile(file_dir,data_fname);
        cli_szr_info(a).clinical_onset_sec=clinical_onset_sec(a)-file_onset_sec(file_id);
        cli_szr_info(a).clinical_offset_sec=clinical_offset_sec(a)-file_onset_sec(file_id);
        cli_szr_info(a).clinical_szr_num=clinical_szr_num(a);
        cli_szr_info(a).clinical_soz_chans=clinical_soz_chans{a};
        %         clinical_fname{a}=fullfile(file_dir,data_fname);
        %         clinical_onset_sec(a)=clinical_onset_sec(a)-file_onset_sec(file_id);
        %         clinical_offset_sec(a)=clinical_offset_sec(a)-file_onset_sec(file_id);
        % pickup here ?? I think I want import_all_times_7chans.m
    end
end


