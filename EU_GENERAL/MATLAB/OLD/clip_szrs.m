%% Load szr onset and offset times
%'/home/dgroppe/GIT/SZR_ANT/
git_root='/Users/davidgroppe/PycharmProjects/SZR_ANT/';
szr_times_csv=fullfile(git_root,'EU_METADATA','szr_on_off_FR_1096.csv');
szr_times=csv2Cell(szr_times_csv,',',1);
n_szrs=size(szr_times,1);

clinical_ids=[];
for a=1:n_szrs,
    if strcmpi(szr_times{a,6},'Clinical'),
        clinical_ids=[clinical_ids a];
    end
end
n_clinical=length(clinical_ids);
fprintf('%d clinical szrs\n',n_clinical);

% Get onset and offset times of clinical seizures
clinical_onset_sec=zeros(n_clinical,1);
clinical_offset_sec=zeros(n_clinical,1);
clinical_szr_num=zeros(n_clinical,1);

for a=1:n_clinical,
    clinical_szr_num(a)=str2num(szr_times{clinical_ids(a),1});
    clinical_offset_sec(a)=str2num(szr_times{clinical_ids(a),2});
    clinical_onset_sec(a)=str2num(szr_times{clinical_ids(a),4});
end


%% Load list of file start and stop times
file_times_csv=fullfile(git_root,'EU_METADATA','data_on_off_FR_1096.csv');
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


%% For each clinical szr import the data plus 3 minutes before and after szr
file_dir='/Volumes/ValianteLabEuData/EU/inv/pat_FR_1096/adm_1096102/rec_109600102';
clinical_fname=cell(1,n_clinical);
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
        clinical_fname{a}=fullfile(file_dir,data_fname);
        % pickup here ?? I think I want import_all_times_7chans.m
    end
end



