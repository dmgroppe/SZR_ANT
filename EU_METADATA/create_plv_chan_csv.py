import pandas as pd
import os
import ieeg_funcs as ief
import pickle
import numpy as np
import sys


## Start of main function
if len(sys.argv)==1:
    print('Usage: create_plv_chan_csv.py sub_id (e.g., 1077)')
    exit()
if len(sys.argv)!=2:
    raise Exception('Error: create_plv_chan_csv.py requires 1 argument: sub_id')

# Import Parameters from json file
sub_id=sys.argv[1]

# Load list of channels of interest (I limit this to 8 or the # of SOZ chans)
# sub_id=1096
in_fname='/Users/davidgroppe/PycharmProjects/SZR_ANT/EU_METADATA/ANALYZE_CHANS/'+sub_id+'_bi_use_chans.txt'

coi_df=pd.read_csv(in_fname,header=None) #COI=Channels of Interest
coi_df.head()
n_coi=coi_df.shape[0]

out_fname='/Users/davidgroppe/PycharmProjects/SZR_ANT/EU_METADATA/PLV_CHANS/'+sub_id+'_plv.csv'
print('Creating file %s' % out_fname)
fid = open(out_fname,'w')

fid.write('Seed,')
for a in range(1,n_coi-1):
    fid.write(' Pair%d,' %a)
fid.write(' Pair%d\n' % (n_coi-1))


print('# of channels of interest: %d' % n_coi)
# If 8, just make table that indicate that all other channels should be used as PLV channels
if n_coi==8:
    for a in range(n_coi):
        fid.write('%s,' % coi_df.iloc[a,0])
        ct=0
        for b in range(n_coi):
            if a!=b:
                ct+=1
                fid.write(' %s' % coi_df.iloc[b,0])
                if ct<7:
                    fid.write(',')
        fid.write('\n')
    fid.close()
else:
    pass
    # TODO: If more than 8, find the closest 8 other channels and use those as plv channels

print('Done.')



