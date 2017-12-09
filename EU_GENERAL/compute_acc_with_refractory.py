# Libraries
import numpy as np
import scipy.io as sio
import os
import pandas as pd
import pickle
import sys
import ieeg_funcs as ief
import dgFuncs as dg
import matplotlib.pyplot as plt

def replace_periods(word):
    for letter in word:
        if letter == ".":
            word = word.replace(letter,"-")
    return word

## Start of main function
if len(sys.argv)==1:
    print('Usage: compute_acc_with_refractory.py sub_id stim_thresh model_name')
    exit()
if len(sys.argv)!=4:
    raise Exception('Error: compute_acc_with_refractory.py requires 3 arguments: sub_id stim_thresh model_name')

# Import Parameters from command line
sub = int(sys.argv[1])
stim_thresh=float(sys.argv[2]) # threshold for triggering stimulation
model_name=sys.argv[3]

Fs = 9.84615384615  # sampling rate of moving spectral energy window
time_step=1/Fs
# Set stim refractory period
#refract_min=0.5 # length of refractory period in minutes
refract_sec=30 # length of refractory period in seconds
refract_tpt=np.round(Fs*refract_sec) #length of refractory period in time points


# Get list of yhat files
# TODO get these paths from get_path_dict()
path_dict=ief.get_path_dict()
if sys.platform=='linux':
    yhat_path = os.path.join('/home/dgroppe/EU_YHAT/',str(sub)+'_'+model_name)
    label_path =os.path.join('/home/dgroppe/EU_Y/',str(sub)+'_all_labels') #TODO figure this out
else:
    yhat_path = os.path.join('/Users/davidgroppe/ONGOING/EU_YHAT/',str(sub)+'_'+model_name)
    label_path =os.path.join('/Volumes/SgateOSExJnld/EU_TEMP/',str(sub)+'_all_labels')

# Accuracy metrics
total_hrs = 0
n_false_pos = 0
n_clin_szr = 0
n_true_pos = 0
stim_latency_sec = list()
stim_latency_hit = list()

# Get list of clips from data_on_off_FR*.csv
csv_path=os.path.join(path_dict['eu_meta'],'IEEG_ON_OFF')
csv_fname='data_on_off_FR_'+str(sub)+'.csv'
on_off_df=pd.read_csv(os.path.join(csv_path,csv_fname))

edge_pts=1178 # number of initial time points skipped due to EDM edge effects

