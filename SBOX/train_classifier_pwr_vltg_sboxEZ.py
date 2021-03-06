# This script does LOOCV using 8/9 patients (9th is reserved for testing)
# Various parameters of C are tried
# Features are power in 6 frequency bands and 5 voltage domain features in a one second window
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import scipy.io as sio
import os
import ieeg_funcs as ief
import dgFuncs as dg
from sklearn import svm
from sklearn.externals import joblib

# Import list of subjects to use
path_dict=ief.get_path_dict()
use_subs_df=pd.read_csv(os.path.join(path_dict['szr_ant_root'],'use_subs.txt'),header=None,na_filter=False)
test_sub_list=['NA']
train_subs_list=[]
for sub in use_subs_df.iloc[:,0]:
    if not sub in test_sub_list:
        train_subs_list.append(sub)
        
print('Training subs: {}'.format(train_subs_list))


ftr_types=['PWR','PWR_3SEC','VLTG']
n_ftr_types=len(ftr_types)
n_dim=0
n_wind=0
fname_stem_list=[]
for type_ct, ftr_type in enumerate(ftr_types):
    print('Checking dimensions of feature type %s' % ftr_type)
    # Figure out how much data there is to preallocate mem
    ftr_type_dir=os.path.join(path_dict['ftrs_root'],ftr_type)

    if type_ct==0:
        # count time windows and create fname_stem_list
        for sub in train_subs_list:
            ftr_path=os.path.join(ftr_type_dir,sub)
            for f in os.listdir(ftr_path):
                #get file stem
                f_parts = f.split('_')
                f_stem = f_parts[0]+'_'+f_parts[1]+'_'+f_parts[2]
                fname_stem_list.append(f_stem)
                ftr_dict=np.load(os.path.join(ftr_path,f))
                n_wind+=np.sum(ftr_dict['peri_ictal']>=0)
    else:
        temp_n_wind=0
        f_ct=0
        for sub in train_subs_list:
            ftr_path=os.path.join(ftr_type_dir,sub)
            for f in os.listdir(ftr_path):
                #get file stem
                f_parts = f.split('_')
                f_stem = f_parts[0]+'_'+f_parts[1]+'_'+f_parts[2]
                if f_stem != fname_stem_list[f_ct]:
                    print(f)
                    print('{}'.format(f_parts))
                    print('New stem %s' % f_stem)
                    print('Orig stem %s' % fname_stem_list[f_ct])
                    raise ValueError('File stems do not match across features')
                ftr_dict=np.load(os.path.join(ftr_path,f))
                temp_n_wind+=np.sum(ftr_dict['peri_ictal']>=0)
                f_ct+=1
        if temp_n_wind!=n_wind:
            raise ValueError('# of time windows do not match across features')
    n_dim += ftr_dict['ftrs'].shape[0]

print('Total # of dimensions: %d ' % n_dim)
print('Total # of time windows: %d ' % n_wind)
print('Total # of files: %d' % len(fname_stem_list))


# Load all training data into a giant matrix
ftrs=np.zeros((n_wind,n_dim))
szr_class=np.zeros(n_wind)
sub_id=np.zeros(n_wind)
wind_ct=0
sub_ct=0
file_ct=0
sub_stem_dict=dict()
for sub_ct, sub in enumerate(train_subs_list):
    print('Loading data for sub %s' % sub)

    # Get list of seizure stems for this subject
    ftr_type_dir = os.path.join(path_dict['ftrs_root'], ftr_types[0])
    temp_stem_list=[]
    ftr_path = os.path.join(ftr_type_dir, sub)
    for f in os.listdir(ftr_path):
        # get file stem
        f_parts = f.split('_')
        f_stem = f_parts[0] + '_' + f_parts[1] + '_' + f_parts[2]
        temp_stem_list.append(f_stem)
    sub_stem_dict[sub]=temp_stem_list
    print(temp_stem_list)

    for f_stem in temp_stem_list:
        dim_ct = 0
        file_ct+=1
        for ftr_type in ftr_types:
            ftr_path = os.path.join(path_dict['ftrs_root'], ftr_type, sub)
            file_found=False
            for f in os.listdir(ftr_path):
                # get file stem
                f_parts = f.split('_')
                temp_f_stem = f_parts[0] + '_' + f_parts[1] + '_' + f_parts[2]
                if temp_f_stem==f_stem:
                    # load file
                    #print('Loading %s' % f)
                    print('Loading %s' % os.path.join(ftr_path, f))
                    ftr_dict = np.load(os.path.join(ftr_path, f))
                    file_found=True
                    # break out of for loop
                    break
            # Catch if new file was not loaded
            if not file_found:
                print('Trying to find %s for %s' % (f_stem,ftr_type))
                raise ValueError('File stem not found')
            # Add ftr to collection
            temp_use_ids=ftr_dict['peri_ictal'] >= 0
            temp_n_dim = ftr_dict['ftrs'].shape[0]
            temp_n_wind=np.sum(temp_use_ids)
            #temp_n_dim, temp_n_wind=ftr_dict['ftrs'].shape
            ftrs[wind_ct:wind_ct + temp_n_wind, dim_ct:dim_ct + temp_n_dim] = ftr_dict['ftrs'][:,temp_use_ids].T
            #ftrs[wind_ct:wind_ct+temp_n_wind,dim_ct:dim_ct+temp_n_dim]=ftr_dict['ftrs'].T
            dim_ct+=temp_n_dim
        szr_class[wind_ct:wind_ct+temp_n_wind]=ftr_dict['peri_ictal'][temp_use_ids]
        sub_id[wind_ct:wind_ct+temp_n_wind]=np.ones(temp_n_wind)*sub_ct
        wind_ct+=temp_n_wind

