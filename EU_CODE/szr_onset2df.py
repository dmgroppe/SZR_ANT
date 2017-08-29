# Read seizure onsets from "all szrs" html file and output them to a dataframe which is saved via pickle to disk.
# The dataframe columns are:
# 'SzrType'=clinical/subclinical
# 'SzrOnsetSec'=onset in seconds from Jan. 1, 2000
# 'SzrOffsetSec'=offset in seconds from Jan. 1, 2000
# 'SzrOnsetStr'=onset in string form (copied directly from html file)
# 'SzrOffsetStr'=offset in string form (copied directly from html file)

import pandas as pd
import os
import numpy as np
from datetime import datetime
import pickle
import sys

if len(sys.argv)==1:
    print('Usage: szr_onset2df.py sub# (e.g., szr_onset2df.py 1146')
    exit()
if len(sys.argv)!=2:
    raise Exception('Error: szr_onset2df.p requires 1 argument: the patient # (e.g., 1146)')


sub=sys.argv[1]
#metadata_dir='/Users/davidgroppe/PycharmProjects/SZR_ANT/EU_METADATA'
metadata_dir='/Users/davidgroppe/GIT/OCSVM_EDMSE/matlab/EU/metadata'
html_fname=os.path.join(metadata_dir,'all_szrs_FR_'+sub+'.html')
print('Attempting to read %s' % html_fname)
htable=pd.read_html(html_fname)
print('%d tables read' % len(htable))
print('This code expects 4 tables.')

# Purge "Total:" rows
for tloop in range(len(htable)):
    n_rows = htable[tloop].shape[0]
    #if np.isnan(htable[tloop].iloc[n_rows - 1, 2]):
    if htable[tloop].iloc[n_rows-1,0]=='total:':
        htable[tloop]=htable[tloop].drop(htable[tloop].index[n_rows-1])

# print(htable[0])
# print(htable[2])
# exit()

# FIRST TABLE IS CLINICAL SZRS
# Convert clinical onset/offsets to datetime
n_clinical_szr=htable[0].shape[0]
print('************** %d clinical szrs' % n_clinical_szr)
szr_onset_sec=list()
szr_offset_sec=list()
szr_onset_str=list()
szr_offset_str=list()
szr_type=list()


#milestone=datetime(1970,1,1) # This is 5 hours (I think) after time=0 for python
milestone=datetime(2000,1,1) # Arbirary date via which to convert times into seconds
#milestone=datetime(2009,6,21)

for a in range(n_clinical_szr):
    szr_type.append('Clinical')
    
    print()
    # Convert onset to seconds since milestone
    if not isinstance(htable[0].iloc[a, 2], str):
        szr_onset_sec.append(np.nan)
        szr_onset_str.append('NaN')
    else:
        temp_lst=htable[0].iloc[a,2].split(' ')
        temp_lst[1]=temp_lst[1].replace("'","20")
        print('Onset: '+temp_lst[1]+' '+temp_lst[2])
        hr_splt=temp_lst[2].split(':')
        temp_dt=datetime.strptime(temp_lst[1],'%d.%m.%Y')
        ttl_sec=(temp_dt-milestone).total_seconds()
        ttl_sec+=int(hr_splt[0])*3600+int(hr_splt[1])*60+float(hr_splt[2])
        szr_onset_sec.append(ttl_sec)
        szr_onset_str.append(temp_lst[1]+' '+temp_lst[2])
    
    # Convert offset to seconds since milestone
    if not isinstance(htable[0].iloc[a, 3], str):
        szr_offset_sec.append(np.nan)
        szr_offset_str.append('NaN')
    else:
        temp_lst=htable[0].iloc[a,3].split(' ')
        temp_lst[1]=temp_lst[1].replace("'","20")
        print('Offset: '+temp_lst[1]+' '+temp_lst[2])
        hr_splt=temp_lst[2].split(':')
        temp_dt=datetime.strptime(temp_lst[1],'%d.%m.%Y')
        ttl_sec=(temp_dt-milestone).total_seconds()
        ttl_sec+=int(hr_splt[0])*3600+int(hr_splt[1])*60+float(hr_splt[2])
        szr_offset_sec.append(ttl_sec)
        szr_offset_str.append(temp_lst[1]+' '+temp_lst[2])

    df=szr_offset_sec[a]-szr_onset_sec[a]
    mnts=np.floor(df/60)
    scs=df-mnts*60
    print('Duration: %d minute(s) %f sec' % (mnts,scs))
    

