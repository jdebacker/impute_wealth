import pandas as pd
import read_data as rd

# read in PUF
puf = pd.read_csv('puf.csv')
puf_year = 2011

# compute factors
cap_factors = rd.compute_cap_factors()

# apply factors to PUF
puf['corp_equity_assets'] = (
    (puf['e00600'] + puf['e00650']) /
    cap_factors.loc['2011-12-31', 'r_div'])
puf['fixed_income_assets'] = (
    (puf['e00300'] + puf['e00400']) /
    cap_factors.loc['2011-12-31', 'r_int'])
puf['rental_assets'] = (
    (puf['e02000'] - puf['e26270']) /
    cap_factors.loc['2011-12-31', 'r_rent'])

puf['wealth'] = (puf['corp_equity_assets'] + puf['fixed_income_assets']
                 + puf['rental_assets'])

print(puf[['wealth', 'corp_equity_assets', 'fixed_income_assets',
           'rental_assets']].describe())
