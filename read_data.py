import pandas_datareader.data as web
import datetime
from constants import NIPA_VARS, FA_VARS

# set beginning and END_DATE dates for data
# format is year (1947), month (1), day (1)
START_DATE = datetime.datetime(1947, 1, 1)
END_DATE = datetime.date.today()


def read_nipa():
    '''
    Function to read NIPA data

    Args:
        None

    Returns:
        nipa_data (Pandas DataFrame): annual dataseries from the NIPA

    '''
    # pull NIPA data series of interest using pandas_datareader
    nipa_var_list = list(NIPA_VARS.keys())
    nipa_data = web.DataReader(nipa_var_list, "fred", START_DATE, END_DATE)
    nipa_mapper = {v: NIPA_VARS[v][1] for v in nipa_var_list}
    nipa_data.rename(columns=nipa_mapper, inplace=True)
    # resample data so annual
    nipa_data = nipa_data.resample('A').mean()

    return nipa_data


def read_fa():
    '''
    Function to read Federal Reserve Financial Accounts data

    Args:
        None

    Returns:
        fa_data (Pandas DataFrame): annual dataseries from the FA

    '''
    # pull Financial Accounts data series using pandas_datareader
    fa_var_list = list(FA_VARS.keys())
    fa_data = web.DataReader(fa_var_list, "fred", START_DATE, END_DATE)
    fa_mapper = {v: FA_VARS[v][1] for v in fa_var_list}
    fa_data.rename(columns=fa_mapper, inplace=True)
    # resample data so annual
    fa_data = fa_data.resample('A').mean()

    return fa_data


def compute_cap_factors():
    '''
    Function to create dataframe with capitalization factors for each
    source of income and each year

    Args:
        None

    Returns:
        cap_data (Pandas DataFrame): capitalization factors for each
            year and source of income

    '''
    nipa_data = read_nipa()
    fa_data = read_fa()
    cap_data = nipa_data.merge(fa_data, how='outer', on='DATE')
    cap_data['r_div'] = (cap_data['dividend_income'] /
                         cap_data['corp_equity'])
    cap_data['r_int'] = cap_data['interest_income'] / cap_data['debt']
    cap_data['r_rent'] = cap_data['rent'] / cap_data['total_nonfin_assets']

    return cap_data
