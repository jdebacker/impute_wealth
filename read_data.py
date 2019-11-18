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
    'PCEPI': 'Personal Consumption Expenditures: Chain-type Price Index',
    'PINCOME': 'Personal Income',
    'A033RC1A027NBEA': 'National income: Compensation of employees',
    'A4102C1A027NBEA': 'Gross domestic income: Compensation of employees, paid: Wages and salaries',
    'A132RC1': 'Compensation of Employees, Received: Wage and Salary Disbursements: Private Industries',
    'B202RC1Q027SBEA': 'Compensation of employees: Wages and salaries: Government',
    'A038RC1Q027SBEA': 'Compensation of employees: Supplements to wages and salaries',
    'L306051A027NBEA': 'Supplements to wages and salaries: Pension, profit-sharing, and other retirement benefit plans: Old-age, survivors, and disability insurance',
    'B039RC1M027SBEA': 'Compensation of employees: Supplements to wages and salaries: Employer contributions for government social insurance',
    'A1645C1A027NBEA': "National income: Domestic business: Noncorporate business: Sole proprietorships and partnerships: Proprietors' income with IVA and CCAdj",
    'BOGZ1FA136111103Q': "Farm business; proprietors' income with IVA and CCAdj, Flow",
    'A1646C1A027NBEA': "National income: Domestic business: Noncorporate business: Sole proprietorships and partnerships: Proprietors' income with IVA and CCAdj: Nonfarm",
    'RENTIN': 'Rental Income of Persons with Capital Consumption Adjustment',
    'PIROA': 'Personal Income Receipts on Assets',
    'PII': 'Personal Income Receipts on Assets: Personal Interest Income',
    'B703RC1Q027SBEA': 'Personal income receipts on assets: Personal dividend income',
    'PCTR': 'Personal Current Transfer Receipts',
    'A063RC1Q027SBEA': 'Personal current transfer receipts: Government social benefits to persons',
    'W823RC1Q027SBEA': 'Personal current transfer receipts: Government social benefits to persons: Social security',
    'W824RC1A027NBEA': 'Personal current transfer receipts: Government social benefits to persons: Medicare',
    'W729RC1Q027SBEA': 'Personal current transfer receipts: Government social benefits to persons: Medicaid',
    'W825RC1Q027SBEA': 'Personal current transfer receipts: Government social benefits to persons: Unemployment insurance',
    'W826RC1Q027SBEA': "Personal current transfer receipts: Government social benefits to persons: Veterans' benefits",
    'W827RC1Q027SBEA': "Personal current transfer receipts: Government social benefits to persons: Other",
    'B931RC1Q027SBEA': 'Personal current transfer receipts: Other current transfer receipts, from business (net)',
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
