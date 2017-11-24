# Fits a classifier on ALL training subjects using a fixed set of hyperparameters
# Parameters are fed in via a json file like this:
# {"model_type": "logreg",
# "model_name": "genLogregSeLog10",
# "n_rand_params": 1,
# "C": 1,
# "gamma": .001,
# "use_ftrs": ["SE"]}
#
# TODO: currently code only works with one feature. Need to add others.

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import scipy.io as sio
import os
import sys
import ieeg_funcs as ief
import dgFuncs as dg
import euGenFuncs as eu
import pickle
from sklearn import svm
from sklearn.externals import joblib
import json


## Start of main function
if len(sys.argv)==1:
    print('Usage: train_smart_srch_multi_patient_kdsamp.py srch_params.json')
    exit()
if len(sys.argv)!=2:
    raise Exception('Error: train_smart_srch_multi_kdsamp.py requires 1 argument: srch_params.json')

# Import Parameters from json file
param_fname=sys.argv[1]
print('Importing model parameters from %s' % param_fname)
with open(param_fname) as param_file:
    params=json.load(param_file)
model_name=params['model_name']
print('Model name is %s' % model_name)
model_type=params['model_type']
print('Model type is %s' % model_type)
ftr_types=params['use_ftrs']
print('Features being used: {}'.format(ftr_types))
if params['equal_sub_wts']=="False":
    equal_sub_wts=False
else:
    equal_sub_wts = True
print('Weight subjects equally={}'.format(equal_sub_wts))
gam=float(params['gamma'])
print('Gamma=%f' % gam)
C=float(params['C'])
print('C=%f' % C)

# if params['ictal_wind']=='small':
#     small_ictal_wind=True
# elif params['ictal_wind']=='max':
#     small_ictal_wind=False
# else:
#     raise Exception('ictal_wind needs to be "small" or "max"')
use_ftrs=['SE'] #TODO import this from json file


# Find if there any existing models of this name
# If so, grab the number of model an increment that number by 1 to get new model name
path_dict=ief.get_path_dict()
model_root=model_path=os.path.join(path_dict['szr_ant_root'],'MODELS')
model_num=1
for f in os.listdir(model_root):
    if os.path.isdir(os.path.join(model_root,f)):
        spltf=f.split('_')
        if spltf[0]==model_name:
           temp_model_num=int(spltf[1])
           if temp_model_num>=model_num:
               model_num=temp_model_num+1
model_path=os.path.join(model_root,model_name+'_'+str(model_num))
print('Model will be stored to %s' % model_path)
if os.path.exists(model_path)==False:
    os.mkdir(model_path)

# Import list of subjects to use
#use_subs_df=pd.read_csv(os.path.join(path_dict['szr_ant_root'],'use_subs.txt'),header=None,na_filter=False)
use_subs_df=pd.read_csv('train_subs.txt',header=None,na_filter=False)
train_subs_list=[]
for sub in use_subs_df.iloc[:,0]:
    train_subs_list.append(sub)
        
print('Training subs: {}'.format(train_subs_list))


# ftr_root='/Users/davidgroppe/PycharmProjects/SZR_ANT/EU_GENERAL/EU_GENERAL_FTRS/SE/'
#ftr_root=path_dict['eu_gen_ftrs']
ftr_root=os.path.join(path_dict['szr_ant_root'],'EU_GENERAL','KDOWNSAMP')
ftr='SE'

n_wind=0
for sub in train_subs_list:
    in_fname='kdownsampled_'+str(sub)+'.npz'
    npz=np.load(os.path.join(ftr_root,in_fname))
    n_wind+=npz['ftrs_dsamp'].shape[0]
n_ftrs=npz['ftrs_dsamp'].shape[1]
print(npz.keys())
print('Total # of observations %d' % n_wind)
print('Total # of features %d' % n_ftrs)

# Import and Concatenate downsampled data
ftrs=np.zeros((n_wind,n_ftrs))
sub_id=np.zeros(n_wind,dtype=int)
szr_class=np.zeros(n_wind)
dsamp_wts=np.zeros(n_wind)
obs_ct=0
for sub in train_subs_list:
    in_fname='kdownsampled_'+str(sub)+'.npz'
    npz=np.load(os.path.join(ftr_root,in_fname))
    n_obs_this_sub=npz['ftrs_dsamp'].shape[0]
    ftrs[obs_ct:obs_ct+n_obs_this_sub,:]=npz['ftrs_dsamp']
    sub_id[obs_ct:obs_ct+n_obs_this_sub]=sub
    szr_class[obs_ct:obs_ct+n_obs_this_sub]=npz['szr_class_dsamp']
    dsamp_wts[obs_ct:obs_ct+n_obs_this_sub]=npz['dsamp_wts']
    obs_ct+=n_obs_this_sub

