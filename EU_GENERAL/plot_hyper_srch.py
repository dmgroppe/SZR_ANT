""" This function plots the balanced accuracy on training and validation data as a function of C & gamma
hyperparameters for all models with the same stem name"""

import numpy as np
import matplotlib.pyplot as plt
from matplotlib import cm
import os
import ieeg_funcs as ief
import sys

## Start of main function
if len(sys.argv)==1:
    print('Usage: plt_hyper_srch.py model_stem')
    exit()
if len(sys.argv)!=2:
    raise Exception('Error: plt_hyper_srch.py requires 1 argument: model_stem')

# Import Parameters from json file
model_stem=sys.argv[1]

path_dict=ief.get_path_dict()
print(path_dict.keys())

#model_stem='genSvmSe'
#model_stem='genSvmEqWtsAes'
####model_stem='svmKdsampSeAes'
#model_stem='tempEqWt'
#model_stem='genLogregSe'
#model_dir='/home/dgroppe/GIT/SZR_ANT/MODELS/'
model_dir=os.path.join(path_dict['szr_ant_root'],'MODELS')
#model_dir='/Users/davidgroppe/PycharmProjects/SZR_ANT/MODELS/'
C_srch=list()
valid_bal_acc_srch=list()
train_bal_acc_srch=list()
model_names_srch=list()
gamma_srch=list()
for f in os.listdir(model_dir):
    f_splt=f.split('_')
    if f_splt[0]==model_stem:
        # model of desired type
        in_fname=os.path.join(model_dir,f,'classify_metrics_srch.npz')
        if os.path.isfile(in_fname):
            temp=np.load(in_fname)
            C_srch=C_srch+list(temp['tried_C'])
    #         C_srch=C_srch+list(temp['C_srch'])
    #         temp_gamma=[temp['gamma'] for a in range(len(temp['C_srch']))]
            gamma_srch=gamma_srch+list(temp['tried_gamma'])
            valid_bal_acc_srch=valid_bal_acc_srch+list(temp['tried_valid_acc'])
            train_bal_acc_srch=train_bal_acc_srch+list(temp['tried_train_acc'])
            model_names_srch=model_names_srch+[f for a in range(len(temp['tried_C']))]

mx_id=np.argmax(valid_bal_acc_srch)
print('%d hyperparameters tried' % len(valid_bal_acc_srch))
print('Best Validation Accuracy: %f' % valid_bal_acc_srch[mx_id])
print('Using C=%f, gam=%f' % (C_srch[mx_id],gamma_srch[mx_id]))
print('Best model name is %s' % model_names_srch[mx_id])

plt.figure(1)
plt.clf()
#plt.scatter(np.arange(len(vbacc_ray)),vbacc_ray,c=vbacc_ray)
plt.scatter(np.log10(C_srch),np.log10(gamma_srch),c=valid_bal_acc_srch,cmap='plasma',s=32)
plt.plot(np.log10(C_srch[mx_id]),np.log10(gamma_srch[mx_id]),'k.')
plt.xlabel('log10(C)')
plt.ylabel('log10(Gamma)')
cbar=plt.colorbar()
cbar.set_label('Balanced Accuracy', rotation=90)
plt.title('Validation Data')
plt.show()

plt.figure(2)
plt.clf()
#plt.scatter(np.arange(len(vbacc_ray)),vbacc_ray,c=vbacc_ray)
plt.scatter(np.log10(C_srch),np.log10(gamma_srch),c=train_bal_acc_srch,cmap='plasma',s=32)
plt.plot(np.log10(C_srch[mx_id]),np.log10(gamma_srch[mx_id]),'k.')
plt.xlabel('log10(C)')
plt.ylabel('log10(Gamma)')
cbar=plt.colorbar()
cbar.set_label('Balanced Accuracy', rotation=90)
plt.title('Training Data')
plt.show()