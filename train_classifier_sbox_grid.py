# # Draft of classification module
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import scipy.io as sio
import os
import ieeg_funcs as ief
import dgFuncs as dg
from sklearn import svm
from sklearn.externals import joblib
# import pickle

# Import list of subjects to use
path_dict=ief.get_path_dict()
use_subs_df=pd.read_csv(os.path.join(path_dict['szr_ant_root'],'use_subs.txt'),header=None,na_filter=False)
test_sub_list=['NA']
train_subs_list=[]
for sub in use_subs_df.iloc[:,0]:
    if not sub in test_sub_list:
        train_subs_list.append(sub)
        
print('Training subs: {}'.format(train_subs_list))

# Figure out how much data there is to preallocate mem
n_ftrs=0
n_wind=0
for sub in train_subs_list:
    ftr_path=os.path.join(path_dict['ftrs_root'],'PWR',sub)
    for f in os.listdir(ftr_path):
        ftr_dict=np.load(os.path.join(ftr_path,f))
        if n_ftrs==0:
            n_ftrs=ftr_dict['db_pwr'].shape[0]
        n_wind+=np.sum(ftr_dict['peri_ictal']>=0)
print('n_ftrs=%d' % n_ftrs)
print('n_wind=%d' % n_wind)


# Load all training data into a giant matrix
ftrs=np.zeros((n_wind,n_ftrs))
szr_class=np.zeros(n_wind)
sub_id=np.zeros(n_wind)
wind_ct=0
sub_ct=0
for sub in train_subs_list:
    ftr_path=os.path.join(path_dict['ftrs_root'],'PWR',sub)
    for f in os.listdir(ftr_path):
        ftr_dict=np.load(os.path.join(ftr_path,f))
        neo_wind=np.sum(ftr_dict['peri_ictal']>=0)
        ftrs[wind_ct:wind_ct+neo_wind,:]=ftr_dict['db_pwr'][:,:neo_wind].T
        szr_class[wind_ct:wind_ct+neo_wind]=ftr_dict['peri_ictal'][:neo_wind]
        sub_id[wind_ct:wind_ct+neo_wind]=np.ones(neo_wind)*sub_ct
        wind_ct+=neo_wind
    sub_ct+=1


# TODO grid search C and gamma values
#gamma defines how much influence a single training example has. The larger gamma is, the closer other examples must be to be affected.
# Proper choice of C and gamma is critical to the SVM’s performance. One is advised to 
# use sklearn.model_selection.GridSearchCV with C and gamma spaced exponentially far apart 
# to choose good values.
# C = 1.0  # SVM regularization parameter, the smaller it is, the stronger the regularization
# C = 0.1

try_C=np.arange(0.01,1.02,.2)

# LOOCV on training data
n_train_subs = len(train_subs_list)
n_C=len(try_C)

# n_train_subs=3 # TODO remove this!!! ??
valid_sens = np.zeros((n_train_subs,n_C))
valid_spec = np.zeros((n_train_subs,n_C))
valid_acc = np.zeros((n_train_subs,n_C))
valid_bal_acc = np.zeros((n_train_subs,n_C))
train_sens = np.zeros((n_train_subs,n_C))
train_spec = np.zeros((n_train_subs,n_C))
train_acc = np.zeros((n_train_subs,n_C))
train_bal_acc = np.zeros((n_train_subs,n_C))

for C_ct, C in enumerate(try_C):
    print('Using C value of %f' % C)

    for left_out_id in range(n_train_subs):
        print('Left out sub %d of %d' % (left_out_id+1,n_train_subs))
        #rbf_svc = svm.SVC(kernel='rbf', gamma=0.7, C=C).fit(ftrs.T, szr_class)
        if 'rbf_svc' in locals():
            del rbf_svc # clear model just in case
        rbf_svc = svm.SVC(class_weight='balanced',C=C)
        # rbf_svc.fit? # could add sample weight to weight each subject equally
        rbf_svc.fit(ftrs[sub_id!=left_out_id,:], szr_class[sub_id!=left_out_id])
        #rbf_svc.fit(ftrs[sub_id == 0, :], szr_class[sub_id == 0]) # min training data to test code
        #clf = svm.SVC()
        # >>> clf.fit(X, y)

        # make predictions from training and validation data
        training_class_hat=rbf_svc.predict(ftrs)
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

        # TODO Load validation data and calculate false positive rate, and peri-onset latency

        # Save current performance metrics
        np.savez('classification_metrics.npz',
             valid_sens=valid_sens,
             valid_spec=valid_spec,
             valid_bal_acc=valid_bal_acc,
             train_sens=train_sens,
             train_spec=train_spec,
             train_bal_acc=train_bal_acc,
             train_subs_list=train_subs_list,
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