# THIRD TABLE IS SUBCLINICAL SZRS
# Convert SUBclinical onset/offsets to datetime
#n_subclinical_szr=htable[2].shape[0]-1 # subtract 1 because last row is a total
n_subclinical_szr=htable[2].shape[0] # subtract 1 because last row is a total
print('************** %d subclinical szrs' % n_subclinical_szr)

for a in range(n_subclinical_szr):
    szr_type.append('Subclinical')
        
    print()
    # Convert onset to seconds since milestone
    if not isinstance(htable[2].iloc[a, 1], str):
        szr_onset_sec.append(np.nan)
        szr_onset_str.append('NaN')
    else:
        temp_lst=htable[2].iloc[a,1].split(' ')
        temp_lst[0]=temp_lst[0].replace("'","20")
        print('Onset: '+temp_lst[0]+' '+temp_lst[1])
        hr_splt=temp_lst[1].split(':')
        temp_dt=datetime.strptime(temp_lst[0],'%d.%m.%Y')
        ttl_sec=(temp_dt-milestone).total_seconds()
        ttl_sec+=int(hr_splt[0])*3600+int(hr_splt[1])*60+float(hr_splt[2])
        #print(ttl_sec)
        szr_onset_sec.append(ttl_sec)
        szr_onset_str.append(temp_lst[0]+' '+temp_lst[1])
    
    # Convert offset to seconds since milestone
    if not isinstance(htable[2].iloc[a,2],str):
        szr_offset_sec.append(np.nan)
        szr_offset_str.append('NaN')
    else:
        temp_hr=htable[2].iloc[a,2]
        print('temp_hr {}'.format(temp_hr))
        print('Offset: '+temp_lst[0]+' '+temp_hr)
        hr_splt=temp_hr.split(':')
        ttl_sec=(temp_dt-milestone).total_seconds()
        ttl_sec+=int(hr_splt[0])*3600+int(hr_splt[1])*60+float(hr_splt[2])
        szr_offset_sec.append(ttl_sec)
        szr_offset_str.append(temp_lst[0]+' '+temp_hr)

    if szr_onset_str=='NaN' or szr_offset_str=='NaN':
        print('Duration unknown')
    else:
        df=szr_offset_sec[a]-szr_onset_sec[a]
        mnts=np.floor(df/60)
        scs=df-mnts*60
        print('Duration: %d minute(s) %f sec' % (mnts,scs))


# Create DataFrame
szr_on_off_df=pd.DataFrame({'SzrType': szr_type,
                           'SzrOnsetSec': szr_onset_sec,
                           'SzrOffsetSec': szr_offset_sec,
                           'SzrOnsetStr': szr_onset_str,
                           'SzrOffsetStr': szr_offset_str})


# Sort dataframe from first to last szr
szr_on_off_df.sort_values('SzrOnsetSec',inplace=True)

out_path='/Users/davidgroppe/Dropbox/TWH_INFO/EU_METADATA'
# Output to csv
out_fname=os.path.join(out_path,'szr_on_off_FR_'+str(sub)+'.csv')
print('Saving file to:')
print(out_fname)
szr_on_off_df.to_csv(out_fname)

# Output to pkl
out_fname=os.path.join(out_path,'szr_on_off_FR_'+str(sub)+'.pkl')
print('Saving file to:')
print(out_fname)
pickle.dump(szr_on_off_df,open(out_fname,'wb'))