# ftr_info_dict=eu.data_size_and_fnames(train_subs_list, ftr_root, ftr)
#ftrs_tr, targ_labels_tr=eu.import_data(szr_fnames_tr, non_fnames_tr, n_szr_wind_tr, n_non_wind_tr, ftr_dim)

# n_dim=ftr_info_dict['ftr_dim']
# n_non_wind=ftr_info_dict['grand_n_non_wind']
# n_szr_wind=ftr_info_dict['grand_n_szr_wind']
# n_wind=n_non_wind+n_szr_wind
# print('Total # of dimensions: %d ' % n_dim)
# print('Total # of szr time windows: %d ' % n_szr_wind)
# print('Total # of non-szr time windows: %d ' % n_non_wind)
# print('Total # of time windows: %d ' % n_wind)
# # print('Total # of files: %d' % f_ct)

# Load training/validation data into a single matrix
# ftrs, szr_class, sub_id=eu.import_data(ftr_info_dict['grand_szr_fnames'], ftr_info_dict['grand_non_fnames'],
#                                        ftr_info_dict['szr_file_subs'],ftr_info_dict['non_file_subs'],
#                                        n_szr_wind, n_non_wind, n_dim)

# Set sample weights to weight each subject (and preictal/ictal equally:
uni_subs=np.unique(sub_id)
n_train_subs = len(uni_subs)
# samp_wts = np.ones(n_wind)
# for sub_loop in uni_subs:
#     subset_id = (sub_id == sub_loop)
#     n_obs = np.sum(subset_id)
#     print('Sub #%d has %d observations' % (sub_loop, int(n_obs)))
#     samp_wts[subset_id] = samp_wts[subset_id] / n_obs
#samp_wts=np.multiply(samp_wts,dsamp_wts) #weight each obs by the number of members of each cluster
samp_wts=dsamp_wts
print('Sum samp wts=%f' % np.sum(samp_wts))
print('# of subs=%d' % n_train_subs)

if model_type=='svm':
    from sklearn import svm
    model = svm.SVC(class_weight='balanced', C=C, gamma=gam)
elif model_type=='lsvm':
    from sklearn import svm
    print('Using gamma value of %f' % gam)
    model = svm.SVC(class_weight='balanced', kernel='linear', C=C, gamma=gam)
else:
    from sklearn import linear_model
    #model = linear_model.LogisticRegression(class_weight='balanced', C=C, penalty='l1')
    model = linear_model.LogisticRegression(class_weight='balanced', C=C)

if equal_sub_wts==True:
    model.fit(ftrs, szr_class, sample_weight=samp_wts)
else:
    model.fit(ftrs, szr_class)
    #model.fit(ftrs[sub_id == 0, :], szr_class[sub_id == 0]) # min training data to test code

# make predictions from training and validation data
class_hat = model.predict(ftrs)
# Compute performance on training data
train_bacc, train_sens, train_spec= ief.perf_msrs(szr_class, class_hat)

print('Done!')
print('Training data balanced accuracy: %f' % train_bacc)
print('Training data sensitivity: %f' % train_sens)
print('Training data specificity: %f' % train_spec)
print('Using C=%.2E and gam=%.2E' % (C,gam))
print('Model name: {}'.format(model_name))
print('Features used: {}'.format(use_ftrs))
print('Equal subject wts={}'.format(equal_sub_wts))

out_model_fname = os.path.join(model_path, 'classify_models_srch.pkl')
print('Saving model as %s' % out_model_fname)
models=list()
models.append(model)
pickle.dump(models, open(out_model_fname, 'wb'))

# Save current performance metrics
out_metrics_fname=os.path.join(model_path,'classify_metrics_srch.npz')
print('Metrics save to: %s' % out_metrics_fname)
np.savez(out_metrics_fname,
         train_sens=train_sens,
         train_spec=train_spec,
         train_bacc=train_bacc,
         train_subs_list=train_subs_list,
         C=C,
         gam=gam,
         use_ftrs=use_ftrs)


