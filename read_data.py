import pandas as pd
import numpy as np
import pandas_datareader.data as web
import datetime


# set beginning and end dates for data
start = datetime.datetime(1947, 1, 1) # format is year (1947), month (1), day (1)
end = datetime.date.today() # go through today

# pull NIPA data series of interest using pandas_datareader
nipa_var_dict = {
    'CON5201A027NBEA': 'Contributions for government social insurance: Employee and self-employed contributions: Federal social insurance funds: Old-age, survivors, disability, and hospital insurance: Self-employed',
    'PCE': 'Personal Consumption Expenditures',
    'G170091A027NBEA': 'Government consumption expenditures: Education',
    'PCEPI': 'Personal Consumption Expenditures: Chain-type Price Index'
}
nipa_var_list = list(nipa_var_dict.keys())
nipa_data = web.DataReader(nipa_var_list, "fred", start, end)
print(nipa_data.head(n=10))

# pull Financial Accounts data series of interest using pandas_datareader
fa_var_dict = {
    'BOGZ1FL153064476Q': 'Households and nonprofit organizations; directly and indirectly held corporate equities as a percentage of total assets, Level, Quarterly, Not Seasonally Adjusted',
    'BOGZ1FL153064486Q': 'Households and nonprofit organizations; directly and indirectly held corporate equities as a percentage of total financial assets, Level, Quarterly, Not Seasonally Adjusted',
    'BOGZ1FL153099475Q': 'Households and nonprofit organizations; other financial assets (B.101.e), Level, Quarterly, Not Seasonally Adjusted',
    'BOGZ1LM153064175Q': 'Households and nonprofit organizations; indirectly held corporate equities; asset, Market value levels, Quarterly, Not Seasonally Adjusted',
    'BOGZ1LM153064475Q': 'Households and nonprofit organizations; directly and indirectly held corporate equities; asset, Market value levels, Quarterly, Not Seasonally Adjusted',
    'BOGZ1LM223064213Q': 'State and local government employee retirement funds; corporate equities held indirectly through mutual funds; asset, Revaluation, Quarterly, Not Seasonally Adjusted',
    'BOGZ1LM343064125Q': 'Federal government retirement funds; corporate equities held by Thrift Savings Plan; asset, Market value levels, Quarterly, Not Seasonally Adjusted',
    'BOGZ1LM543064153Q': 'Life insurance companies; corporate equities held directly and indirectly through mutual funds; asset, Market value levels, Quarterly, Not Seasonally Adjusted',
    'BOGZ1LM573064175Q': 'Private defined contribution pension funds; corporate equities held directly and indirectly through mutual funds; asset, Market value levels, Quarterly, Not Seasonally Adjusted',
    'BOGZ1LM653064155Q': 'Mutual funds; corporate equities indirectly held by households; asset, Market value levels, Quarterly, Not Seasonally Adjusted',
    'DABSHNO': 'Households and nonprofit organizations; total currency and deposits including money market fund shares; asset, Level, Quarterly, Not Seasonally Adjusted',
    'HNOCEA': 'Households and nonprofit organizations; corporate equities; asset, Market value levels, Quarterly, Not Seasonally Adjusted',
    'HNODSAQ027S': 'Households and nonprofit organizations; debt securities; asset, Level, Quarterly, Not Seasonally Adjusted',
    'HNOLA': 'Households and nonprofit organizations; loans; asset, Level, Quarterly, Not Seasonally Adjusted',
    'TABSHNO': 'Households and nonprofit organizations; total assets, Level, Quarterly, Not Seasonally Adjusted',
    'TFAABSHNO': 'Households and nonprofit organizations; total financial assets, Level, Quarterly, Not Seasonally Adjusted',
    'TLBSHNO': 'Households and nonprofit organizations; total liabilities, Level, Quarterly, Not Seasonally Adjusted',
    'TNWBSHNO': 'Households and nonprofit organizations; net worth, Level, Quarterly, Not Seasonally Adjusted',
    'TTABSHNO': 'Households and nonprofit organizations; nonfinancial assets, Level, Quarterly, Not Seasonally Adjusted'}
fa_var_list = list(fa_var_dict.keys())
fa_data = web.DataReader(fa_var_list, "fred", start, end)
print(fa_data.head(n=10))