# print('File ct=%d' % file_ct)
# print('wind_ct=%d' % wind_ct)
# np.savez('temp.npz',ftrs=ftrs,szr_class=szr_class,sub_id=sub_id)

# TODO grid search gamma values?
#gamma defines how much influence a single training example has. The larger gamma is, the closer other examples must be to be affected.
# Proper choice of C and gamma is critical to the SVM’s performance. One is advised to
# use sklearn.model_selection.GridSearchCV with C and gamma spaced exponentially far apart
# to choose good values.
# C = 1.0  # SVM regularization parameter, the smaller it is, the stronger the regularization
# C = 0.1

#try_C=np.arange(0.01,1.02,.2) # search 1
#try_C=np.arange(0.01,0.17,.03) # search 2
try_C=np.linspace(0.04,0.1,6) # search 3
n_C=len(try_C)

# LOOCV on training data
n_train_subs = len(train_subs_list)
# n_train_subs=2 # TODO remove this!!! ??

valid_sens = np.zeros((n_train_subs,n_C))
valid_spec = np.zeros((n_train_subs,n_C))
valid_acc = np.zeros((n_train_subs,n_C))
valid_bal_acc = np.zeros((n_train_subs,n_C))
train_sens = np.zeros((n_train_subs,n_C))
train_spec = np.zeros((n_train_subs,n_C))
train_acc = np.zeros((n_train_subs,n_C))
train_bal_acc = np.zeros((n_train_subs,n_C))
pcnt_missed_szrs = np.zeros((n_train_subs,n_C))
mn_stim_latency = np.zeros((n_train_subs,n_C))

