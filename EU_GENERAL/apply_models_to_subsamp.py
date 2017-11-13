# Function for applying a saved ensemble of models to subsampled data from a list of subjects (sub_list.txt)
# These are the data that could be used for training
# It outputs binary classification performance metrics

import numpy as np
# import matplotlib.pyplot as plt
import pandas as pd
# import scipy.io as sio
import os
import sys
import ieeg_funcs as ief
import dgFuncs as dg
import euGenFuncs as eu
import pickle
from sklearn.metrics import roc_auc_score
from sklearn import svm
from sklearn.externals import joblib
import json


## Start of main function
if len(sys.argv)==1:
    print('Usage: apply_models_to_subsamp.py model_name sub_list.txt')
    exit()
if len(sys.argv)!=3:
    raise Exception('Error: apply_models_to_subsamp.py requires 2 arguments: model_name sub_list.txt')

# Import Parameters from command line
model_name=sys.argv[1]
print('Model name is %s' % model_name)

text_file=open(sys.argv[2],'r')
temp=text_file.readlines()
subs=list()
for raw_sub in temp:
    subs.append(int(raw_sub.strip()))
print('Subs are {}'.format(subs))
path_dict=ief.get_path_dict()


# Load model
model_root=model_path=os.path.join(path_dict['szr_ant_root'],'MODELS')
model_fname=os.path.join(model_root,model_name,'classify_models_srch.pkl')
print('Loading %s' % model_fname)
models=pickle.load(open(model_fname,'rb'))
n_models=len(models)
print('# of models in ensemble= %d' % n_models)

# Import Data
# use_ftrs=['SE'] #TODO import this from model
ftr_root=path_dict['eu_gen_ftrs']
ftr='SE'
ftr_info_dict=eu.data_size_and_fnames(subs, ftr_root, ftr)

n_dim=ftr_info_dict['ftr_dim']
n_non_wind=ftr_info_dict['grand_n_non_wind']
n_szr_wind=ftr_info_dict['grand_n_szr_wind']
n_wind=n_non_wind+n_szr_wind
print('Total # of dimensions: %d ' % n_dim)
print('Total # of szr time windows: %d ' % n_szr_wind)
print('Total # of non-szr time windows: %d ' % n_non_wind)
print('Total # of time windows: %d ' % n_wind)
# print('Total # of files: %d' % f_ct)

# Load training/validation data into a single matrix
ftrs, szr_class, sub_id=eu.import_data(ftr_info_dict['grand_szr_fnames'], ftr_info_dict['grand_non_fnames'],
                                       ftr_info_dict['szr_file_subs'],ftr_info_dict['non_file_subs'],
                                       n_szr_wind, n_non_wind, n_dim)


# Set sample weights to weight each subject (and preictal/ictal equally:
wt_subs_equally=False
if wt_subs_equally==True:
    uni_subs=np.unique(sub_id)
    n_train_subs = len(uni_subs)
    samp_wts = np.ones(n_wind)
    for sub_loop in uni_subs:
        subset_id = (sub_id == sub_loop)
        n_obs = np.sum(subset_id)
        print('Sub #%d has %d observations' % (sub_loop, int(n_obs)))
        samp_wts[subset_id] = samp_wts[subset_id] / n_obs
    print('Sum samp wts=%f' % np.sum(samp_wts))
    print('# of subs=%d' % n_train_subs)


# Apply ensemble of models on validation data
for model_ct in range(n_models):
    tmp_yhat = models[model_ct].predict_proba(ftrs)[:, 1]
    if model_ct == 0:
        class_hat = np.zeros(tmp_yhat.shape)
    class_hat += tmp_yhat / n_models


# Compute performance metrics
print('Ensemble Performance')
auc = roc_auc_score(szr_class, class_hat)
print('AUC=%.3f' % auc)
bal_acc, sens, spec = ief.perf_msrs(szr_class, class_hat >= 0.5)
print('Balanced Accuracy (sens/spec)=%.3f (%f/%f)' % (bal_acc, sens, spec))