# Loop over header files
#temp_files=['109600102_0000_yhat.npz','109600102_0001_yhat.npz','109600102_0002_yhat.npz','109600102_0072_yhat.npz']
#for f in temp_files:
clin_szr_ct=0
# first_hdr_file=True
stim_sec=list()
last_stim = on_off_df['StartSec'][0]-refract_sec-1 # initialize so that stimulation can begin at start of first clip
for hdr_ct, hdr_fname in enumerate(on_off_df['HeaderFname']):
    # Note that the files should already be sorted in chronological order in on_off_df
    root_fname=hdr_fname.split('.')[0]

    # Load classifier output for this clip
    yhat_fname=root_fname+'_yhat.npz'
    #print('Analyzing file %s' % yhat_fname)
    yhat_npz = np.load(os.path.join(yhat_path, yhat_fname))
    n_wind = len(yhat_npz['max_yhat'])

    # Compute # of seconds in file
    file_dur_hr = n_wind / (Fs * 3600)
    total_hrs += file_dur_hr
    #print('total_hrs=%f' % total_hrs)

    # Load clinician labels for this clip
    y_fname = str(sub) + '_y_' + root_fname + '.mat'
    label_f = os.path.join(label_path, y_fname)
    #print('Loading file %s' % y_fname)
    label_mat = sio.loadmat(label_f)

    time_ptr=on_off_df['StartSec'][hdr_ct]+edge_pts/Fs # First feature time point
    # if first_hdr_file==True:
    #     time_ptr=0 #set to start of first file
    #     first_hdr_file==False


    # Compute hypothetical stimulations with refractory periods
    stim = np.zeros(n_wind)
    for wind_ct, yhat in enumerate(yhat_npz['max_yhat']):
        if wind_ct>0:
            time_ptr+=time_step
        if yhat > stim_thresh and ((time_ptr-last_stim) > refract_sec):
            # Hypotheticaly stimulate
            stim[wind_ct] = 1
            stim_sec.append(time_ptr)
            last_stim = time_ptr


    # Compute false positives
    se_szr_class = np.squeeze(label_mat['se_szr_class'])
    # TODO make this also ignore subclinical szrs  !!!!!!
    nonszr_bool = se_szr_class == 0 # TODO extend this 5 sec before clinician onset,
    # should probably make a separate matlab variable
    #print('false+ %d' % np.sum(stim[nonszr_bool]))
    n_false_pos += np.sum(stim[nonszr_bool])

    if False:
        plt.figure(1)
        plt.clf()
        plt.plot(yhat_npz['max_yhat'],'b-')
        #plt.plot(stim[stim>0],'r.')
        plt.plot(stim,'r.')
        plt.plot(se_szr_class,'g-')
        xlim=plt.xlim()
        plt.plot(xlim,[0.5, 0.5],'k:')
        plt.show()

    # Load list of szrs
    np.savez('sbox.npz',stim_sec=stim_sec)
    # Loop over szrs and:
    # 1) find the stimulation that is closest in time to seizure onset
    # 2) see if stimulation happens SOMEwhere in the target window


        # Compute sensitivity and latency to clinical szr onset (if any clinical szrs in the file)
        # if 1 in se_szr_class:
        #     print('Clinical szr present')
        #     onset_id_list = list()
        #     offset_id_list = list()
        #     in_szr = False
        #     for tloop, y in enumerate(se_szr_class):
        #         if in_szr == False:
        #             if y == 1:
        #                 # entered new clinical szr
        #                 onset_id_list.append(tloop)
        #                 n_clin_szr += 1
        #                 in_szr = True
        #         else:
        #             if y == 0:
        #                 # exited clinical szr
        #                 offset_id_list.append(tloop - 1)
        #                 in_szr = False
        #     if in_szr == True:
        #         # szr lasts until end of file
        #         offset_id_list.append(tloop - 1)
        #     if len(onset_id_list) != len(offset_id_list):
        #         raise Exception('Error: len(onset_id_list)!=len(offset_id_list) in %s!!!!')
        #     print('Clinical szr onsets: {}'.format(onset_id_list))
        #     print('Clinical szr offsets: {}'.format(offset_id_list))
        #     # Loop over clinical szrs (may be more than one in the clip)
        #     for temp_ct, onset_id in enumerate(onset_id_list):
        #         if sum(stim[onset_id:offset_id_list[temp_ct]]):
        #             n_true_pos += 1
        #             stim_latency_hit.append(1)
        #         else:
        #             stim_latency_hit.append(0)
        #         # Find closest stimulation to clinician defined onset
        #         temp_id = np.argmin(np.abs(np.asarray(stim_ids) - onset_id))
        #         closest_id = stim_ids[temp_id]
        #         stim_latency_sec.append((closest_id - onset_id) / Fs)
        #         if stim_latency_sec[-1]>=-5 and stim_latency_sec[-1]<=0:
        #             # Stimulation occurred within 5 sec before clinician onset.
        #             # I count this as a hit due to training
        #             if stim_latency_hit[-1]==0:
        #                 stim_latency_hit[-1]=1
        #                 n_true_pos += 1
        #         if stim_latency_sec[-1]>50 and stim_latency_hit[-1]==1:
        #             # Stimulation occurred more than 50 sec after clinician onset.
        #             # I count this as a miss even if it happened during the seizure
        #             stim_latency_hit[-1] = 0
        #             n_true_pos += -1
        #         clin_szr_ct+=1
        #         print('Clinical Szr #%d, file %s' % (clin_szr_ct,label_f))
        #         print('yhat from %s' % os.path.join(yhat_path, f))
        #         print('Hit=%d, Latency=%f sec' % (stim_latency_hit[-1],stim_latency_sec[-1]))

fp_per_hour = n_false_pos / total_hrs
print('%f of false positives/hr' % fp_per_hour)
print('%f of false positives/day' % (fp_per_hour*24))
if n_clin_szr == 0:
    print('No clinical szrs captured')
    sens = np.nan
else:
    sens = n_true_pos / n_clin_szr
    print('%d/%d clinical szrs, Sensitivity=%f' % (n_true_pos, n_clin_szr, sens))
    mn_latency_sec = np.mean(stim_latency_sec)
    sd_latency_sec = np.std(stim_latency_sec)
    print('Mean(SD) latency of stim relative to clinician onset: %.1f (%.1f) seconds' % (mn_latency_sec, sd_latency_sec))


# outpath=os.path.join(path_dict['szr_ant_root'],'MODELS',model_name)
# outfname=str(sub)+'_thresh_'+replace_periods(str(stim_thresh))+'_refract_'+replace_periods(str(refract_sec))+'_stim_results'
# print('Saving results to %s' % os.path.join(outpath,outfname))
# np.savez(os.path.join(outpath,outfname),
#          stim_latency_sec=stim_latency_sec,
#          stim_latency_hit=stim_latency_hit,
#          sens=sens,
#          n_clin_szr=n_clin_szr,
#          n_true_pos=n_true_pos,
#          total_hrs=total_hrs,
#          n_false_pos=n_false_pos,
#          fp_per_hour=fp_per_hour,
#          stim_thresh=stim_thresh,
#          refract_sec=refract_sec)

# plt.figure(1)
# plt.clf()
# plt.boxplot(stim_latency_sec)
# plt.plot(np.ones(len(stim_latency_sec)),stim_latency_sec,'b.')
# plt.ylabel('Seconds')
# plt.xticks([])
# plt.title('Stim Latency relative to Szr Onset')
# xlim=[.85, 1.15]
# plt.xlim(xlim)
# plt.plot(xlim,[0, 0],'k:')
# plt.show()