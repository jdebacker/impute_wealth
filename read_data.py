import pandas as pd
import numpy as np
import pandas_datareader.data as web
import datetime
from constants import NIPA_VARS, FA_VARS


# set beginning and end dates for data
# format is year (1947), month (1), day (1)
start = datetime.datetime(1947, 1, 1)
end = datetime.date.today()

# pull NIPA data series of interest using pandas_datareader
nipa_var_list = list(NIPA_VARS.keys())
nipa_data = web.DataReader(nipa_var_list, "fred", start, end)
nipa_mapper = {v: NIPA_VARS[v][1] for v in nipa_var_list}
nipa_data.rename(columns=nipa_mapper, inplace=True)
# resample data so annual
nipa_data = nipa_data.resample('A').mean()
print(nipa_data.head(n=10))

# pull Financial Accounts data series of interest using pandas_datareader
fa_var_list = list(FA_VARS.keys())
fa_data = web.DataReader(fa_var_list, "fred", start, end)
fa_mapper = {v: FA_VARS[v][1] for v in fa_var_list}
fa_data.rename(columns=fa_mapper, inplace=True)
# resample data so annual
fa_data = fa_data.resample('A').mean()
print(fa_data.head(n=10))

# create dataframe with capitalization factors
print('NIPA type = ', nipa_data.index.dtype)
print('FA type = ', fa_data.index.dtype)
cap_data = nipa_data.merge(fa_data, how='outer', on='DATE')
cap_data['r_div'] = cap_data['dividend_income'] / cap_data['corp_equity']
cap_data['r_int'] = cap_data['interest_income'] / cap_data['debt']
cap_data['r_rent'] = cap_data['rent'] / cap_data['total_nonfin_assets']
print(cap_data[['r_div', 'r_int', 'r_rent']].head(n=50))
