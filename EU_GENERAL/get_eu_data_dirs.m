function subdirs=get_eu_data_dirs(root_dir)

f=dir(fullfile(root_dir,'rec_*'));
subdirs=cell(1,1);
subdir_ct=0;
for a=1:length(f),
    if isdir(fullfile(root_dir,f(a).name)),
        subdir_ct=subdir_ct+1;
        subdirs{subdir_ct}=fullfile(root_dir,f(a).name);
    end
end
fprintf('%d subdirectories of data found\n',subdir_ct);



