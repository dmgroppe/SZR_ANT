import numpy as np
import pandas as pd
import os
import ieeg_funcs as ief
import matplotlib.pyplot as plt
import sys


if len(sys.argv)<2:
    raise ValueError('You need to pass sub codename as first argument')

sub=sys.argv[1]

print('Processing onset times for %s' % sub)
csv_path='/Users/davidgroppe/ONGOING/SZR_SPREAD/PATIENTS/'+sub+'/ONSETTIMES/'
print('Importing manual onset times from %s' % csv_path)
csv_list=list()
for f in os.listdir(csv_path):
    if f.endswith('manualOnsets.txt'):
        csv_list.append(f)

n_files=len(csv_list)
print('%d manual wide-band onset files found' % n_files)

# Grab onset times and channel labels from csv files
chan_labels=list()
for csv_loop in range(n_files):
    temp_df=pd.read_csv(os.path.join(csv_path,csv_list[csv_loop]))
    sec_df=temp_df.iloc[:,2]
    if csv_loop==0:
        n_chan=temp_df.shape[0]
        bband_onset_times=np.zeros((n_chan,n_files))
    for chan_loop in range(n_chan):
        bband_onset_times[chan_loop,csv_loop]=sec_df[chan_loop]
        if csv_loop==0:
            chan_labels.append(temp_df.iloc[chan_loop,0])
    # normalize onset so that 0 is earliest channel
    bband_onset_times[:,csv_loop]=bband_onset_times[:,csv_loop]-np.nanmin(bband_onset_times[:,csv_loop])
chan_labels=ief.clean_labels(chan_labels)

# print head of last imported csv file
print(temp_df.head())

figure_path='/Users/davidgroppe/PycharmProjects/SZR_ANT/PICS/MAN_ONSETS'

plt.figure(1)
plt.clf()
_=plt.plot(bband_onset_times,'o-')
plt.ylabel('Seconds (0=onset)')
_=plt.xticks(np.arange(0,n_chan),chan_labels,rotation='vertical',fontsize=8)
_=plt.title(sub+' manual broadband onsets (n='+str(n_files)+')')
plt.savefig(os.path.join(figure_path,sub+'_onsets_scatter.pdf'))

plt.figure(2)
plt.clf()
_=plt.errorbar(np.arange(n_chan),np.nanmean(bband_onset_times,axis=1),
               yerr=np.nanstd(bband_onset_times,axis=1)/np.sqrt(n_files))
plt.ylabel('Seconds (0=onset)')
_=plt.xticks(np.arange(0,n_chan),chan_labels,rotation='vertical',fontsize=8)
_=plt.title(sub+' manual broadband onsets [mn/stderr] (n='+str(n_files)+')')
plt.savefig(os.path.join(figure_path,sub+'_onsets_err_bar.pdf'))

# Channel with earlist avg onset
mn_onset=np.nanmean(bband_onset_times,axis=1)
se_onset=np.nanstd(bband_onset_times,axis=1)/np.sqrt(n_files)
min_id=np.nanargmin(mn_onset)
print('Channel with earliest mean onset: {} (MN={:.2f}, SE={:.2f} sec)'.format(
    chan_labels[min_id],mn_onset[min_id],se_onset[min_id]))