for C_ct, C in enumerate(try_C):
    print('Using C value of %f' % C)

    for left_out_id in range(n_train_subs):
        print('Left out sub %d of %d' % (left_out_id+1,n_train_subs))
        #rbf_svc = svm.SVC(kernel='rbf', gamma=0.7, C=C).fit(ftrs.T, szr_class)
        if 'rbf_svc' in locals():
            del rbf_svc # clear model just in case
        rbf_svc = svm.SVC(class_weight='balanced',C=C)
        # rbf_svc.fit? # could add sample weight to weight each subject equally
        rbf_svc.fit(ftrs[sub_id!=left_out_id,:], szr_class[sub_id!=left_out_id]) # Correct training data
        #rbf_svc.fit(ftrs[sub_id == 0, :], szr_class[sub_id == 0]) # min training data to test code ?? TODO remove this
        #clf = svm.SVC()
        # >>> clf.fit(X, y)

        # make predictions from training and validation data
        training_class_hat = rbf_svc.predict(ftrs)
        jive=training_class_hat==szr_class

        train_bool=sub_id!=left_out_id
        valid_bool=sub_id==left_out_id
        ictal_bool=szr_class==1
        preictal_bool=szr_class==0

        # Training Data Results
        train_acc[left_out_id,C_ct]=np.mean(jive[train_bool])
        print('Training accuracy: %f' % train_acc[left_out_id,C_ct])
        use_ids=np.multiply(train_bool,ictal_bool)
        train_sens[left_out_id,C_ct]=np.mean(jive[use_ids])
        print('Training sensitivity: %f' % train_sens[left_out_id,C_ct])
        use_ids=np.multiply(train_bool,preictal_bool)
        train_spec[left_out_id,C_ct]=np.mean(jive[use_ids])
        print('Training specificity: %f' % train_spec[left_out_id,C_ct])
        train_bal_acc[left_out_id,C_ct]=(train_spec[left_out_id,C_ct]+train_sens[left_out_id,C_ct])/2
        print('Training balanced accuracy: %f' % train_bal_acc[left_out_id,C_ct])

        # Validation Data Results
        valid_acc[left_out_id,C_ct]=np.mean(jive[valid_bool])
        print('Validation accuracy: %f' % valid_acc[left_out_id,C_ct])
        use_ids=np.multiply(valid_bool,ictal_bool)
        valid_sens[left_out_id,C_ct]=np.mean(jive[use_ids])
        print('Validation sensitivity: %f' % valid_sens[left_out_id,C_ct])
        use_ids=np.multiply(valid_bool,preictal_bool)
        valid_spec[left_out_id,C_ct]=np.mean(jive[use_ids])
        print('Validation specificity: %f' % valid_spec[left_out_id,C_ct])
        valid_bal_acc[left_out_id,C_ct] = (valid_spec[left_out_id,C_ct] + valid_sens[left_out_id,C_ct]) / 2
        print('Validation balanced accuracy: %f' % valid_bal_acc[left_out_id,C_ct])

        # Load validation data and calculate false positive rate, and peri-onset latency
        valid_sub = train_subs_list[left_out_id]
        onset_dif_sec_list=list()
        n_valid_szrs=0
        n_missed_szrs=0
        mn_onset_dif=0
        for stem_loop in sub_stem_dict[valid_sub]:
            # Collect features for each seizure
            n_valid_szrs+=1
            dim_ct=0
            for ftr_type in ftr_types:
                ftr_path = os.path.join(path_dict['ftrs_root'], ftr_type, valid_sub)
                file_found=False
                for f_valid in os.listdir(ftr_path):
                    # get file stem
                    f_parts = f_valid.split('_')
                    temp_f_stem = f_parts[0] + '_' + f_parts[1] + '_' + f_parts[2]
                    if temp_f_stem==stem_loop:
                        # load file
                        #print('Loading %s' % f)
                        print('Loading %s' % os.path.join(ftr_path, f_valid))
                        ftr_dict = np.load(os.path.join(ftr_path, f_valid))
                        file_found=True
                        # break out of for loop
                        break
                # Catch if new file was not loaded
                if not file_found:
                    print('Trying to find %s for %s' % (stem_loop,ftr_type))
                    print('Looking in dir %s' % ftr_path)
                    raise ValueError('File stem not found')
                    exit()
                # Add ftr to collection
                temp_n_dim = ftr_dict['ftrs'].shape[0]
                # Note that we use all time points (even ictal points long after ictal onset
                if ftr_type==ftr_types[0]:
                    # First feature being analyzed pre-allocate mem
                    temp_n_wind=ftr_dict['ftrs'].shape[1]
                    temp_valid_ftrs=np.zeros((temp_n_wind,n_dim))
                temp_valid_ftrs[:, dim_ct:dim_ct + temp_n_dim] = ftr_dict['ftrs'].T
                dim_ct += temp_n_dim

            # Classify each time point
            temp_class_hat=rbf_svc.predict(temp_valid_ftrs)

            # Compute latency of earliest ictal prediction relative to clinician onset
            sgram_srate=1/10
            onset_dif_sec=ief.cmpt_postonset_stim_latency(temp_class_hat,ftr_dict['peri_ictal'],sgram_srate)
            if onset_dif_sec is None:
                # no positives during peri-onset time window
                n_missed_szrs+=1
            else:
                mn_onset_dif+=onset_dif_sec

        pcnt_missed_szrs[left_out_id,C_ct] = n_missed_szrs/n_valid_szrs
        if n_missed_szrs==n_valid_szrs:
            mn_stim_latency[left_out_id,C_ct] = np.nan
        else:
            mn_stim_latency[left_out_id, C_ct] = mn_onset_dif/(n_valid_szrs-n_missed_szrs)

        # Save current performance metrics
        np.savez('classification_metrics_pwr_vltg.npz',
             valid_sens=valid_sens,
             valid_spec=valid_spec,
             valid_bal_acc=valid_bal_acc,
             train_sens=train_sens,
             train_spec=train_spec,
             train_bal_acc=train_bal_acc,
             train_subs_list=train_subs_list,
             mn_stim_latency=mn_stim_latency,
             pcnt_missed_szrs=pcnt_missed_szrs,
             try_C=try_C,
             C_ct=C_ct,
             left_out_id=left_out_id)


    # Report mean CI performance
    print('# of patients=%d' % len(train_subs_list))
    print('Training Data')
    mn, ci_low, ci_hi=dg.mean_and_cis(train_sens[:,C_ct])
    print('Mean (0.95 CI) Sensitivity %.3f (%.3f-%.3f)' % (mn,ci_low,ci_hi))
    mn, ci_low, ci_hi=dg.mean_and_cis(train_spec[:,C_ct])
    print('Mean (0.95 CI) Specificity %.3f (%.3f-%.3f)' % (mn,ci_low,ci_hi))

    # print('Mean (0.95 CI) Sensitivty %.3f (%.3f)' % (np.mean(perf['train_sens']),)
    print('Validation Data')
    mn, ci_low, ci_hi=dg.mean_and_cis(valid_sens[:,C_ct])
    print('Mean (0.95 CI) Sensitivity %.3f (%.3f-%.3f)' % (mn,ci_low,ci_hi))
    mn, ci_low, ci_hi=dg.mean_and_cis(valid_spec[:,C_ct])
    print('Mean (0.95 CI) Specificity %.3f (%.3f-%.3f)' % (mn,ci_low,ci_hi))
